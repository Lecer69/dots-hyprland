import QtQuick
import qs.common
import qs.todo

// A task to tick off; clicking or Space/Enter toggles it
Rectangle {
    id: root

    required property var task
    // Ticking it takes it off the sidebar, so the keyboard moves on first
    property bool leavesWhenDone: false
    // Gets the keyboard if no row is left
    property Item fallback: null

    readonly property string listRow: "sidebarTasks"

    function toggle(): void {
        if (root.leavesWhenDone && root.activeFocus && !KeyNav.step(root, true) && !KeyNav.step(root, false))
            root.fallback?.forceActiveFocus();
        TodoService.toggleDone(root.task.id);
    }

    height: Math.max(34, label.height + 16)
    radius: 8
    color: area.containsMouse || root.activeFocus ? Theme.hover : "transparent"

    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: root.toggle()
    Keys.onReturnPressed: root.toggle()
    Keys.onEnterPressed: root.toggle()

    Rectangle {
        id: check

        x: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: width / 2
        color: root.task.done ? Theme.text : "transparent"
        border.color: root.task.done ? Theme.text : Theme.adapt("#4a4a4a")
        border.width: 1.5
    }

    Text {
        id: label

        anchors.left: check.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.task.text
        textFormat: Text.PlainText
        wrapMode: Text.Wrap
        maximumLineCount: 2
        elide: Text.ElideRight
        color: root.task.done ? Theme.textDim : Theme.text
        font.pixelSize: 13
        font.strikeout: root.task.done
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggle()
    }
}
