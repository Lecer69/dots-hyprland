import QtQuick
import Quickshell.Io

// A device's IPv4 address, read from NetworkManager whenever it turns active
// (Quickshell.Networking only exposes the hardware address)
Item {
    id: root

    property string device: ""
    property bool active: false
    property string address: ""

    function refresh(): void {
        if (root.active && root.device !== "")
            probe.running = true
    }

    onActiveChanged: refresh()
    onDeviceChanged: refresh()
    Component.onCompleted: refresh()

    Process {
        id: probe

        command: ["nmcli", "-g", "IP4.ADDRESS", "device", "show", root.device]

        stdout: StdioCollector {
            // "192.168.1.20/24", several are joined with " | "
            onStreamFinished: root.address = text.trim().split(" | ")[0].split("/")[0]
        }
    }
}
