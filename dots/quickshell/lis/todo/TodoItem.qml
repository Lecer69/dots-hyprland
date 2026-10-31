import QtQuick
import qs.common

// A task: drag handle, check, wrapping text, its list's name, star and ✕; clicking it opens its description
Rectangle {
    id: root

    required property var task
    // Empty for none
    property string listName: ""
    property bool expanded: false
    property bool dragged: false
    // The item drag positions are given in
    property Item dragSpace: null
    // Gets the keyboard on Up from the first task
    property Item above: null
    // Kept on the description's cursor while typing
    property Flickable view: null

    signal toggleExpanded()
    signal dragStarted(point p)
    signal dragMoved(point p)
    signal dragEnded()

    readonly property real band: 44
    readonly property real textBottom: description.visible ? description.y + description.height
        : preview.visible ? preview.y + preview.height : label.y + label.height

    // Opening moves the keyboard into the description, closing moves it back to the task
    function toggle(): void {
        if (root.expanded && description.activeFocus)
            root.forceActiveFocus()
        root.toggleExpanded()
        if (root.expanded) {
            description.forceActiveFocus()
            description.cursorPosition = description.length
            root.showCursor()
        }
    }

    function showCursor(): void {
        if (!root.view || !description.activeFocus)
            return

        const r = description.mapToItem(root.view.contentItem, description.cursorRectangle)
        const margin = 8
        if (r.y - margin < root.view.contentY)
            root.view.contentY = Math.max(0, r.y - margin)
        else if (r.y + r.height + margin > root.view.contentY + root.view.height)
            root.view.contentY = r.y + r.height + margin - root.view.height
    }

    height: Math.max(root.band, root.textBottom + label.y)
    radius: 8
    color: root.dragged || (root.activeFocus && root.expanded) ? Theme.border
        : root.expanded || hover.hovered || root.activeFocus ? Theme.hover : "transparent"

    readonly property string listRow: "tasks"
    activeFocusOnTab: true
    Keys.onUpPressed: {
        // From the description's first line
        if (description.activeFocus)
            root.forceActiveFocus()
        else if (!KeyNav.step(root, false) && root.above)
            root.above.forceActiveFocus()
    }
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: TodoService.toggleDone(root.task.id)
    Keys.onReturnPressed: root.toggle()
    Keys.onEnterPressed: root.toggle()
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

    MouseArea {
        width: parent.width
        // An open description takes its own clicks
        height: root.expanded ? description.y : parent.height
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
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
        color: root.task.done ? Theme.text : "transparent"
        border.color: root.task.done ? Theme.text : Theme.adapt("#4a4a4a")
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
        color: root.task.done ? Theme.textDim : Theme.text
        font.pixelSize: 13
        font.strikeout: root.task.done
    }

    Text {
        id: preview

        x: label.x
        y: label.y + label.height + 4
        width: label.width
        visible: !root.expanded && text !== ""
        text: (root.task.description ?? "").trim()
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: root.task.done ? Theme.textDim : Theme.adapt("#999999")
        font.pixelSize: 12
    }

    TextEdit {
        id: description

        x: label.x
        y: preview.y
        width: label.width
        visible: root.expanded
        activeFocusOnTab: true
        textFormat: TextEdit.PlainText
        wrapMode: TextEdit.Wrap
        selectByMouse: true
        color: Theme.adapt("#999999")
        selectionColor: Theme.adapt("#333333")
        selectedTextColor: Theme.adapt("#ffffff")
        font.pixelSize: 12

        // Not bound: a save while typing would move the cursor
        Component.onCompleted: text = root.task.description ?? ""
        onTextChanged: if (activeFocus) TodoService.setDescription(root.task.id, text)
        onCursorRectangleChanged: root.showCursor()

        // Tab would type a tab
        Keys.onTabPressed: nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason)
        Keys.onBacktabPressed: root.forceActiveFocus(Qt.BacktabFocusReason)

        Text {
            visible: description.text.length === 0
            text: "Add a description…"
            color: Theme.adapt("#4a4a4a")
            font: description.font
        }
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
            color: Theme.textDim
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
                color: root.task.important ? Theme.text : "transparent"
                border.color: root.task.important ? Theme.text : starArea.containsMouse ? Theme.adapt("#999999") : Theme.adapt("#4a4a4a")
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
                color: removeArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
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
