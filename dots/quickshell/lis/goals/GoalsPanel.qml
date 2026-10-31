pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// Goals with sub goals; open ones first, done ones after
PanelFrame {
    id: root

    // Ids of the open goals
    property var expanded: []
    readonly property Item initialFocus: input

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
        // Once the row exists
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
            color: Theme.hover

            TextInput {
                id: input

                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 36
                verticalAlignment: TextInput.AlignVCenter
                color: Theme.text
                selectionColor: Theme.adapt("#333333")
                selectedTextColor: Theme.adapt("#ffffff")
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                activeFocusOnTab: true

                Keys.onReturnPressed: root.addGoal()
                Keys.onEnterPressed: root.addGoal()
                Keys.onDownPressed: KeyNav.step(input, true, "goals")

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: input.text.length === 0
                    text: "Add a goal…"
                    color: Theme.textDim
                    font.pixelSize: 13
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "+"
                font.pixelSize: 16
                color: addArea.containsMouse ? Theme.adapt("#ffffff") : Theme.adapt("#808080")

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

                    move: Transition {
                        NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
                    }

                    Repeater {
                        id: repeater

                        // Keyed, so a goal's row moves instead of being remade
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
                                // Follows the mouse while dragged
                                y: wrap.isDragged ? reorder.top - wrap.y : 0
                                goal: wrap.modelData
                                expanded: root.expanded.includes(wrap.modelData.id)
                                dragged: wrap.isDragged
                                dragSpace: column
                                above: input

                                onToggleExpanded: root.toggleExpanded(wrap.modelData.id)
                                // Moves among the open goals, or among the done ones
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
                color: Theme.textDim
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
