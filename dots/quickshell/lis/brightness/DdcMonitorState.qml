pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    property var monitors: []
    property bool ready: false
    property bool detecting: false
    property var _unresolved: []

    property var _proc: Process {
        command: ["ddcutil", "detect", "--brief"]
        running: false

        stdout: SplitParser {
            splitMarker: "\n\n"
            onRead: data => {
                if (data.startsWith("Display ")) {
                    const lines = data.split("\n").map(l => l.trim())
                    const busLine = lines.find(l => l.startsWith("I2C bus:"))
                    const drmLine = lines.find(l => l.startsWith("DRM connector:"))
                    const monLine = lines.find(l => l.startsWith("Monitor:"))
                    if (!busLine) return
                    const bus = busLine.split("/dev/i2c-")[1]
                    if (drmLine) {
                        const drm = drmLine.split("DRM connector:")[1].trim()
                        DdcMonitorState.monitors.push({ name: drm, busNum: bus })
                    } else if (monLine) {
                        // "Monitor: MFG:MODEL:SERIAL"
                        const serial = monLine.slice(monLine.lastIndexOf(":") + 1).trim()
                        if (serial.length >= 4)
                            DdcMonitorState._unresolved.push({ busNum: bus, serial: serial })
                    }
                }
            }
        }

        onExited: code => {
            console.log("DdcMonitorState: ddcutil detect exited, code:", code,
                        "unresolved:", JSON.stringify(DdcMonitorState._unresolved))
            if (DdcMonitorState._unresolved.length > 0) {
                const args = []
                DdcMonitorState._unresolved.forEach(u => args.push(u.busNum, u.serial))
                DdcMonitorState._edidProc.command = ["sh", "-c",
                    "while [ $# -ge 2 ]; do " +
                    "m=; n=0; " +
                    // sysfs reports edid as size 0, so it's read through a pipe
                    "for f in /sys/class/drm/card*-*/edid; do " +
                    "cat \"$f\" | grep -qaF -- \"$2\" && { m=$(basename $(dirname \"$f\")); n=$((n+1)); }; " +
                    "done; " +
                    "[ $n -eq 1 ] && echo \"$1 $m\"; " +
                    "shift 2; " +
                    "done", "sh"].concat(args)
                DdcMonitorState._edidProc.running = true
            } else {
                DdcMonitorState._finish()
            }
        }
    }

    property var _edidProc: Process {
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(" ")
                if (parts.length === 2)
                    DdcMonitorState.monitors.push({ name: parts[1], busNum: parts[0] })
            }
        }

        onExited: DdcMonitorState._finish()
    }

    function _finish() {
        console.log("DdcMonitorState: found:", JSON.stringify(monitors))
        ready = true
        detecting = false
    }

    function ensureDetected() {
        if (ready || detecting) return
        detecting = true
        monitors = []
        _unresolved = []
        _proc.running = true
    }

    function findMatch(screenName) {
        return monitors.find(m => {
            const stripped = m.name.replace(/^card\d+-/, "")
            return stripped === screenName
        }) || null
    }
}
