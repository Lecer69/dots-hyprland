import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: root

    property var trayItem: null
    property bool isOpen: false
    property Item anchorItem: null

    // Stay visible while the menu animates out
    visible: isOpen || menuFrame.opacity > 0.01
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:traymenu"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
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

        // No menu at all: don't open an empty frame
        if (!item || !item.menu || !root.screen) return

        root.trayItem = item
        root.anchorItem = anchorItem

        // Open away from the bar edge, clamped on-screen
        root.reposition()

        var op = openerComponent.createObject(root)
        op.menu = item.menu

        root.openerStack  = [{ opener: op, label: "" }]
        root.activeOpener = op
        root.currentLabel = ""
        root.inSubmenu    = false

        root.isOpen = true
    }

    // Place the frame next to the tray icon, away from the bar edge — same
    // approach as DropdownMenu, so it never covers the bar itself.
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

    // Backdrop: click anywhere outside to close. While open the window's input
    // mask covers the screen so the click reaches this catcher; closed: the
    // window is fully click-through and never blocks the bar.
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
        radius: 14
        color: "#0f0f0f"
        border.width: 1
        border.color: "#2a2a2a"

        // Entries load async — keep the frame placed correctly as it grows
        onHeightChanged: if (root.isOpen) root.reposition()

        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1 : 0.98
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        // Click shield
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

            // Submenu back button
            Item {
                visible: root.inSubmenu
                width: menuCol.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: backMouse.containsMouse ? "#1c1c1c" : "transparent"
                    Behavior on color { ColorAnimation { duration: 100 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "‹"
                            font.pixelSize: 14
                            color: "#888888"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: root.currentLabel
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: "#dddddd"
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
                color: "#222222"
            }

            // App name header
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
                    color: "#777777"
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: !root.inSubmenu && (root.trayItem?.title ?? "") !== ""
                width: menuCol.width
                height: 1
                color: "#222222"
            }

            // Menu entries
            Repeater {
                id: menuRepeater

                model: root.activeOpener ? root.activeOpener.children : null

                delegate: Item {
                    required property QsMenuEntry modelData

                    width: menuCol.width
                    height: modelData.isSeparator ? 9 : 32

                    Rectangle {
                        visible: modelData.isSeparator
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        height: 1
                        color: "#222222"
                    }

                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        radius: 8
                        color: itemMouse.containsMouse ? "#1c1c1c" : "transparent"
                        Behavior on color { ColorAnimation { duration: 100 } }

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
                                color: modelData.enabled ? "#dddddd" : "#555555"
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.hasChildren
                                Layout.alignment: Qt.AlignVCenter
                                text: "›"
                                font.pixelSize: 14
                                color: "#888888"
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

            // Loading state: only while entries haven't arrived yet
            Item {
                visible: menuRepeater.count === 0
                width: menuCol.width
                height: 30

                Text {
                    anchors.centerIn: parent
                    text: "Loading…"
                    color: "#555555"
                    font.pixelSize: 12
                }
            }
        }
    }
}