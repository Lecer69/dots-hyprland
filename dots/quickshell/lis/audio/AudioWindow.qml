import qs.common

PanelHost {
    id: root

    name: "audio"
    description: "Toggles the audio panel"

    AudioPanel {
        anchors.centerIn: parent
        width: 460
        height: Math.min(implicitHeight, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
