import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

PanelHost {
    id: root

    name: "cheatsheet"
    description: "Toggles the cheatsheet window"
    namespace: "quickshell:cheatsheet"

    Rectangle {
        id: cheatsheetBackground
        anchors.centerIn: parent
        radius: 12
        color: Theme.panel
        clip: true
        border.width: 1
        border.color: Theme.border

        readonly property real headerHeight: 56
        readonly property real headerGap: 8
        readonly property real contentMargins: 24
        readonly property real maxWidth: Math.min(parent.width * 0.90, 1400)
        readonly property real maxHeight: Math.min(parent.height * 0.85, 580)
        readonly property real chromeWidth: contentMargins * 2
        readonly property real chromeHeight: headerHeight + headerGap + contentMargins

        width: Math.min(maxWidth, chromeWidth + keybindsPage.implicitWidth)
        height: Math.min(maxHeight, chromeHeight + keybindsPage.implicitHeight)

        Item {
            id: header
            width: parent.width
            height: cheatsheetBackground.headerHeight

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: "Keybinds"
                font.pixelSize: 15
                font.weight: Font.DemiBold
                color: Theme.adapt("#ffffff")
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                font.pixelSize: 12
                color: closeHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.close()
                }
            }
        }

        CheatsheetPanel {
            id: keybindsPage
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.margins: cheatsheetBackground.contentMargins
            anchors.topMargin: cheatsheetBackground.headerGap
            columnHeight: cheatsheetBackground.maxHeight - cheatsheetBackground.chromeHeight
        }
    }
}
