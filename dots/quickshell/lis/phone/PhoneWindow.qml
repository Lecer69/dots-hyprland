import qs.common

PanelHost {
    id: root

    name: "phone"
    description: "Toggles the phone panel"
    hidden: root.item?.picking ?? false

    signal settingsRequested()

    PhonePanel {
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 80)
        height: wantedHeight
        shown: root.panelShown
        onCloseRequested: root.close()
        onSettingsRequested: {
            root.close()
            root.settingsRequested()
        }
    }
}
