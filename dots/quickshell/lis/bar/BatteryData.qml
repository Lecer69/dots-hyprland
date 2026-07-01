pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int percent: 0
    property bool charging: false
    property bool available: false
    property int activeViewers: 0

    Timer {
        id: pollTimer
        interval: 1000
        repeat: true
        running: root.activeViewers > 0
        triggeredOnStart: true
        onTriggered: battProc.running = true
    }

    Process {
        id: battProc
        command: ["bash", "-c",
            "for b in BAT0 BAT1; do " +
            "if [ -r /sys/class/power_supply/$b/capacity ]; then " +
            "cat /sys/class/power_supply/$b/capacity; " +
            "cat /sys/class/power_supply/$b/status; " +
            "exit 0; fi; done; echo -1; echo Unknown"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const v = parseInt(lines[0])
                const status = (lines[1] || "Unknown").trim()

                if (v < 0 || isNaN(v)) {
                    root.available = false
                    root.percent = -100
                    root.charging = false
                    return
                }

                root.available = true
                root.percent = Math.max(0, Math.min(100, v))
                root.charging = (status === "Charging" || status === "Full")
            }
        }
    }

    function addViewer() { activeViewers++ }
    function removeViewer() { activeViewers = Math.max(0, activeViewers - 1) }
}
