import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common
import qs.settings.components

PanelFrame {
    id: root

    property bool shown: false

    readonly property var wiredDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wired)
    readonly property var wifiDevices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)

    property string expandedName: ""
    // Null while the prompt is closed
    property var passwordTarget: null
    property var wifiNetworks: []
    property string _networkOrder: ""

    // Connected, saved, then strongest; signal is bucketed so the list doesn't jitter
    readonly property var _sortedNetworks: {
        const all = []
        for (const device of root.wifiDevices) {
            for (const network of device.networks.values) {
                if (network.name !== "") all.push(network)
            }
        }
        return all.sort((a, b) => (b.connected - a.connected)
            || (b.known - a.known)
            || (Math.round(b.signalStrength * 5) - Math.round(a.signalStrength * 5))
            || a.name.localeCompare(b.name))
    }

    readonly property string statusText: {
        let text = "Disconnected"
        if (root.wiredDevices.some(d => d.connected)) {
            text = "Ethernet"
        } else {
            const wifi = root._sortedNetworks.find(n => n.connected)
            if (wifi) text = wifi.name
        }
        if (Networking.connectivity === NetworkConnectivity.Limited) text += " · Limited"
        else if (Networking.connectivity === NetworkConnectivity.Portal) text += " · Sign-in required"
        return text
    }

    // Only when the order changes, so rows aren't rebuilt on every update
    function syncNetworks(): void {
        const order = root._sortedNetworks.map(n => n.name).join("\n")
        if (order === root._networkOrder) return
        root._networkOrder = order
        root.wifiNetworks = root._sortedNetworks
    }

    function updateScanning(): void {
        for (const device of root.wifiDevices)
            device.scannerEnabled = root.shown
    }

    function submitPassword(): void {
        if (!root.passwordTarget || passwordInput.text === "") return
        root.passwordTarget.connectWithPsk(passwordInput.text)
        root.passwordTarget = null
    }

    on_SortedNetworksChanged: syncNetworks()
    onWifiDevicesChanged: updateScanning()
    onShownChanged: {
        updateScanning()
        if (!shown) {
            root.expandedName = ""
            root.passwordTarget = null
        }
    }
    onPasswordTargetChanged: {
        passwordInput.text = ""
        if (root.passwordTarget) passwordInput.forceActiveFocus()
    }
    Component.onCompleted: syncNetworks()

    title: "Network"
    subtitle: root.statusText
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

        ColumnLayout {
            visible: root.wiredDevices.length > 0
            Layout.fillWidth: true
            spacing: 4

            Text {
                text: "Wired"
                color: "#6b6b6b"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Repeater {
                model: root.wiredDevices

                WiredDeviceItem {
                    required property var modelData

                    Layout.fillWidth: true
                    device: modelData
                    panelShown: root.shown
                }
            }
        }

        ColumnLayout {
            visible: root.wifiDevices.length > 0
            Layout.fillWidth: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Wi-Fi"
                    color: "#6b6b6b"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                ToggleSwitch {
                    id: wifiToggle

                    visible: Networking.wifiHardwareEnabled
                    checked: Networking.wifiEnabled
                    onToggled: v => {
                        Networking.wifiEnabled = v
                        wifiToggle.checked = Qt.binding(() => Networking.wifiEnabled)
                    }
                }
            }

            Text {
                visible: text !== ""
                Layout.fillWidth: true
                Layout.topMargin: 12
                Layout.bottomMargin: 12
                horizontalAlignment: Text.AlignHCenter
                color: "#6b6b6b"
                font.pixelSize: 13
                text: {
                    if (!Networking.wifiHardwareEnabled) return "Wi-Fi is turned off by a hardware switch"
                    if (!Networking.wifiEnabled) return "Wi-Fi is off"
                    if (root.wifiNetworks.length === 0) return "Searching for networks…"
                    return ""
                }
            }

            // For a secured network that isn't saved yet
            Rectangle {
                visible: root.passwordTarget !== null
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: prompt.implicitHeight + 24
                radius: 8
                color: "#161616"

                ColumnLayout {
                    id: prompt

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        text: "Password for " + (root.passwordTarget ? root.passwordTarget.name : "")
                        color: "#e6e6e6"
                        font.pixelSize: 13
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 28
                            radius: 6
                            color: "#1f1f1f"

                            TextInput {
                                id: passwordInput

                                activeFocusOnTab: true
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                echoMode: TextInput.Password
                                color: "#e6e6e6"
                                font.pixelSize: 13
                                clip: true
                                selectByMouse: true

                                Keys.onReturnPressed: root.submitPassword()
                                Keys.onEnterPressed: root.submitPassword()

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: passwordInput.text.length === 0
                                    text: "Password"
                                    color: "#6b6b6b"
                                    font.pixelSize: 13
                                }
                            }
                        }

                        PanelButton {
                            text: "Cancel"
                            onClicked: root.passwordTarget = null
                        }

                        PanelButton {
                            text: "Connect"
                            onClicked: root.submitPassword()
                        }
                    }
                }
            }

            Flickable {
                id: wifiList

                visible: Networking.wifiEnabled && root.wifiNetworks.length > 0
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(wifiColumn.implicitHeight, 360)
                contentHeight: wifiColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: wifiColumn

                    width: wifiList.width
                    spacing: 2

                    Repeater {
                        model: root.wifiNetworks

                        WifiNetworkItem {
                            required property var modelData

                            width: wifiColumn.width
                            network: modelData
                            expanded: root.expandedName === modelData.name
                            onToggleRequested: root.expandedName = expanded ? "" : modelData.name
                            onPasswordRequested: root.passwordTarget = modelData
                        }
                    }
                }
            }
        }

        Text {
            visible: root.wiredDevices.length === 0 && root.wifiDevices.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 12
            horizontalAlignment: Text.AlignHCenter
            text: "No network devices"
            color: "#6b6b6b"
            font.pixelSize: 13
        }
    }
}
