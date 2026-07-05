pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    property var monitors: []
    property bool ready: false
    property bool detecting: false

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
                    if (busLine && drmLine) {
                        const bus = busLine.split("/dev/i2c-")[1]
                        const drm = drmLine.split("DRM connector:")[1].trim()
                        DdcMonitorState.monitors.push({ name: drm, busNum: bus })
                    }
                }
            }
        }

        onExited: code => {
            console.log("DdcMonitorState: ddcutil detect exited, code:", code,
                        "found:", JSON.stringify(DdcMonitorState.monitors))
            DdcMonitorState.ready = true
            DdcMonitorState.detecting = false
        }
    }

    function ensureDetected() {
        if (ready || detecting) return
        detecting = true
        monitors = []
        _proc.running = true
    }

    function findMatch(screenName) {
        return monitors.find(m => {
            const stripped = m.name.replace(/^card\d+-/, "")
            return stripped === screenName
        }) || null
    }
}
