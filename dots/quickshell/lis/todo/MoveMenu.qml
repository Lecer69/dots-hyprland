pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// A task's right-click menu of lists to move it to; covers the panel so a click outside closes it
Item {
    id: root

    // Null while closed
    property var task: null
    property Item opener: null
    // -1 until the pointer or the keyboard picks a row
    property int current: -1
    property Item _back: null

    readonly property var choices: [{ id: -1, name: "" }].concat(TodoService.lists)
    readonly property int rowHeight: 32
    readonly property int maxRows: 8

    signal moved(Item opener, real id, real list)

    visible: root.task !== null

    // At p, kept inside; from the keyboard it starts on the task's list
    function open(opener: Item, task: var, p: point, keyboard: bool): void {
        root._back = root.Window.activeFocusItem;
        root.opener = opener;
        root.task = task;
        root.current = keyboard ? root.choices.findIndex(l => l.id === task.list) : -1;
        box.x = Math.max(0, Math.min(p.x, root.width - box.width));
        box.y = p.y + box.height <= root.height ? p.y : Math.max(0, p.y - box.height);
        flick.contentY = 0;
        root.showCurrent();
        box.forceActiveFocus();
    }

    function close(restore: bool): void {
        if (root.task === null)
            return;

        root.task = null;
        if (restore && root._back)
            root._back.forceActiveFocus();
    }

    function choose(index: int): void {
        const task = root.task;
        const list = root.choices[index]?.id;
        root.close(true);
        if (task && list !== undefined && list !== task.list)
            root.moved(root.opener, task.id, list);
    }

    function step(forward: bool): void {
        if (root.choices.length === 0)
            return;

        root.current = forward ? Math.min(root.choices.length - 1, root.current + 1) : Math.max(0, root.current - 1);
        root.showCurrent();
    }

    function showCurrent(): void {
        if (root.current < 0)
            return;

        const y = root.current * root.rowHeight;
        if (y < flick.contentY)
            flick.contentY = y;
        else if (y + root.rowHeight > flick.contentY + flick.height)
            flick.contentY = y + root.rowHeight - flick.height;
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        onPressed: root.close(true)
        onWheel: root.close(true)
    }

    Rectangle {
        id: box

        width: 200
        height: header.height + Math.min(root.choices.length, root.maxRows) * root.rowHeight + 8
        radius: 8
        color: Theme.panel
        border.color: Theme.adapt("#262626")
        border.width: 1

        // Escape would close the whole panel
        Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
        Keys.onEscapePressed: root.close(true)
        Keys.onUpPressed: root.step(false)
        Keys.onDownPressed: root.step(true)
        Keys.onTabPressed: root.step(true)
        Keys.onBacktabPressed: root.step(false)
        Keys.onReturnPressed: root.choose(root.current)
        Keys.onEnterPressed: root.choose(root.current)
        Keys.onSpacePressed: root.choose(root.current)
        onActiveFocusChanged: if (!activeFocus) root.close(false)

        // Clicks between the rows stay in the menu
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onWheel: {}
        }

        Text {
            id: header

            x: 12
            width: parent.width - 24
            height: 32
            verticalAlignment: Text.AlignVCenter
            text: "Move to"
            elide: Text.ElideRight
            color: Theme.textDim
            font.pixelSize: 12
        }

        Flickable {
            id: flick

            x: 4
            y: header.height
            width: parent.width - 8
            height: parent.height - y - 4
            contentHeight: rows.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            Column {
                id: rows

                width: flick.width

                Repeater {
                    model: root.choices

                    delegate: Rectangle {
                        id: choice

                        required property var modelData
                        required property int index
                        readonly property bool isTaskList: root.task !== null && choice.modelData.id === root.task.list

                        width: rows.width
                        height: root.rowHeight
                        radius: 6
                        color: root.current === choice.index ? Theme.hover : "transparent"

                        Text {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 36
                            text: choice.modelData.id === -1 ? "No list" : choice.modelData.name.trim() || "Untitled list"
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            color: choice.isTaskList ? Theme.textDim : Theme.text
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: choice.isTaskList
                            text: "✓"
                            color: Theme.textDim
                            font.pixelSize: 12
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = choice.index
                            onClicked: root.choose(choice.index)
                        }
                    }
                }
            }
        }
    }
}
