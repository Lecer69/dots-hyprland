import QtQuick
import QtQuick.Layouts
import qs.common

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
    color: Theme.panel
    clip: true
    border.color: Theme.border
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
                color: Theme.textDim
                font.pixelSize: 13
                visible: historyList.count === 0
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignRight
            Layout.preferredWidth: clearLabel.implicitWidth + 24
            Layout.preferredHeight: 28
            radius: 6
            color: clearHover.pressed ? Theme.adapt("#333333") : clearHover.containsMouse || activeFocus ? Theme.adapt("#2a2a2a") : Theme.border
            visible: historyList.count > 0

            activeFocusOnTab: true
            Keys.onSpacePressed: NotificationHistory.clear()
            Keys.onReturnPressed: NotificationHistory.clear()
            Keys.onEnterPressed: NotificationHistory.clear()

            Text {
                id: clearLabel

                anchors.centerIn: parent
                text: "Clear all"
                color: Theme.text
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
