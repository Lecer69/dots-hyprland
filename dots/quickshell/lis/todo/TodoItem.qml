import QtQuick
import qs.common

// A task: drag handle, check, wrapping text, its list's name, star and ✕
Rectangle {
    id: root

    required property var task
    // Empty for none
    property string listName: ""
    property bool dragged: false
    // The item drag positions are given in
    property Item dragSpace: null
    // Gets the keyboard on Up from the first task
    property Item above: null

    signal dragStarted(point p)
    signal dragMoved(point p)
    signal dragEnded()

    readonly property real band: 44

    height: Math.max(root.band, label.y * 2 + label.height)
    radius: 8
    color: root.dragged ? "#1f1f1f" : hover.hovered || root.activeFocus ? "#161616" : "transparent"

    readonly property string listRow: "tasks"
    activeFocusOnTab: true
    Keys.onUpPressed: {
        if (!KeyNav.step(root, false) && root.above)
            root.above.forceActiveFocus()
    }
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: TodoService.toggleDone(root.task.id)
    Keys.onDeletePressed: {
        const id = root.task.id
        // Focus moves on before the row goes
        if (!KeyNav.step(root, true) && !KeyNav.step(root, false) && root.above)
            root.above.forceActiveFocus()
        TodoService.removeTask(id)
    }

    FontMetrics {
        id: metrics

        font: label.font
    }

    HoverHandler {
        id: hover
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

                    Rectangle { width: 3; height: 3; radius: 1.5; color: "#444444" }
                    Rectangle { width: 3; height: 3; radius: 1.5; color: "#444444" }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.SizeVerCursor
            // The list scrolls otherwise, and the drag never ends
            preventStealing: true
            onPressed: mouse => root.dragStarted(mapToItem(root.dragSpace, mouse.x, mouse.y))
            onPositionChanged: mouse => root.dragMoved(mapToItem(root.dragSpace, mouse.x, mouse.y))
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
        color: root.task.done ? "#e6e6e6" : "transparent"
        border.color: root.task.done ? "#e6e6e6" : "#4a4a4a"
        border.width: 1.5

        MouseArea {
            anchors.fill: parent
            anchors.margins: -4
            cursorShape: Qt.PointingHandCursor
            onClicked: TodoService.toggleDone(root.task.id)
        }
    }

    Text {
        id: label

        x: 64
        y: Math.round((root.band - metrics.height) / 2)
        width: trailing.x - x - 10
        text: root.task.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        color: root.task.done ? "#6b6b6b" : "#e6e6e6"
        font.pixelSize: 13
        font.strikeout: root.task.done
    }

    Row {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: 8
        height: root.band

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 110)
            rightPadding: 6
            visible: root.listName !== ""
            text: root.listName
            elide: Text.ElideRight
            color: "#6b6b6b"
            font.pixelSize: 12
        }

        Item {
            width: 26
            height: parent.height

            Rectangle {
                anchors.centerIn: parent
                width: 10
                height: 10
                radius: width / 2
                color: root.task.important ? "#e6e6e6" : "transparent"
                border.color: root.task.important ? "#e6e6e6" : starArea.containsMouse ? "#999999" : "#4a4a4a"
                border.width: 1.5
            }

            MouseArea {
                id: starArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TodoService.toggleImportant(root.task.id)
            }
        }

        Item {
            width: 26
            height: parent.height

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: removeArea.containsMouse ? "#dddddd" : "#666666"
            }

            MouseArea {
                id: removeArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TodoService.removeTask(root.task.id)
            }
        }
    }
}
