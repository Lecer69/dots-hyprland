import QtQuick
import Quickshell.Networking

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: icon.height

    // NetworkManager state over D-Bus, updated as it changes (it used to
    // run nmcli every 5s in every bar)
    readonly property string _iconName: {
        const devices = Networking.devices.values
        if (devices.some(d => d.type === DeviceType.Wired && d.connected)) return "ethernet"

        const wifi = devices.find(d => d.type === DeviceType.Wifi && d.connected)
        const network = wifi?.networks.values.find(n => n.connected) ?? null
        if (!network) return "wifi-disconnect"

        const signal = Math.round(network.signalStrength * 100)
        if (signal <= 20) return "wifi-1b"
        if (signal <= 40) return "wifi-2b"
        if (signal <= 60) return "wifi-3b"
        if (signal <= 80) return "wifi-4b"
        return "wifi-5b"
    }

    Image {
        id: icon
        source: "../icons/" + root._iconName + ".svg"
        width: 18
        height: 18
        sourceSize: Qt.size(18, 18)
        antialiasing: true
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
        opacity: menuBtn.containsMouse ? 0.7 : 1.0
    }

    MouseArea {
        id: menuBtn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: networkWindow.shown = !networkWindow.shown
    }
}
