import qs.common

PanelHost {
    id: root

    name: "battery"
    description: "Toggles the battery panel"

    BatteryPanel {
        anchors.centerIn: parent
        width: 460
        height: contentHeight
        visible: root.panelShown
        onCloseRequested: root.close()
    }
}
