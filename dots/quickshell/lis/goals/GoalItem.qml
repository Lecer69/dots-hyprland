pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// A goal: drag handle, check, title, how many sub goals are done, and a bar
// for it. Clicking it opens it: the title can then be edited, and the sub
// goals are listed under it, with a field to add more.
Rectangle {
    id: root

    required property var goal
    property bool expanded: false
    property bool dragged: false
    // The item the drag positions are given in
    property Item dragSpace: null

    signal toggleExpanded()
    signal dragStarted(real y)
    signal dragMoved(real y)
    signal dragEnded()

    readonly property int total: root.goal.subgoals.length
    readonly property int doneSubgoals: root.goal.subgoals.filter(s => s.done).length
    // A goal is deleted on the second click
    property bool deleteArmed: false
    readonly property real band: 44
    // Left edge of the title, and of the sub goals' checks
    readonly property real textX: 64

    function addSubgoal(): void {
        if (GoalsService.addSubgoal(root.goal.id, addInput.text) !== -1)
            addInput.text = "";
    }

    height: header.height + (root.expanded ? subgoals.height : 0)
    radius: 8
    color: root.dragged ? "#1f1f1f" : (root.expanded || hover.hovered) ? "#161616" : "transparent"

    FontMetrics {
        id: metrics

        font: title.font
    }

    HoverHandler {
        id: hover
    }

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.deleteArmed = false
    }

    Item {
        id: header

        width: parent.width
        height: (bar.visible ? bar.y + bar.height : title.y + title.height) + title.y

        // Clicking the row opens and closes it
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleExpanded()
        }

        // Drag handle
        Item {
            x: 8
            width: 18
            height: root.band

            Column {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3

                    Row {
                        spacing: 3

                        Rectangle { width: 3; height: 3; radius: 1.5; color: "#444444" }
                        Rectangle { width: 3; height: 3; radius: 1.5; color: "#444444" }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor
                // The list scrolls otherwise
                preventStealing: true
                onPressed: mouse => root.dragStarted(mapToItem(root.dragSpace, mouse.x, mouse.y).y)
                onPositionChanged: mouse => root.dragMoved(mapToItem(root.dragSpace, mouse.x, mouse.y).y)
                onReleased: root.dragEnded()
                onCanceled: root.dragEnded()
            }
        }

        // Check
        Rectangle {
            x: 36
            y: (root.band - height) / 2
            width: 18
            height: 18
            radius: width / 2
            color: root.goal.done ? "#e6e6e6" : "transparent"
            border.color: root.goal.done ? "#e6e6e6" : "#4a4a4a"
            border.width: 1.5

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: GoalsService.toggle(root.goal.id)
            }
        }

        // Edited only while open, so a click on a closed goal opens it
        TextEdit {
            id: title

            x: root.textX
            y: Math.round((root.band - metrics.height) / 2)
            width: trailing.x - x - 10
            enabled: root.expanded
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            font.pixelSize: 13
            font.weight: Font.Medium
            font.strikeout: root.goal.done
            color: root.goal.done ? "#6b6b6b" : "#e6e6e6"
            selectionColor: "#333333"
            selectedTextColor: "#ffffff"

            // Not bound to the goal: a save while typing would move the cursor
            Component.onCompleted: text = root.goal.title
            onTextChanged: if (activeFocus) GoalsService.edit(root.goal.id, text)

            Keys.onReturnPressed: addInput.forceActiveFocus()
            Keys.onEnterPressed: addInput.forceActiveFocus()
            Keys.onTabPressed: addInput.forceActiveFocus()

            Text {
                visible: title.text.length === 0
                text: "Untitled goal"
                color: "#4a4a4a"
                font: title.font
            }
        }

        Row {
            id: trailing

            anchors.right: parent.right
            anchors.rightMargin: 8
            height: root.band

            Text {
                anchors.verticalCenter: parent.verticalCenter
                rightPadding: 4
                visible: root.deleteArmed || root.total > 0
                text: root.deleteArmed ? "Delete?" : root.doneSubgoals + "/" + root.total
                color: root.deleteArmed ? "#e06c6c" : "#6b6b6b"
                font.pixelSize: 12
            }

            // Open / close
            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    rotation: root.expanded ? 90 : 0
                    font.pixelSize: 16
                    color: chevronArea.containsMouse ? "#dddddd" : "#666666"

                    Behavior on rotation {
                        NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                    }
                }

                MouseArea {
                    id: chevronArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.toggleExpanded()
                }
            }

            // Delete
            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 11
                    color: root.deleteArmed ? "#e06c6c" : removeArea.containsMouse ? "#dddddd" : "#666666"
                }

                MouseArea {
                    id: removeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.deleteArmed) {
                            GoalsService.remove(root.goal.id);
                        } else {
                            root.deleteArmed = true;
                            disarm.restart();
                        }
                    }
                }
            }
        }

        // How many sub goals are done
        Rectangle {
            id: bar

            x: root.textX
            y: title.y + title.height + 8
            width: parent.width - x - 16
            height: 2
            radius: 1
            visible: root.total > 0
            color: "#2a2a2a"

            Rectangle {
                width: root.total > 0 ? parent.width * root.doneSubgoals / root.total : 0
                height: parent.height
                radius: parent.radius
                color: root.goal.done ? "#6b6b6b" : "#bbbbbb"

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    // The sub goals, once open
    Column {
        id: subgoals

        y: header.height
        x: 36
        width: parent.width - x - 8
        visible: root.expanded
        bottomPadding: 6

        Column {
            id: subColumn

            width: parent.width

            move: Transition {
                NumberAnimation { properties: "y"; duration: 150; easing.type: Easing.OutCubic }
            }

            Repeater {
                id: subRepeater

                // Keyed, so a sub goal keeps its row when the goal changes
                model: ScriptModel {
                    values: subReorder.arrange(root.goal.subgoals)
                    objectProp: "id"
                }

                delegate: Item {
                    id: subWrap

                    required property var modelData

                    readonly property bool isDragged: subReorder.key === subWrap.modelData.id

                    width: subColumn.width
                    height: sub.height
                    z: subWrap.isDragged ? 10 : 0

                    SubgoalItem {
                        id: sub

                        width: parent.width
                        y: subWrap.isDragged ? subReorder.top - subWrap.y : 0
                        goalId: root.goal.id
                        subgoal: subWrap.modelData
                        dragged: subWrap.isDragged
                        dragSpace: subColumn

                        onDragStarted: y => {
                            const ids = root.goal.subgoals.map(s => s.id);
                            subReorder.start(ids, subWrap.modelData.id, y, 0, ids.length - 1);
                        }
                        onDragMoved: y => subReorder.move(y)
                        onDragEnded: subReorder.end()
                        onAccepted: addInput.forceActiveFocus()
                    }
                }
            }
        }

        // Add a sub goal
        Item {
            width: parent.width
            height: 30

            Text {
                x: 28
                width: 14
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                text: "+"
                font.pixelSize: 14
                color: "#6b6b6b"
            }

            TextInput {
                id: addInput

                x: 50
                width: parent.width - x - 8
                anchors.verticalCenter: parent.verticalCenter
                color: "#e6e6e6"
                selectionColor: "#333333"
                selectedTextColor: "#ffffff"
                font.pixelSize: 13
                clip: true
                selectByMouse: true

                Keys.onReturnPressed: root.addSubgoal()
                Keys.onEnterPressed: root.addSubgoal()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: addInput.text.length === 0
                    text: "Add a sub goal…"
                    color: "#6b6b6b"
                    font.pixelSize: 13
                }
            }
        }
    }

    Reorder {
        id: subReorder

        column: subColumn
        repeater: subRepeater
        onDropped: ids => GoalsService.orderSubgoals(root.goal.id, ids)
    }
}
