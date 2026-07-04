import QtQuick
import Quickshell

Item {
    id: root

    property var otherMenu: null
    property var screen: null
    readonly property var menu: powerMenu

    width: 16
    height: 16
    smooth: true

    DropdownMenu {
        id: powerMenu
        menuWidth: 120
        targetScreen: root.screen
        items: [
            QtObject {
                property string label: "Shutdown"
                property string icon: "../icons/power.svg"
                property var action: () => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "shutdown"])
            },
            QtObject {
                property string label: "Reboot"
                property string icon: "../icons/restart.svg"
                property var action: () => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "reboot"])
            },
            QtObject {
                property string label: "Suspend"
                property string icon: "../icons/exit.svg"
                property var action: () => Quickshell.execDetached(["systemctl", "suspend"])
            }
        ]
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "../icons/power.svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        opacity: menuBtn.containsMouse ? 0.7 : 1.0
    }

    MouseArea {
        id: menuBtn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (powerMenu.isOpen) {
                powerMenu.isOpen = false
            } else {
                if (root.otherMenu) root.otherMenu.isOpen = false
                powerMenu.isOpen = true
            }
        }
    }
}