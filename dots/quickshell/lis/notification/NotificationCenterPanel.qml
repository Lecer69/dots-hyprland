import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    readonly property Item initialFocus: historyList

    // The current row follows inserts; start from the newest
    function showNewest(): void {
        historyList.currentIndex = 0
        historyList.positionViewAtBeginning()
    }

    signal closeRequested()

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
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
        id: bodyLayout

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 12

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: historyList

                anchors.fill: parent
                spacing: 4
                clip: true
                model: NotificationHistory.model
                visible: count > 0
                // Up/Down are the list's own
                activeFocusOnTab: true

                delegate: NotificationCenterItem {
                    width: historyList.width
                    entry: model
                    onDismissed: NotificationHistory.removeAt(index)
                    // A row on its way out has index -1
                    Keys.onDeletePressed: if (index >= 0) NotificationHistory.removeAt(index)
                }
            }

            Text {
                anchors.centerIn: parent
                text: "No notifications"
                color: "#6b6b6b"
                font.pixelSize: 13
                visible: historyList.count === 0
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: clearLabel.implicitWidth + 24
            Layout.preferredHeight: 28
            radius: 6
            color: clearHover.pressed ? "#333333" : clearHover.containsMouse || activeFocus ? "#2a2a2a" : "#1f1f1f"
            visible: historyList.count > 0

            activeFocusOnTab: true
            Keys.onSpacePressed: NotificationHistory.clear()
            Keys.onReturnPressed: NotificationHistory.clear()
            Keys.onEnterPressed: NotificationHistory.clear()

            Text {
                id: clearLabel

                anchors.centerIn: parent
                text: "Clear all"
                color: "#e6e6e6"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            MouseArea {
                id: clearHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: NotificationHistory.clear()
            }
        }
    }
}
