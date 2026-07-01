import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.components
import qs.settings.data
import qs.settings.pages

Rectangle {
    id: root
    signal closeRequested

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Item {
            Layout.preferredWidth: 200
            Layout.fillHeight: true

            Rectangle {
                anchors.fill: parent
                color: "#141414"
                topLeftRadius: 14
                bottomLeftRadius: 14
                topRightRadius: 0
                bottomRightRadius: 0
            }

            ColumnLayout {
                anchors { fill: parent; margins: 12 }
                spacing: 2

                Item { Layout.preferredHeight: 8 }
                Text {
                    text: "Settings"
                    font { pixelSize: 18; weight: Font.Bold }
                    color: "#ffffff"
                    Layout.leftMargin: 8
                }
                Item { Layout.preferredHeight: 12 }

                NavItem {
                    Layout.fillWidth: true
                    label: "General"
                    icon: "../../icons/settings.svg"
                    active: pager.currentIndex === 0
                    onClicked: pager.currentIndex = 0
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "Bar"
                    icon: "../../icons/bar.svg"
                    active: pager.currentIndex === 1
                    onClicked: pager.currentIndex = 1
                }
                NavItem {
                    Layout.fillWidth: true
                    label: "osu!"
                    icon: "../../icons/osu.svg"
                    active: pager.currentIndex === 2
                    onClicked: pager.currentIndex = 2
                }

                Item { Layout.fillHeight: true }
            }
        }

        // Divider
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            color: "#222222"
        }

        // Page area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 24
                Layout.rightMargin: 16

                Text {
                    text: ["General","Bar","osu!"][pager.currentIndex]
                    font { pixelSize: 15; weight: Font.DemiBold }
                    color: "#dddddd"
                }
                Item { Layout.fillWidth: true }

                Rectangle {
                    width: 28; height: 28
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
                        onClicked: root.closeRequested()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: "#222222"
            }

            StackLayout {
                id: pager
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: 0

                GeneralPage {}
                BarPage {}
                OsuPage {}
            }
        }
    }
}
