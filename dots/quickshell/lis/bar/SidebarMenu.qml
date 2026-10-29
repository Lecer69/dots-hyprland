import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// Right-edge sidebar, opened by clicking the volume hover bar. Items are
// grouped under their `section`; items without one are pinned to the bottom.
Scope {
    id: root

    property list<QtObject> items: [
        QtObject {
            property string section: "Panels"
            property string label: "Notification Center"
            property string icon: "../icons/notification.svg"
            property var action: () => {
                return notificationCenterWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Calendar"
            property string icon: "../icons/calendar.svg"
            property var action: () => {
                return calendarWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "To-Do"
            property string icon: "../icons/todo.svg"
            property var action: () => {
                return todoWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Goals"
            property string icon: "../icons/goals.svg"
            property var action: () => {
                return goalsWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Notes"
            property string icon: "../icons/notes.svg"
            property var action: () => {
                return notesWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Color Settings"
            property string icon: "../icons/color.svg"
            property var action: () => {
                return gammaWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Internet Usage"
            property string icon: "../icons/data.svg"
            property var action: () => {
                return internetUsageWindow.shown = true;
            }
        },
        QtObject {
            property string section: "Panels"
            property string label: "Wellbeing"
            property string icon: "../icons/wellbeing.svg"
            property var action: () => {
                return wellbeingWindow.shown = true;
            }
        },
        QtObject {
            property string section: "System"
            property string label: "Audio"
            property string icon: "../icons/speaker-high.svg"
            property var action: () => {
                return audioWindow.shown = true;
            }
        },
        QtObject {
            property string section: "System"
            property string label: "Bluetooth"
            property string icon: "../icons/bluetooth.svg"
            property var action: () => {
                return bluetoothWindow.shown = true;
            }
        },
        QtObject {
            property string section: "System"
            property string label: "Network"
            property string icon: "../icons/wifi.svg"
            property var action: () => {
                return networkWindow.shown = true;
            }
        },
        QtObject {
            property string section: "System"
            property string label: "Displays"
            property string icon: "../icons/monitor.svg"
            property var action: () => {
                return displaysWindow.shown = true;
            }
        },
        QtObject {
            property string section: "System"
            property string label: "Task Manager"
            property string icon: "../icons/taskmanager.svg"
            property var action: () => {
                return taskManagerWindow.shown = true;
            }
        },
        QtObject {
            property string label: "Settings"
            property string icon: "../icons/settings.svg"
            property var action: () => {
                return settingsWindow.shown = true;
            }
        },
        QtObject {
            property string label: "Power"
            property string icon: "../icons/power.svg"
            property var action: () => {
                powerDialog.targetScreen = root.screen;
                powerDialog.isOpen = true;
            }
        }
    ]
    property var targetScreen: null
    property bool isOpen: false
    readonly property var screen: root.targetScreen ?? Quickshell.screens[0]

    readonly property var sections: {
        const seen = []
        for (let i = 0; i < root.items.length; i++) {
            const section = root.items[i].section ?? ""
            if (section !== "" && !seen.includes(section)) seen.push(section)
        }
        return seen
    }

    function itemsIn(section): var {
        const out = []
        for (let i = 0; i < root.items.length; i++) {
            if ((root.items[i].section ?? "") === section) out.push(root.items[i])
        }
        return out
    }

    // Opens on the given screen, or closes when it's already open there
    function toggle(screen): void {
        if (root.isOpen && root.screen === screen) {
            root.isOpen = false
            return
        }
        root.targetScreen = screen
        root.isOpen = true
    }

    IpcHandler {
        target: "sidebar"

        function toggle(): void {
            root.toggle(Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null)
        }

        function close(): void {
            root.isOpen = false
        }
    }

    // Click anywhere outside the sidebar closes it. On the top layer, so the
    // sidebar (overlay) is always above it.
    PanelWindow {
        screen: root.screen
        visible: root.isOpen
        color: "transparent"
        // Keeps clear of the bar's reserved space
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:sidebarbackdrop"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Hyprland slides it in and out, like it animates the other panels (the
    // quickshell:sidebar layer rule in hyprland/rules.lua). A slide in QML
    // runs at 60 fps on NVIDIA, where Qt steps animations every 16 ms.
    PanelWindow {
        screen: root.screen
        visible: root.isOpen
        color: "transparent"
        implicitWidth: 280
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        WlrLayershell.namespace: "quickshell:sidebar"

        anchors {
            top: true
            bottom: true
            right: true
        }

        margins {
            top: 8
            bottom: 8
            right: 8
        }

        Shortcut {
            sequences: ["Escape"]
            onActivated: root.isOpen = false
        }

        Rectangle {
            anchors.fill: parent
            radius: 12
            color: "#0f0f0f"
            border.color: "#1f1f1f"
            border.width: 1

            Item {
                id: header

                width: parent.width
                height: 56

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Menu"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                }

                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: "✕"
                    font.pixelSize: 12
                    color: closeHover.containsMouse ? "#dddddd" : "#666666"

                    MouseArea {
                        id: closeHover

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.isOpen = false
                    }
                }
            }

            ColumnLayout {
                anchors {
                    top: header.bottom
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
                    margins: 12
                    topMargin: 0
                }
                spacing: 2

                Repeater {
                    model: root.sections

                    ColumnLayout {
                        id: group

                        required property string modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.topMargin: index > 0 ? 16 : 0
                        spacing: 2

                        Text {
                            Layout.leftMargin: 10
                            Layout.bottomMargin: 6
                            text: group.modelData
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: "#6b6b6b"
                        }

                        Repeater {
                            model: root.itemsIn(group.modelData)

                            SidebarItem {}
                        }
                    }
                }

                Item {
                    Layout.fillHeight: true
                }

                Repeater {
                    model: root.itemsIn("")

                    SidebarItem {}
                }
            }
        }
    }

    component SidebarItem: Rectangle {
        id: entry

        required property var modelData

        Layout.fillWidth: true
        implicitHeight: 36
        radius: 8
        color: area.pressed ? "#1f1f1f" : area.containsMouse ? "#161616" : "transparent"

        RowLayout {
            anchors {
                fill: parent
                leftMargin: 10
                rightMargin: 10
            }
            spacing: 12

            Image {
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                source: entry.modelData.icon
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                smooth: true
                opacity: area.containsMouse ? 1 : 0.6
            }

            Text {
                Layout.fillWidth: true
                text: entry.modelData.label
                font.pixelSize: 13
                color: area.containsMouse ? "#ffffff" : "#e6e6e6"
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: area

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                root.isOpen = false
                entry.modelData.action()
            }
        }
    }
}
