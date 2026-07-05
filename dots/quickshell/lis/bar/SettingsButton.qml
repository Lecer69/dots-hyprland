import QtQuick
import Quickshell

Item {
    id: root

    property var otherMenu: null
    property var screen: null
    readonly property var menu: settingsMenu

    width: 16
    height: 16
    smooth: true

    DropdownMenu {
        id: settingsMenu
        menuWidth: 160
        targetScreen: root.screen
        items: [
            QtObject {
                property string label: "Notification Center"
                property string icon: "../icons/notification.svg"
                property var action: () => {
                    return notificationCenterWindow.shown = true;
                }
            },
            QtObject {
                property string label: "Audio Settings"
                property string icon: "../icons/speaker-high.svg"
                property var action: () => Quickshell.execDetached(["pavucontrol-qt"])
            },
            QtObject {
                property string label: "Network"
                property string icon: "../icons/wifi.svg"
                property var action: () => Quickshell.execDetached(["kcmshell6", "kcm_networkmanagement"])
            },
            QtObject {
                property string label: "Task Manager"
                property string icon: "../icons/taskmanager.svg"
                property var action: () => Quickshell.execDetached(["gnome-system-monitor"])
            },
            QtObject {
                property string label: "Color Settings"
                property string icon: "../icons/color.svg"
                property var action: () => {
                    return gammaWindow.shown = true;
                }
            },
            QtObject {
                property string label: "Internet Usage"
                property string icon: "../icons/data.svg"
                property var action: () => {
                    return internetUsageWindow.shown = true;
                }
            },
            QtObject {
                property string label: "Wellbeing"
                property string icon: "../icons/wellbeing.svg"
                property var action: () => {
                    return wellbeingWindow.shown = true;
                }
            },
            QtObject {
                property string label: "Settings"
                property string icon: "../icons/settings.svg"
                property var action: () => {
                    return settingsWindow.shown = true;
                }
            }
        ]
    }

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "../icons/settings.svg"
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
            if (settingsMenu.isOpen) {
                settingsMenu.isOpen = false
            } else {
                if (root.otherMenu) root.otherMenu.isOpen = false
                settingsMenu.isOpen = true
            }
        }
    }
}