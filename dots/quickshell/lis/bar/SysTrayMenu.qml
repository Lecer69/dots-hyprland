import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray

PopupWindow {
    id: root

    property var trayItem: null

    anchor.item: null
    anchor.edges: Edges.Bottom | Edges.Left

    color: "transparent"
    visible: false

    property bool grabReady: false
    property real grabArmedAt: 0
    readonly property int grabSettleMs: 100

    HyprlandFocusGrab {
        id: focusGrab
        windows: [root]
        active: root.grabReady
        onCleared: {
            if (!root.grabReady) return
            var age = Date.now() - root.grabArmedAt
            if (age < root.grabSettleMs) {
                rearmTimer.restart()
            } else {
                root.close()
            }
        }
    }

    Timer {
        id: rearmTimer
        interval: root.grabSettleMs
        repeat: false
        onTriggered: {
            if (root.visible && root.activeOpener !== null) {
                root.grabReady = false
                root.grabArmedAt = Date.now()
                root.grabReady = true
            }
        }
    }

    Timer {
        id: grabTimer
        interval: 10
        repeat: false
        onTriggered: {
            if (root.activeOpener !== null) {
                root.grabArmedAt = Date.now()
                root.grabReady = true
            }
        }
    }

    implicitWidth: 280
    implicitHeight: menuCol.implicitHeight + 16

    property var openerStack: []
    property var activeOpener: null
    property string currentLabel: ""
    property bool   inSubmenu:    false

    Component {
        id: openerComponent
        QsMenuOpener { menu: null }
    }

    function openFor(item, anchorItem) {
        root.grabReady = false
        grabTimer.stop()
        rearmTimer.stop()
        _clearStack()

        root.trayItem    = item
        root.anchor.item = anchorItem

        var op = openerComponent.createObject(root)
        op.menu = item.menu

        root.openerStack  = [{ opener: op, label: "" }]
        root.activeOpener = op
        root.currentLabel = ""
        root.inSubmenu    = false

        root.visible = true
        grabTimer.restart()
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
        root.grabReady    = false
        root.visible      = false
        root.activeOpener = null
        grabTimer.stop()
        rearmTimer.stop()
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

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: "#f0121212"
        border.width: 1
        border.color: "#25ffffff"

        Column {
            id: menuCol
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 1
            topPadding: 1
            bottomPadding: 1

            Item {
                visible: root.inSubmenu
                width: parent.width
                height: 32

                Rectangle {
                    anchors.fill: parent
                    anchors.leftMargin: 2
                    anchors.rightMargin: 2
                    radius: 6
                    color: backMouse.containsMouse ? "#20ffffff" : "transparent"
                    Behavior on color { ColorAnimation { duration: 80 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "‹"
                            font.pixelSize: 13
                            color: "#88ffffff"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            text: root.currentLabel
                            font.pixelSize: 12
                            font.bold: true
                            color: "#ccffffff"
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
                width: parent.width - 12
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: "#20ffffff"
            }

            Item {
                visible: !root.inSubmenu && (root.trayItem?.title ?? "") !== ""
                width: parent.width
                height: 28

                Text {
                    id: headerText
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 10
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    text: root.trayItem?.title ?? ""
                    color: "#55ffffff"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                visible: !root.inSubmenu && (root.trayItem?.title ?? "") !== ""
                width: parent.width - 12
                anchors.horizontalCenter: parent.horizontalCenter
                height: 1
                color: "#20ffffff"
            }

            Repeater {
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
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        height: 1
                        color: "#20ffffff"
                    }

                    Rectangle {
                        visible: !modelData.isSeparator
                        anchors.fill: parent
                        anchors.leftMargin: 2
                        anchors.rightMargin: 2
                        radius: 6
                        color: itemMouse.containsMouse ? "#20ffffff" : "transparent"
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Item {
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: 14
                                Layout.preferredHeight: 14
                                opacity: (modelData.icon ?? "").length > 0 ? 1 : 0

                                Image {
                                    anchors.fill: parent
                                    source: modelData.icon ?? ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true; mipmap: true
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                text: modelData.text
                                font.pixelSize: 12
                                color: modelData.enabled ? '#e8ffffff' : "#40ffffff"
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: modelData.hasChildren
                                Layout.alignment: Qt.AlignVCenter
                                text: "›"
                                font.pixelSize: 13
                                color: "#55ffffff"
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
        }
    }
}
