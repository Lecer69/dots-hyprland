import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
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
        id: bodyLayout

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 20
        anchors.topMargin: 16
        spacing: 12

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: historyList

                anchors.fill: parent
                spacing: 8
                clip: true
                model: NotificationHistory.model
                visible: count > 0

                delegate: NotificationCenterItem {
                    width: historyList.width
                    entry: model
                    onDismissed: NotificationHistory.removeAt(index)
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                color: "#666666"
                font.pixelSize: 13
                visible: historyList.count === 0
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 8
            color: clearHover.containsMouse ? "#252525" : "#1a1a1a"
            border.color: "#2a2a2a"
            border.width: 1
            visible: historyList.count > 0

            Text {
                anchors.centerIn: parent
                text: "Clear all"
                color: "#888888"
                font.pixelSize: 13
            }

            MouseArea {
                id: clearHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationHistory.clear()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }
    }
}
