import qs.common

PanelHost {
    id: root

    name: "network"
    description: "Toggles the network panel"

    NetworkPanel {
        anchors.centerIn: parent
        width: 460
        height: Math.min(implicitHeight, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
