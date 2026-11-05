import qs.common

PanelHost {
    id: root

    name: "notes"
    description: "Toggles the notes panel"

    NotesPanel {
        anchors.centerIn: parent
        width: Math.min(1100, parent.width - 160)
        height: Math.min(720, parent.height - 120)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
