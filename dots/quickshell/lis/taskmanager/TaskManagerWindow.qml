import qs.common

PanelHost {
    id: root

    name: "taskmanager"
    description: "Toggles the task manager"

    TaskManagerPanel {
        anchors.centerIn: parent
        width: 640
        height: Math.min(730, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
