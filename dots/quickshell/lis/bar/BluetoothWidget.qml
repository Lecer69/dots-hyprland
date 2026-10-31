import QtQuick
import Quickshell.Bluetooth
import qs.common

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: icon.height

    // BlueZ over D-Bus: nothing to poll
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property var connectedDevices: (root.adapter?.devices.values ?? []).filter(d => d.connected)

    function isAudio(device) {
        const name = device.icon ?? ""
        return name.startsWith("audio") || name.includes("headset") || name.includes("headphone")
    }

    readonly property string _iconName: {
        if (!root.adapter || !root.adapter.enabled) return "bluetooth-disabled"
        if (root.connectedDevices.length === 0) return "bluetooth"
        return root.connectedDevices.some(root.isAudio) ? "bluetooth-audio" : "bluetooth-connected"
    }

    Icon {
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
        onClicked: bluetoothWindow.shown = !bluetoothWindow.shown
    }
}
