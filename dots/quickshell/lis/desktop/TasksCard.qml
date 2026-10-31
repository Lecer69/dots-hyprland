import QtQuick
import qs.todo
import qs.common

// To-do tasks; clicking one toggles it done
OverviewCard {
    id: root

    signal openRequested()

    title: "To-do"
    subtitle: {
        const total = TodoService.tasks.length;
        return total > 0 ? TodoService.tasks.filter(t => t.done).length + "/" + total : "";
    }
    action: "Open"
    onActionClicked: root.openRequested()

    Flickable {
        id: flick

        // Row highlights reach into the padding
        anchors.fill: parent
        anchors.leftMargin: -8
        anchors.rightMargin: -8
        contentWidth: width
        contentHeight: rows.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: rows

            width: flick.width
            spacing: 2

            Repeater {
                model: TodoService.sorted()

                delegate: Rectangle {
                    id: row

                    required property var modelData

                    width: rows.width
                    height: 34
                    radius: 8
                    color: rowArea.containsMouse ? Theme.hover : "transparent"

                    Rectangle {
                        id: check

                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        width: 16
                        height: 16
                        radius: width / 2
                        color: row.modelData.done ? Theme.text : "transparent"
                        border.color: row.modelData.done ? Theme.text : Theme.adapt("#4a4a4a")
                        border.width: 1.5
                    }

                    Text {
                        anchors.left: check.right
                        anchors.leftMargin: 10
                        anchors.right: important.left
                        anchors.rightMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.modelData.text
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        color: row.modelData.done ? Theme.textDim : Theme.text
                        font.pixelSize: 13
                        font.strikeout: row.modelData.done
                    }

                    Rectangle {
                        id: important

                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.modelData.important ? 8 : 0
                        height: 8
                        radius: 4
                        color: Theme.text
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: TodoService.toggleDone(row.modelData.id)
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: TodoService.tasks.length === 0
        text: "No tasks"
        color: Theme.textDim
        font.pixelSize: 13
    }
}
