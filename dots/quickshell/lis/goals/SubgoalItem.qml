import QtQuick
import qs.common

// A sub goal; emptying its title removes it
Rectangle {
    id: root

    required property real goalId
    required property var subgoal
    property bool dragged: false
    // The item drag positions are given in
    property Item dragSpace: null

    signal dragStarted(real y)
    signal dragMoved(real y)
    signal dragEnded()
    // Enter in the title
    signal accepted()

    readonly property real band: 30

    height: Math.max(root.band, editor.y * 2 + editor.height)
    radius: 6
    color: root.dragged || root.activeFocus ? "#1f1f1f" : "transparent"

    readonly property string listRow: "subgoals " + root.goalId
    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: GoalsService.toggleSubgoal(root.goalId, root.subgoal.id)
    Keys.onReturnPressed: editor.forceActiveFocus()
    Keys.onEnterPressed: editor.forceActiveFocus()
    Keys.onDeletePressed: {
        // Focus moves on before the row goes
        if (!KeyNav.step(root, true))
            KeyNav.step(root, false);
        GoalsService.removeSubgoal(root.goalId, root.subgoal.id);
    }

    FontMetrics {
        id: metrics

        font: editor.font
    }

    HoverHandler {
        id: hover
    }

    Item {
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

    Rectangle {
        x: 28
        y: (root.band - height) / 2
        width: 14
        height: 14
        radius: width / 2
        color: root.subgoal.done ? "#e6e6e6" : "transparent"
        border.color: root.subgoal.done ? "#e6e6e6" : "#4a4a4a"
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: GoalsService.toggleSubgoal(root.goalId, root.subgoal.id)
        }
    }

    TextEdit {
        id: editor

        x: 50
        y: Math.round((root.band - metrics.height) / 2)
        width: remove.x - x - 8
        textFormat: TextEdit.PlainText
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        font.pixelSize: 13
        font.strikeout: root.subgoal.done
        color: root.subgoal.done ? "#6b6b6b" : "#e6e6e6"
        selectionColor: "#333333"
        selectedTextColor: "#ffffff"

        // Not bound: a save while typing would move the cursor
        Component.onCompleted: text = root.subgoal.title
        onTextChanged: if (activeFocus) GoalsService.editSubgoal(root.goalId, root.subgoal.id, text)
        onActiveFocusChanged: {
            if (!activeFocus && text.trim() === "")
                GoalsService.removeSubgoal(root.goalId, root.subgoal.id);
        }

        Keys.onReturnPressed: root.accepted()
        Keys.onEnterPressed: root.accepted()
    }

    Item {
        id: remove

        anchors.right: parent.right
        width: 26
        height: root.band
        visible: hover.hovered

        Text {
            anchors.centerIn: parent
            text: "✕"
            font.pixelSize: 10
            color: removeArea.containsMouse ? "#dddddd" : "#666666"
        }

        MouseArea {
            id: removeArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: GoalsService.removeSubgoal(root.goalId, root.subgoal.id)
        }
    }
}
