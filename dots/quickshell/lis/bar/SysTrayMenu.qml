import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import qs.common

PanelWindow {
    id: root

    property var trayItem: null
    property bool isOpen: false
    property Item anchorItem: null

    // Stays mapped while the menu fades out
    visible: isOpen || menuFrame.opacity > 0.01
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keyboard.mode
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:traymenu"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    PanelKeyboard {
        id: keyboard
        open: root.isOpen
        initialFocus: menuFrame
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.close()
    }

    property var openerStack: []
    property var activeOpener: null
    property string currentLabel: ""
    property bool inSubmenu: false

    Component {
        id: openerComponent
        QsMenuOpener { menu: null }
    }

    function openFor(item, anchorItem): void {
        _clearStack()

        // No menu: don't open an empty frame
        if (!item || !item.menu || !root.screen) return

        root.trayItem = item
        root.anchorItem = anchorItem

        root.reposition()

        var op = openerComponent.createObject(root)
        op.menu = item.menu

        root.openerStack  = [{ opener: op, label: "" }]
        root.activeOpener = op
        root.currentLabel = ""
        root.inSubmenu    = false

        root.isOpen = true
    }

    // Next to the tray icon, never over the bar
    function reposition(): void {
        if (!anchorItem || !root.screen) return
        const pos = anchorItem.mapToGlobal(0, 0)
        const bx = pos.x - root.screen.x
        const by = pos.y - root.screen.y
        const bw = anchorItem.width
        const bh = anchorItem.height
        const sw = root.screen.width
        const sh = root.screen.height
        const fw = menuFrame.width
        const fh = menuFrame.height

        const cx = bx + bw / 2
        const cy = by + bh / 2
        const distLeft = bx
        const distTop = by
        const distRight = sw - (bx + bw)
        const distBottom = sh - (by + bh)

        let px, py
        if (distTop <= distLeft && distTop <= distRight && distTop <= distBottom) {
            py = by + bh + 6
            px = cx - fw / 2
        } else if (distBottom <= distLeft && distBottom <= distRight) {
            py = by - fh - 6
            px = cx - fw / 2
        } else if (distLeft <= distRight) {
            px = bx + bw + 6
            py = cy - fh / 2
        } else {
            px = bx - fw - 6
            py = cy - fh / 2
        }

        menuFrame.x = Math.max(8, Math.min(sw - fw - 8, px))
        menuFrame.y = Math.max(8, Math.min(sh - fh - 8, py))
    }

    function pushSubmenu(entry) {
        var op = openerComponent.createObject(root)
        op.menu = entry

        var newStack = root.openerStack.slice()
        newStack.push({ opener: op, label: entry.text })
        root.openerStack  = newStack
        root.activeOpener = op
        root.currentLabel = entry.text
        root.inSubmenu    = true
    }

    // Submenus rebuild the entries, so focus moves to the new first one
    function focusFirstEntry(): void {
        menuFrame.forceActiveFocus()
        Qt.callLater(() => KeyNav.step(menuFrame, true, true))
    }

    function popSubmenu() {
        if (root.openerStack.length <= 1) return

        var newStack = root.openerStack.slice()
        var popped   = newStack.pop()
        popped.opener.menu = null
        popped.opener.destroy()
        root.openerStack = newStack

        var top = newStack[newStack.length - 1]
        root.activeOpener = top.opener
        root.currentLabel = newStack.length > 1 ? top.label : ""
        root.inSubmenu    = newStack.length > 1
    }

    function close() {
        root.isOpen = false
        root.activeOpener = null
        _clearStack()
    }

    function _clearStack() {
        var stack = root.openerStack
        for (var i = 0; i < stack.length; i++) {
            stack[i].opener.menu = null
            stack[i].opener.destroy()
        }
        root.openerStack  = []
        root.currentLabel = ""
        root.inSubmenu    = false
    }

    // While open, the mask covers the screen so outside clicks close it; closed, it's click-through
    mask: Region {
        item: root.isOpen ? backdrop : null
    }

    MouseArea {
        id: backdrop
        anchors.fill: parent
        onClicked: root.close()
    }

    Rectangle {
        id: menuFrame

        width: 280
        height: menuCol.implicitHeight + 12
        radius: 10
        color: "#161616"
        border.width: 1
        border.color: "#242424"

        // Entries load async; keep it placed as it grows
        onHeightChanged: if (root.isOpen) root.reposition()

        // Down/Up go to the first/last entry; Left leaves a submenu
        Keys.onDownPressed: KeyNav.step(menuFrame, true, true)
        Keys.onUpPressed: KeyNav.step(menuFrame, false, true)
        Keys.onLeftPressed: {
            if (!root.inSubmenu)
                return
            root.popSubmenu()
            root.focusFirstEntry()
        }

        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1 : 0.98
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        MouseArea {
            anchors.fill: parent
            onClicked: mouse.accepted = true
        }

        Column {
            id: menuCol

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 6
            spacing: 2

            Item {
                visible: root.inSubmenu
                width: menuCol.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: backMouse.containsMouse ? "#262626" : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "‹"
                            font.pixelSize: 14
                            color: "#808080"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: root.currentLabel
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "#e6e6e6"
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.popSubmenu()
                    }
                }
            }

            Rectangle {
                visible: root.inSubmenu
                width: menuCol.width
                height: 1
                color: "#242424"
            }

            Item {
                visible: !root.inSubmenu && (root.trayItem?.title ?? "") !== ""
                width: menuCol.width
                height: 30

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    text: root.trayItem?.title ?? ""
                    color: "#6b6b6b"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: !root.inSubmenu && (root.trayItem?.title ?? "") !== ""
                width: menuCol.width
                height: 1
                color: "#242424"
            }

            Repeater {
                id: menuRepeater

                model: root.activeOpener ? root.activeOpener.children : null

                delegate: Item {
                    id: entry

                    required property QsMenuEntry modelData

                    function activate(): void {
                        if (entry.modelData.hasChildren) {
                            root.pushSubmenu(entry.modelData)
                            root.focusFirstEntry()
                        } else {
                            entry.modelData.triggered()
                            root.close()
                        }
                    }

                    width: menuCol.width
                    height: modelData.isSeparator ? 9 : 32

                    // Separators and disabled entries aren't stops
                    readonly property bool listRow: true
                    activeFocusOnTab: !modelData.isSeparator && modelData.enabled
                    Keys.onUpPressed: KeyNav.step(entry, false)
                    Keys.onDownPressed: KeyNav.step(entry, true)
                    Keys.onSpacePressed: entry.activate()
                    Keys.onReturnPressed: entry.activate()
                    Keys.onEnterPressed: entry.activate()
                    Keys.onRightPressed: if (entry.modelData.hasChildren) entry.activate()

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        height: 1
                        color: "#242424"
                    }

                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: 8
                        color: itemMouse.containsMouse || entry.activeFocus ? "#262626" : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Item {
                                visible: (modelData.icon ?? "").length > 0
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 16
                                Layout.preferredHeight: 16

                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon ?? ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    mipmap: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.text
                                font.pixelSize: 12
                                color: modelData.enabled ? "#e6e6e6" : "#4a4a4a"
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.hasChildren
                                Layout.alignment: Qt.AlignVCenter
                                text: "›"
                                font.pixelSize: 14
                                color: "#808080"
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !modelData.isSeparator && modelData.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.hasChildren) {
                                    root.pushSubmenu(modelData)
                                } else {
                                    modelData.triggered()
                                    root.close()
                                }
                            }
                        }
                    }
                }
            }

            // Until the entries arrive
            Item {
                visible: menuRepeater.count === 0
                width: menuCol.width
                height: 30

                Text {
                    anchors.centerIn: parent
                    text: "Loading…"
                    color: "#6b6b6b"
                    font.pixelSize: 12
                }
            }
        }
    }
}