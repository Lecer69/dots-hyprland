pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// Tasks by list: the lists on the left, the open list's tasks on the right; drop a task on a list to move it
PanelFrame {
    id: root

    property bool shown: false
    // -1 for All tasks
    property real selectedList: -1
    property bool deleteArmed: false
    // Ids of the tasks with their description open
    property var expanded: []
    // While dragging over the lists: the one under it
    property var dropList: null
    // Shared with the title block so the lines below align
    readonly property int topRowHeight: 52

    readonly property var selected: TodoService.lists.find(l => l.id === root.selectedList) ?? null
    readonly property real viewList: root.selected ? root.selectedList : -1
    // Starred first
    readonly property var tasks: TodoService.listed(root.viewList)
    readonly property int doneCount: root.tasks.filter(t => t.done).length
    readonly property Item initialFocus: input

    title: "To-do"
    subtitle: {
        const total = TodoService.tasks.length;
        return total > 0 ? TodoService.tasks.filter(t => t.done).length + "/" + total : "";
    }

    onShownChanged: {
        if (!root.shown) {
            root.leave();
            root.deleteArmed = false;
        }
    }

    function toggleExpanded(id: real): void {
        root.expanded = root.expanded.includes(id) ? root.expanded.filter(e => e !== id) : root.expanded.concat([id]);
    }

    function listName(id: real): string {
        const list = TodoService.lists.find(l => l.id === id);
        return list ? (list.name.trim() || "Untitled list") : "";
    }

    // Drops the open list if left without a name or tasks
    function leave(): void {
        const list = root.selected;
        if (list && list.name.trim() === "" && !TodoService.tasks.some(t => t.list === list.id))
            TodoService.removeList(list.id);
    }

    function select(id: real): void {
        if (id === root.selectedList)
            return;

        root.leave();
        root.selectedList = id;
        root.deleteArmed = false;
        nameInput.text = root.selected?.name ?? "All tasks";
        flick.contentY = 0;
    }

    function newList(): void {
        const id = TodoService.addList("");
        if (id === -1)
            return;

        root.select(id);
        nameInput.forceActiveFocus();
    }

    function addTask(): void {
        if (!TodoService.addTask(input.text, root.viewList))
            return;

        input.text = "";
        // New tasks go last, so bring them into view
        Qt.callLater(() => {
            column.forceLayout();
            flick.contentY = Math.max(0, flick.contentHeight - flick.height);
        });
    }

    // The first click arms it, the second deletes the list and its tasks
    function deleteList(): void {
        if (!root.deleteArmed) {
            root.deleteArmed = true;
            disarm.restart();
            return;
        }
        TodoService.removeList(root.selectedList);
        root.select(-1);
    }

    // Null for none
    function listAt(p: point): var {
        const q = lists.mapFromItem(root, p.x, p.y);
        if (q.x < 0 || q.y < 0 || q.x > lists.width || q.y > lists.height)
            return null;

        const row = lists.itemAt(q.x + lists.contentX, q.y + lists.contentY);
        return row ? row.modelData.id : null;
    }

    // Moves among the starred tasks, or among the rest
    function dragStart(task: var, p: point): void {
        const shown = root.tasks;
        const starred = shown.filter(t => t.important).length;
        reorder.start(shown.map(t => t.id), task.id, column.mapFromItem(root, p.x, p.y).y,
            task.important ? 0 : starred, task.important ? starred - 1 : shown.length - 1);
    }

    // Over the lists, the task stays put in its own
    function dragMove(p: point): void {
        root.dropList = root.listAt(p);
        if (root.dropList === null)
            reorder.move(column.mapFromItem(root, p.x, p.y).y);
    }

    function dragEnd(): void {
        const id = reorder.key;
        const target = root.dropList;
        root.dropList = null;
        reorder.end();
        if (target !== null && target !== root.viewList)
            TodoService.setList(id, target);
    }

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.deleteArmed = false
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: root.newList()
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 24

        ColumnLayout {
            Layout.preferredWidth: 240
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.topRowHeight
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredHeight: 32
                    leftPadding: 12
                    verticalAlignment: Text.AlignVCenter
                    text: "Lists"
                    color: Theme.textDim
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                PanelButton {
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: 32
                    text: "New list"
                    onClicked: root.newList()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.adapt("#262626")
            }

            ListView {
                id: lists

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                model: ScriptModel {
                    values: [{ id: -1, name: "" }].concat(TodoService.lists)
                    objectProp: "id"
                }

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    required property int index
                    readonly property var tasks: TodoService.listed(row.modelData.id)
                    readonly property int done: row.tasks.filter(t => t.done).length
                    readonly property bool isSelected: row.modelData.id === root.viewList
                    readonly property bool isDropTarget: root.dropList === row.modelData.id && !row.isSelected

                    width: ListView.view.width
                    height: 58
                    radius: 8
                    color: row.isDropTarget ? Theme.adapt("#262626")
                        : row.isSelected ? (row.activeFocus ? Theme.adapt("#262626") : Theme.border)
                        : rowArea.containsMouse || row.activeFocus ? Theme.hover : "transparent"

                    activeFocusOnTab: true
                    Keys.onUpPressed: KeyNav.stepView(row.ListView.view, row.index, false)
                    Keys.onDownPressed: KeyNav.stepView(row.ListView.view, row.index, true)
                    Keys.onSpacePressed: root.select(row.modelData.id)
                    Keys.onReturnPressed: root.select(row.modelData.id)
                    Keys.onEnterPressed: root.select(row.modelData.id)

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 3

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.id === -1 ? "All tasks" : row.modelData.name.trim() || "Untitled list"
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: row.modelData.id === -1 || row.modelData.name.trim() ? Theme.text : Theme.adapt("#808080")
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            Text {
                                visible: row.tasks.length > 0
                                text: row.done + "/" + row.tasks.length
                                color: Theme.textDim
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.tasks.find(t => !t.done)?.text ?? (row.tasks.length > 0 ? "All done" : "No tasks")
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: Theme.textDim
                            font.pixelSize: 12
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(row.modelData.id)
                    }
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: root.topRowHeight + 25
            color: Theme.adapt("#262626")
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.topRowHeight
                spacing: 6

                TextInput {
                    id: nameInput

                    Layout.fillWidth: true
                    // All tasks can't be renamed
                    readOnly: root.selected === null
                    activeFocusOnPress: !readOnly
                    activeFocusOnTab: !readOnly
                    text: "All tasks"
                    color: Theme.adapt("#ffffff")
                    selectionColor: Theme.adapt("#333333")
                    selectedTextColor: Theme.adapt("#ffffff")
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    clip: true
                    selectByMouse: !readOnly
                    onTextEdited: {
                        if (root.selected)
                            TodoService.renameList(root.selectedList, text);
                    }

                    Keys.onTabPressed: input.forceActiveFocus()
                    Keys.onReturnPressed: input.forceActiveFocus()
                    Keys.onEnterPressed: input.forceActiveFocus()

                    Text {
                        visible: nameInput.text.length === 0
                        text: "List name"
                        color: Theme.adapt("#4a4a4a")
                        font: nameInput.font
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        Layout.fillWidth: true
                        text: root.tasks.length === 0 ? "No tasks" : root.doneCount + " of " + root.tasks.length + " done"
                        elide: Text.ElideRight
                        color: Theme.textDim
                        font.pixelSize: 12
                    }

                    Text {
                        id: clearLink

                        visible: root.doneCount > 0
                        text: "Clear completed"
                        color: clearArea.containsMouse || clearLink.activeFocus ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                        font.pixelSize: 12

                        activeFocusOnTab: true
                        Keys.onSpacePressed: TodoService.clearDone(root.viewList)
                        Keys.onReturnPressed: TodoService.clearDone(root.viewList)
                        Keys.onEnterPressed: TodoService.clearDone(root.viewList)

                        MouseArea {
                            id: clearArea

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: TodoService.clearDone(root.viewList)
                        }
                    }

                    Text {
                        visible: root.selected !== null
                        text: {
                            if (!root.deleteArmed)
                                return "Delete list";
                            const count = root.tasks.length;
                            return count === 0 ? "Click again to delete"
                                : "Click again to delete it and " + count + (count === 1 ? " task" : " tasks");
                        }
                        color: root.deleteArmed ? Theme.adapt("#e06c6c") : deleteArea.containsMouse || activeFocus ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                        font.pixelSize: 12

                        // Like the click, the first press only arms it
                        activeFocusOnTab: true
                        Keys.onSpacePressed: root.deleteList()
                        Keys.onReturnPressed: root.deleteList()
                        Keys.onEnterPressed: root.deleteList()

                        MouseArea {
                            id: deleteArea

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteList()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.adapt("#262626")
            }

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

                    Keys.onReturnPressed: root.addTask()
                    Keys.onEnterPressed: root.addTask()
                    Keys.onDownPressed: KeyNav.step(input, true, "tasks")

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        visible: input.text.length === 0
                        text: root.selected ? "Add a task to " + root.listName(root.selectedList) + "…" : "Add a task…"
                        elide: Text.ElideRight
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
                        onClicked: root.addTask()
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

                            // Keyed, so a task's row moves instead of being remade
                            model: ScriptModel {
                                values: reorder.arrange(root.tasks)
                                objectProp: "id"
                            }

                            delegate: Item {
                                id: wrap

                                required property var modelData

                                readonly property bool isDragged: reorder.key === wrap.modelData.id

                                width: column.width
                                height: item.height
                                z: wrap.isDragged ? 10 : 0

                                TodoItem {
                                    id: item

                                    width: parent.width
                                    // Follows the mouse while dragged
                                    y: wrap.isDragged ? reorder.top - wrap.y : 0
                                    task: wrap.modelData
                                    listName: root.viewList === -1 ? root.listName(wrap.modelData.list) : ""
                                    expanded: root.expanded.includes(wrap.modelData.id)
                                    dragged: wrap.isDragged
                                    dragSpace: root
                                    above: input
                                    view: flick

                                    onToggleExpanded: root.toggleExpanded(wrap.modelData.id)
                                    onDragStarted: p => root.dragStart(wrap.modelData, p)
                                    onDragMoved: p => root.dragMove(p)
                                    onDragEnded: root.dragEnd()
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.tasks.length === 0
                    text: root.selected ? "No tasks in this list" : "No tasks yet"
                    color: Theme.textDim
                    font.pixelSize: 13
                }
            }
        }
    }

    Reorder {
        id: reorder

        column: column
        repeater: repeater
        onDropped: ids => TodoService.applyOrder(ids)
    }
}
