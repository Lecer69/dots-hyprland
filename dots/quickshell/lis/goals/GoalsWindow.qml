import qs.common

PanelHost {
    id: root

    name: "goals"
    description: "Toggles the goals panel"

    // Saves a title being typed now, not after the pause
    onShownChanged: if (!shown) GoalsService.flush()

    GoalsPanel {
        anchors.centerIn: parent
        width: Math.min(600, parent.width - 80)
        height: Math.min(640, parent.height - 80)
        onCloseRequested: root.close()
    }
}
