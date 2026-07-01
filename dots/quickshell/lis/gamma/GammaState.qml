import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property real gamma:      1.0
    property real brightness: 1.0
    property real contrast:   1.0
    property real saturation: 1.0

    function apply(): void {
        applyProc.command = [
            "wl-gammactl-rust",
            "-g", root.gamma.toFixed(2),
            "-b", root.brightness.toFixed(2),
            "-c", root.contrast.toFixed(2),
            "-s", root.saturation.toFixed(2)
        ]
        applyProc.running = false
        applyProc.running = true
    }

    function reset(): void {
        root.gamma      = 1.0
        root.brightness = 1.0
        root.contrast   = 1.0
        root.saturation = 1.0
        applyProc.running = false
    }

    property Process applyProc: Process {
        running: false
        command: []
    }
}
