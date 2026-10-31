import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common

Item {
    id: root

    required property var device
    property bool panelShown: false

    readonly property bool busy: device.state === ConnectionState.Connecting
        || device.state === ConnectionState.Disconnecting

    implicitHeight: 52

    IpAddressProbe {
        id: ip

        device: root.device.name
        active: root.panelShown && root.device.connected
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 12

        Icon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            source: "../icons/ethernet.svg"
            sourceSize: Qt.size(16, 16)
            fillMode: Image.PreserveAspectFit
            opacity: root.device.connected ? 1 : 0.5
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Ethernet"
                color: Theme.text
                font.pixelSize: 13
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: 12
                text: {
                    const d = root.device
                    if (d.state === ConnectionState.Connecting) return "Connecting…"
                    if (d.state === ConnectionState.Disconnecting) return "Disconnecting…"
                    if (!d.connected) return d.name + (d.hasLink ? " · Disconnected" : " · Cable unplugged")
                    const speed = d.linkSpeed >= 1000 ? (d.linkSpeed / 1000) + " Gb/s" : d.linkSpeed + " Mb/s"
                    return [d.name, d.linkSpeed > 0 ? speed : "", ip.address].filter(s => s !== "").join(" · ")
                }
            }
        }

        PanelButton {
            visible: !root.busy && (root.device.connected || root.device.hasLink)
            text: root.device.connected ? "Disconnect" : "Connect"
            onClicked: {
                if (root.device.connected)
                    root.device.disconnect()
                else if (root.device.network)
                    root.device.network.connect()
            }
        }
    }
}
