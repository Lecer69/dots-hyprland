import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    Loader {
        id: cheatsheetLoader
        active: false

        sourceComponent: PanelWindow {
            id: cheatsheetRoot
            visible: cheatsheetLoader.active

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            function hide() {
                cheatsheetLoader.active = false
            }

            exclusiveZone: 0
            color: "transparent"
            WlrLayershell.namespace: "quickshell:cheatsheet"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Rectangle {
                id: cheatsheetBackground
                anchors.centerIn: parent
                radius: 14
                color: "#0f0f0f"
                clip: true
                border.width: 1
                border.color: "#2a2a2a"

                readonly property real headerHeight: 52
                readonly property real dividerHeight: 1
                readonly property real contentMargins: 28
                readonly property real maxWidth: Math.min(parent.width * 0.90, 1400)
                readonly property real maxHeight: Math.min(parent.height * 0.85, 580)
                readonly property real chromeWidth: contentMargins * 2
                readonly property real chromeHeight: headerHeight + dividerHeight + contentMargins * 2

                width: Math.min(maxWidth, chromeWidth + keybindsPage.implicitWidth)
                height: Math.min(maxHeight, chromeHeight + keybindsPage.implicitHeight)

                focus: cheatsheetRoot.visible
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        cheatsheetRoot.hide()
                        event.accepted = true
                    }
                }

                Rectangle {
                    id: header
                    width: parent.width
                    height: cheatsheetBackground.headerHeight
                    color: "transparent"

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 24
                        anchors.verticalCenter: parent.verticalCenter
                        text: "⌨ Keybinds"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        color: "#dddddd"
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 28
                        radius: 14
                        color: closeHover.containsMouse ? "#252525" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: 12
                            color: "#888888"
                        }

                        MouseArea {
                            id: closeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cheatsheetRoot.hide()
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.top: header.bottom
                    width: parent.width
                    height: cheatsheetBackground.dividerHeight
                    color: "#222222"
                }

                CheatsheetPanel {
                    id: keybindsPage
                    anchors.top: header.bottom
                    anchors.left: parent.left
                    anchors.margins: cheatsheetBackground.contentMargins
                    anchors.topMargin: cheatsheetBackground.contentMargins
                    columnHeight: cheatsheetBackground.maxHeight - cheatsheetBackground.chromeHeight
                }
            }
        }
    }

    IpcHandler {
        target: "cheatsheet"

        function toggle(): void {
            cheatsheetLoader.active = !cheatsheetLoader.active
        }

        function open(): void {
            cheatsheetLoader.active = true
        }

        function close(): void {
            cheatsheetLoader.active = false
        }
    }

    GlobalShortcut {
        name: "cheatsheet"
        description: "Toggles the cheatsheet window"
        onPressed: {
            cheatsheetLoader.active = !cheatsheetLoader.active
        }
    }
}