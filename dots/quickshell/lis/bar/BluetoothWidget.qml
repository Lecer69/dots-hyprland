import QtQuick
import Quickshell.Bluetooth
import Quickshell.Io

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: icon.height

    // BlueZ state over D-Bus, updated as it changes: nothing to poll, and
    // nothing to hang when bluetoothd isn't running
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

    Image {
        id: icon
        source: "../icons/" + root._iconName + ".svg"
        width: 18
        height: 18
        mipmap: true
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
        onClicked: if (!kcmProc.running) kcmProc.running = true
    }

    Process {
        id: kcmProc
        command: ["kcmshell6", "kcm_bluetooth"]
    }
}
