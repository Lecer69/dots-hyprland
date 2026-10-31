import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.common
import qs.settings.components

PanelFrame {
    id: root

    property bool shown: false

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool powered: adapter !== null && adapter.enabled
    readonly property var allDevices: adapter ? adapter.devices.values : []

    property string expandedAddress: ""
    property var pairedDevices: []
    property var availableDevices: []
    property string _order: ""

    // Connected first; unnamed devices are left out
    readonly property var _sorted: {
        const byName = (a, b) => a.name.localeCompare(b.name)
        return {
            paired: root.allDevices.filter(d => d.paired).sort((a, b) => (b.connected - a.connected) || byName(a, b)),
            available: root.allDevices.filter(d => !d.paired && d.deviceName !== "").sort(byName)
        }
    }

    // Only when the order changes, so rows aren't rebuilt on every update
    function syncDevices(): void {
        const order = root._sorted.paired.map(d => d.address).join(",")
            + "|" + root._sorted.available.map(d => d.address).join(",")
        if (order === root._order) return
        root._order = order
        root.pairedDevices = root._sorted.paired
        root.availableDevices = root._sorted.available
    }

    function updateDiscovery(): void {
        if (root.powered) root.adapter.discovering = root.shown
    }

    on_SortedChanged: syncDevices()
    onPoweredChanged: updateDiscovery()
    onShownChanged: {
        updateDiscovery()
        if (!shown) root.expandedAddress = ""
    }
    Component.onCompleted: syncDevices()

    title: "Bluetooth"
    subtitle: {
        if (!root.adapter) return ""
        if (!root.powered) return "Off"
        const connected = root.allDevices.filter(d => d.connected)
        if (connected.length === 1) return connected[0].name
        if (connected.length > 1) return connected.length + " connected"
        return "On"
    }
    implicitHeight: headerHeight + 8 + content.implicitHeight + 24

    ColumnLayout {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 20

        RowLayout {
            visible: root.adapter !== null && root.adapter.state !== BluetoothAdapterState.Blocked
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Theme.text
                font.pixelSize: 13
            }

            ToggleSwitch {
                id: powerToggle

                checked: root.powered
                onToggled: v => {
                    root.adapter.enabled = v
                    powerToggle.checked = Qt.binding(() => root.powered)
                }
            }
        }

        Text {
            visible: text !== ""
            Layout.fillWidth: true
            Layout.topMargin: 4
            Layout.bottomMargin: 4
            horizontalAlignment: Text.AlignHCenter
            color: Theme.textDim
            font.pixelSize: 13
            text: {
                if (!root.adapter) return "No Bluetooth adapter found"
                if (root.adapter.state === BluetoothAdapterState.Blocked) return "Bluetooth is blocked by a hardware or software switch"
                if (!root.powered) return "Bluetooth is off"
                return ""
            }
        }

        ColumnLayout {
            visible: root.powered && root.pairedDevices.length > 0
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "My devices"
                color: Theme.textDim
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Repeater {
                model: root.pairedDevices

                BluetoothDeviceItem {
                    required property var modelData

                    Layout.fillWidth: true
                    device: modelData
                    expanded: root.expandedAddress === modelData.address
                    onToggleRequested: root.expandedAddress = expanded ? "" : modelData.address
                }
            }
        }

        ColumnLayout {
            visible: root.powered
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Available devices"
                color: Theme.textDim
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Text {
                visible: root.availableDevices.length === 0
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                horizontalAlignment: Text.AlignHCenter
                text: root.adapter && root.adapter.discovering ? "Searching for devices…" : "No devices found"
                color: Theme.textDim
                font.pixelSize: 13
            }

            Flickable {
                id: availableList

                visible: root.availableDevices.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(availableColumn.implicitHeight, 280)
                contentHeight: availableColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: availableColumn

                    width: availableList.width
                    spacing: 2

                    Repeater {
                        model: root.availableDevices

                        BluetoothDeviceItem {
                            required property var modelData

                            width: availableColumn.width
                            device: modelData
                            expanded: root.expandedAddress === modelData.address
                            onToggleRequested: root.expandedAddress = expanded ? "" : modelData.address
                        }
                    }
                }
            }
        }
    }
}
