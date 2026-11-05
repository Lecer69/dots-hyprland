import QtQuick
import Quickshell.Io

// One screen's brightness: ddcutil when the monitor answers to it, otherwise the backlight
QtObject {
    id: root

    required property string screenName

    // 0-1
    property real brightness: 0.5
    property bool ready: false

    property string busNum: ""
    property bool useBrightnessctl: false
    property string brightnessDevice: ""
    property real _pending: 0.5

    function setBrightness(value: real): void {
        if (!root.ready) return
        root.brightness = Math.max(0, Math.min(1, value))
        root._pending = root.brightness
        _settle.restart()
    }

    // What changed it elsewhere (a monitor's buttons, brightnessctl)
    function refresh(): void {
        if (!root.ready || _settle.running) return
        if (root.useBrightnessctl) _bctlList.running = true
        else _ddcRead.running = true
    }

    function _match(): void {
        if (!DdcMonitorState.ready || root.ready || root.busNum !== "" || root.useBrightnessctl) return

        const match = DdcMonitorState.findMatch(root.screenName)
        if (match) {
            root.busNum = match.busNum
            _ddcRead.running = true
        } else {
            console.log("ddcutil: no matching display for", root.screenName, "trying brightnessctl")
            root.useBrightnessctl = true
            _bctlList.running = true
        }
    }

    Component.onCompleted: {
        DdcMonitorState.ensureDetected()
        root._match()
    }

    property Connections _ddcWatcher: Connections {
        target: DdcMonitorState
        function onReadyChanged() {
            root._match()
        }
    }

    property Process _ddcRead: Process {
        command: ["ddcutil", "-b", root.busNum, "getvcp", "10", "--brief"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length < 5) return
                const current = parseInt(parts[3])
                const max = parseInt(parts[4])
                if (isNaN(current) || isNaN(max) || max <= 0) return
                root.brightness = current / max
                root.ready = true
            }
        }

        onExited: {
            if (root.ready) return
            console.log("ddcutil getvcp failed, falling back to brightnessctl")
            root.useBrightnessctl = true
            root._bctlList.running = true
        }
    }

    property Process _ddcWrite: Process {
        command: ["ddcutil", "-b", root.busNum, "setvcp", "10", "50"]
    }

    // device,class,current,percent,max
    property Process _bctlList: Process {
        command: ["brightnessctl", "--list", "--machine-readable"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",")
                if (parts.length < 5 || parts[1] !== "backlight") return
                if (root.brightnessDevice !== "" && parts[0] !== root.brightnessDevice) return
                root.brightnessDevice = parts[0]
                root.brightness = (parseInt(parts[2]) || 0) / (parseInt(parts[4]) || 100)
                root.ready = true
            }
        }

        onExited: code => {
            if (root.ready) return
            console.log("brightnessctl list failed (code " + code + "), trying sysfs")
            root._sysfsRead.running = true
        }
    }

    property Process _sysfsRead: Process {
        command: ["sh", "-c",
            "f=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -1); " +
            "[ -z \"$f\" ] && exit 1; " +
            "cur=$(cat $f); " +
            "max=$(cat $(dirname $f)/max_brightness); " +
            "dev=$(basename $(dirname $f)); " +
            "echo \"$dev,$cur,$max\""]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",")
                if (parts.length !== 3) return
                const max = parseInt(parts[2])
                if (max <= 0) return
                root.brightnessDevice = parts[0]
                root.brightness = parseInt(parts[1]) / max
                root.ready = true
            }
        }
    }

    property Process _bctlWrite: Process {
        command: ["brightnessctl", "--device", root.brightnessDevice, "set", "50%"]
    }

    property Timer _settle: Timer {
        interval: 300
        onTriggered: {
            if (root.useBrightnessctl) {
                const pct = Math.max(1, Math.round(root._pending * 100))
                root._bctlWrite.command = ["brightnessctl", "--device", root.brightnessDevice, "set", pct + "%"]
                root._bctlWrite.running = false
                root._bctlWrite.running = true
            } else {
                const raw = Math.max(1, Math.floor(root._pending * 100))
                root._ddcWrite.command = ["ddcutil", "-b", root.busNum, "setvcp", "10", raw + ""]
                root._ddcWrite.running = false
                root._ddcWrite.running = true
            }
        }
    }
}
