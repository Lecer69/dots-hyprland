import qs.common

PanelHost {
    id: root

    name: "bluetooth"
    description: "Toggles the Bluetooth panel"

    BluetoothPanel {
        anchors.centerIn: parent
        width: 460
        height: Math.min(implicitHeight, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
