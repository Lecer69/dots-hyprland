import qs.common

PanelHost {
    id: root

    name: "proton"
    description: "Toggles the Proton panel"
    hidden: root.item?.picking ?? false

    ProtonPanel {
        anchors.centerIn: parent
        width: 720
        height: Math.min(720, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
