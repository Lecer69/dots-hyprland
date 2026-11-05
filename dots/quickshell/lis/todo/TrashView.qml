pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// Deleted tasks, newest first: restore them or delete them for good
Item {
    id: root

    // Gets the keyboard once the last row is gone
    property Item fallback: null

    function leave(row: Item): void {
        if (row.activeFocus && !KeyNav.stepView(view, row.index, true) && !KeyNav.stepView(view, row.index, false))
            root.fallback?.forceActiveFocus();
    }

    function restore(row: Item): void {
        root.leave(row);
        TodoService.restoreTask(row.modelData.id);
    }

    function remove(row: Item): void {
        root.leave(row);
        TodoService.deleteForever(row.modelData.id);
    }

    ListView {
        id: view

        anchors.fill: parent
        clip: true
        spacing: 4
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel {
            values: TodoService.trash.slice().reverse()
            objectProp: "id"
        }

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            width: ListView.view.width
            height: Math.max(52, details.height + 16)
            radius: 8
            color: hover.hovered || row.activeFocus ? Theme.hover : "transparent"

            activeFocusOnTab: true
            Keys.onUpPressed: KeyNav.stepView(view, row.index, false)
            Keys.onDownPressed: KeyNav.stepView(view, row.index, true)
            Keys.onSpacePressed: root.restore(row)
            Keys.onReturnPressed: root.restore(row)
            Keys.onEnterPressed: root.restore(row)
            Keys.onDeletePressed: root.remove(row)

            HoverHandler {
                id: hover
            }

            Column {
                id: details

                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: trailing.x - x - 12
                spacing: 3

                Text {
                    width: parent.width
                    text: row.modelData.text
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    color: Theme.text
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width
                    text: {
                        const days = TodoService.trashDaysLeft(row.modelData);
                        const left = days + (days === 1 ? " day left" : " days left");
                        return row.modelData.listName ? row.modelData.listName + " · " + left : left;
                    }
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.textDim
                    font.pixelSize: 12
                }
            }

            Row {
                id: trailing

                anchors.right: parent.right
                anchors.rightMargin: 8
                height: parent.height
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Restore"
                    color: restoreArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#808080")
                    font.pixelSize: 12

                    MouseArea {
                        id: restoreArea

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.restore(row)
                    }
                }

                Item {
                    width: 26
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.pixelSize: 11
                        color: removeArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                    }

                    MouseArea {
                        id: removeArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.remove(row)
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: view.count === 0
        text: "Trash is empty"
        color: Theme.textDim
        font.pixelSize: 13
    }
}
