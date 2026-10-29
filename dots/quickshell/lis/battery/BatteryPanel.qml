import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    readonly property real contentHeight: header.height + 8 + content.implicitHeight + 24

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    BatteryState {
        id: state
    }

    onVisibleChanged: {
        state.pollTimer.running = root.visible
        if (root.visible) state.refresh()
    }

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: state.available ? "Battery" : "Power"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
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
                onClicked: root.closeRequested()
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 16

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
                        color: "#6b6b6b"
                        font.pixelSize: 12
                    }
                    Text {
                        text: state.statusText
                        color: "#e6e6e6"
                        font.pixelSize: 13
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Health"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                    }
                    Text {
                        text: state.healthAvailable ? state.health + "% of design capacity" : "Unavailable"
                        color: "#e6e6e6"
                        font.pixelSize: 13
                    }
                }
            }
        }

        Text {
            text: "Power profile"
            color: "#6b6b6b"
            font.pixelSize: 12
            font.weight: Font.Medium
            Layout.topMargin: state.available ? 8 : 0
            Layout.bottomMargin: -8
        }

        PowerProfileOption {
            label: "Performance"
            description: "Maximum clocks, no throttling"
            visible: state.hasPerformance
            Layout.preferredHeight: visible ? 52 : 0
            selected: state.profile === "performance"
            onClicked: state.setProfile("performance")
        }

        PowerProfileOption {
            label: "Balanced"
            description: "Balanced clocks, balanced power usage"
            selected: state.profile === "balanced"
            onClicked: state.setProfile("balanced")
        }

        PowerProfileOption {
            label: "Power Saver"
            description: "Lower clocks, lower power usage"
            selected: state.profile === "power-saver"
            onClicked: state.setProfile("power-saver")
        }

        Text {
            visible: !state.profileAvailable
            text: "power-profiles-daemon not detected"
            color: "#6b6b6b"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
        }
    }
}