import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    readonly property real contentHeight: header.height + 1 + 24 + content.implicitHeight + 28

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    BatteryState {
        id: state
    }

    onVisibleChanged: {
        state.pollTimer.running = root.visible
        if (root.visible) state.refresh()
    }

    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: state.available ? "Battery" : "Power"
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
                onClicked: root.closeRequested()
            }
        }
    }

    Rectangle {
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: "#222222"
    }

    ColumnLayout {
        id: content
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 28
        anchors.topMargin: 24
        spacing: 18

        // Ring
        RowLayout {
            visible: state.available
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? implicitHeight : 0
            spacing: 24

            BatteryRing {
                percent: state.percent
                charging: state.charging
                available: state.available
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Status"
                        color: "#777777"
                        font.pixelSize: 11
                    }
                    Text {
                        text: state.statusText
                        color: "#dddddd"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Health"
                        color: "#777777"
                        font.pixelSize: 11
                    }
                    Text {
                        text: state.healthAvailable ? state.health + "% of design capacity" : "Unavailable"
                        color: "#dddddd"
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                }
            }
        }

        Rectangle {
            visible: state.available
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 1 : 0
            color: "#1c1c1c"
        }

        Text {
            text: "Power profile"
            color: "#aaaaaa"
            font.pixelSize: 13
            Layout.bottomMargin: -4
        }

        PowerProfileOption {
            label: "Performance"
            description: "Maximum clocks, no throttling"
            accent: "#f38ba8"
            visible: state.hasPerformance
            Layout.preferredHeight: visible ? 52 : 0
            selected: state.profile === "performance"
            onClicked: state.setProfile("performance")
        }

        PowerProfileOption {
            label: "Balanced"
            description: "Balanced clocks, balanced power usage"
            accent: "#89b4fa"
            selected: state.profile === "balanced"
            onClicked: state.setProfile("balanced")
        }

        PowerProfileOption {
            label: "Power Saver"
            description: "Lower clocks, lower power usage"
            accent: "#a6e3a1"
            selected: state.profile === "power-saver"
            onClicked: state.setProfile("power-saver")
        }

        Text {
            visible: !state.profileAvailable
            text: "power-profiles-daemon not detected"
            color: "#555555"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
        }
    }
}