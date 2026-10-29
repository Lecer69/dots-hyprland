pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// Goals with sub goals, kept by GoalsService in ~/.config/lis/goals.json.
// Open goals come first and done ones after; each part keeps the order the
// goals are dragged into.
PanelFrame {
    id: root

    // The goals that are open, by id
    property var expanded: []

    title: "Goals"
    subtitle: GoalsService.goals.length > 0 ? GoalsService.doneCount + "/" + GoalsService.goals.length : ""

    function toggleExpanded(id: real): void {
        root.expanded = root.expanded.includes(id) ? root.expanded.filter(e => e !== id) : root.expanded.concat([id]);
    }

    function addGoal(): void {
        const id = GoalsService.add(input.text);
        if (id === -1)
            return;

        input.text = "";
        // Once the row is there, scroll it into view
        Qt.callLater(() => {
            const item = repeater.itemAt(GoalsService.sorted.findIndex(g => g.id === id));
            if (!item)
                return;
            if (item.y < flick.contentY)
                flick.contentY = item.y;
            else if (item.y + item.height > flick.contentY + flick.height)
                flick.contentY = item.y + item.height - flick.height;
        });
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 36
            radius: 8
            color: "#161616"

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 36
                verticalAlignment: TextInput.AlignVCenter
                color: "#e6e6e6"
                selectionColor: "#333333"
                selectedTextColor: "#ffffff"
                font.pixelSize: 13
                clip: true
                selectByMouse: true

                Keys.onReturnPressed: root.addGoal()
                Keys.onEnterPressed: root.addGoal()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: "Add a goal…"
                    color: "#6b6b6b"
                    font.pixelSize: 13
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                font.pixelSize: 16
                color: addArea.containsMouse ? "#ffffff" : "#808080"

                MouseArea {
                    id: addArea

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.addGoal()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick

                anchors.fill: parent
                contentWidth: width
                contentHeight: column.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: column

                    width: flick.width
                    spacing: 4

                    // Rows sliding out of the way: of a dragged row, and of
                    // goals opening, closing, being added or deleted
                    move: Transition {
                        NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        id: repeater

                        // Keyed, so a goal keeps its row, and its row moves
                        // instead of being made again
                        model: ScriptModel {
                            values: reorder.arrange(GoalsService.sorted)
                            objectProp: "id"
                        }

                        delegate: Item {
                            id: wrap

                            required property var modelData

                            readonly property bool isDragged: reorder.key === wrap.modelData.id

                            width: column.width
                            height: goalItem.height
                            z: wrap.isDragged ? 10 : 0

                            GoalItem {
                                id: goalItem

                                width: parent.width
                                // Follows the mouse while dragged, wherever
                                // the Column has put the row
                                y: wrap.isDragged ? reorder.top - wrap.y : 0
                                goal: wrap.modelData
                                expanded: root.expanded.includes(wrap.modelData.id)
                                dragged: wrap.isDragged
                                dragSpace: column

                                onToggleExpanded: root.toggleExpanded(wrap.modelData.id)
                                // A goal moves among the open goals, or among
                                // the done ones
                                onDragStarted: y => {
                                    const sorted = GoalsService.sorted;
                                    const open = sorted.filter(g => !g.done).length;
                                    const done = wrap.modelData.done;
                                    reorder.start(sorted.map(g => g.id), wrap.modelData.id, y,
                                        done ? open : 0, done ? sorted.length - 1 : open - 1);
                                }
                                onDragMoved: y => reorder.move(y)
                                onDragEnded: reorder.end()
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: GoalsService.goals.length === 0
                text: "No goals yet"
                color: "#6b6b6b"
                font.pixelSize: 13
            }
        }
    }

    Reorder {
        id: reorder

        column: column
        repeater: repeater
        onDropped: ids => GoalsService.order(ids)
    }
}
