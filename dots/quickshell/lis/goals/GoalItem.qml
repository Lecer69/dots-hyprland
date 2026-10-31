pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.common

// A goal; clicking it opens the title for editing and its sub goals
Rectangle {
    id: root

    required property var goal
    property bool expanded: false
    property bool dragged: false
    // The item drag positions are given in
    property Item dragSpace: null
    // Gets the keyboard on Up from the first goal
    property Item above: null

    signal toggleExpanded()
    signal dragStarted(real y)
    signal dragMoved(real y)
    signal dragEnded()

    readonly property int total: root.goal.subgoals.length
    readonly property int doneSubgoals: root.goal.subgoals.filter(s => s.done).length
    property bool deleteArmed: false
    readonly property real band: 44
    // Left edge of the title and of the sub goals' checks
    readonly property real textX: 64

    function addSubgoal(): void {
        if (GoalsService.addSubgoal(root.goal.id, addInput.text) !== -1)
            addInput.text = "";
    }

    // The first call arms it, the second deletes
    function remove(): void {
        if (!root.deleteArmed) {
            root.deleteArmed = true;
            disarm.restart();
            return;
        }
        if (root.activeFocus && !KeyNav.step(root, true) && !KeyNav.step(root, false) && root.above)
            root.above.forceActiveFocus();
        GoalsService.remove(root.goal.id);
    }

    height: header.height + (root.expanded ? subgoals.height : 0)
    radius: 8
    color: root.dragged || (root.activeFocus && root.expanded) ? Theme.border
        : (root.expanded || hover.hovered || root.activeFocus) ? Theme.hover : "transparent"

    readonly property string listRow: "goals"
    activeFocusOnTab: true
    Keys.onUpPressed: {
        if (!KeyNav.step(root, false) && root.above)
            root.above.forceActiveFocus();
    }
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: GoalsService.toggle(root.goal.id)
    Keys.onReturnPressed: root.toggleExpanded()
    Keys.onEnterPressed: root.toggleExpanded()
    Keys.onDeletePressed: root.remove()

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

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleExpanded()
        }

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

                        Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.adapt("#444444") }
                        Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.adapt("#444444") }
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

        Rectangle {
            x: 36
            y: (root.band - height) / 2
            width: 18
            height: 18
            radius: width / 2
            color: root.goal.done ? Theme.text : "transparent"
            border.color: root.goal.done ? Theme.text : Theme.adapt("#4a4a4a")
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
            color: root.goal.done ? Theme.textDim : Theme.text
            selectionColor: Theme.adapt("#333333")
            selectedTextColor: Theme.adapt("#ffffff")

            // Not bound: a save while typing would move the cursor
            Component.onCompleted: text = root.goal.title
            onTextChanged: if (activeFocus) GoalsService.edit(root.goal.id, text)

            Keys.onReturnPressed: addInput.forceActiveFocus()
            Keys.onEnterPressed: addInput.forceActiveFocus()
            Keys.onTabPressed: addInput.forceActiveFocus()

            Text {
                visible: title.text.length === 0
                text: "Untitled goal"
                color: Theme.adapt("#4a4a4a")
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
                color: root.deleteArmed ? Theme.adapt("#e06c6c") : Theme.textDim
                font.pixelSize: 12
            }

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    rotation: root.expanded ? 90 : 0
                    font.pixelSize: 16
                    color: chevronArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")

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

            Item {
                width: 26
                height: parent.height

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 11
                    color: root.deleteArmed ? Theme.adapt("#e06c6c") : removeArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                }

                MouseArea {
                    id: removeArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.remove()
                }
            }
        }

        Rectangle {
            id: bar

            x: root.textX
            y: title.y + title.height + 8
            width: parent.width - x - 16
            height: 2
            radius: 1
            visible: root.total > 0
            color: Theme.adapt("#2a2a2a")

            Rectangle {
                width: root.total > 0 ? parent.width * root.doneSubgoals / root.total : 0
                height: parent.height
                radius: parent.radius
                color: root.goal.done ? Theme.textDim : Theme.adapt("#bbbbbb")

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }
    }

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

                // Keyed, so a sub goal keeps its row
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
                color: Theme.textDim
            }

            TextInput {
                id: addInput

                x: 50
                width: parent.width - x - 8
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.text
                selectionColor: Theme.adapt("#333333")
                selectedTextColor: Theme.adapt("#ffffff")
                font.pixelSize: 13
                clip: true
                selectByMouse: true
                activeFocusOnTab: true

                Keys.onReturnPressed: root.addSubgoal()
                Keys.onEnterPressed: root.addSubgoal()

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: addInput.text.length === 0
                    text: "Add a sub goal…"
                    color: Theme.textDim
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
