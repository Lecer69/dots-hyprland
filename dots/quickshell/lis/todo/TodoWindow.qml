import qs.common

PanelHost {
    id: root

    name: "todo"
    description: "Toggles the to-do list panel"

    TodoPanel {
        anchors.centerIn: parent
        width: Math.min(980, parent.width - 160)
        height: Math.min(680, parent.height - 120)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
