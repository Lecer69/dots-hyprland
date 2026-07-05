import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.hover

HoverBar {
    id: brightnessBar

    anchors.left: true

    property real brightness: 0.5
    property bool ready: false
    property real pendingBrightness: 0.5

    property string busNum: ""

    property bool useBrightnessctl: false
    property string brightnessDevice: ""
    property int brightnessMax: 100

    value: brightness
    onValueChanged: if (ready) BrightnessPopupState.show(value)

    Component.onCompleted: {
        DdcMonitorState.ensureDetected()
        tryMatch()
    }

    Connections {
        target: DdcMonitorState
        function onReadyChanged() {
            if (DdcMonitorState.ready) tryMatch()
        }
    }

    function tryMatch() {
        if (!DdcMonitorState.ready) return
        if (brightnessBar.ready || brightnessBar.busNum !== "") return // already resolved

        console.log("screen name:", brightnessBar.screen?.name)

        const match = DdcMonitorState.findMatch(brightnessBar.screen?.name)

        if (match) {
            brightnessBar.busNum = match.busNum
            initProc.running = true
        } else {
            console.log("ddcutil: no matching display for", brightnessBar.screen?.name,
                        "trying brightnessctl")
            brightnessBar.useBrightnessctl = true
            bctlListProc.running = true
        }
    }

    Process {
        id: initProc
        command: ["ddcutil", "-b", brightnessBar.busNum, "getvcp", "10", "--brief"]

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(/\s+/)
                if (parts.length >= 5) {
                    const current = parseInt(parts[3])
                    const max = parseInt(parts[4])
                    if (!isNaN(current) && !isNaN(max) && max > 0) {
                        brightnessBar.brightness = current / max
                        brightnessBar.ready = true
                    }
                }
            }
        }

        onExited: code => {
            if (!brightnessBar.ready) {
                console.log("ddcutil getvcp failed, falling back to brightnessctl")
                brightnessBar.useBrightnessctl = true
                bctlListProc.running = true
            }
        }
    }

    Process {
        id: setter
        command: ["ddcutil", "-b", brightnessBar.busNum, "setvcp", "10", "50"]
    }

    Process {
        id: bctlListProc
        command: ["brightnessctl", "--list", "--machine-readable"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                if (brightnessBar.brightnessDevice !== "") return   // already picked one
                const parts = data.trim().split(",")
                if (parts.length >= 4 && parts[1] === "backlight") {
                    brightnessBar.brightnessDevice = parts[0]
                    brightnessBar.brightnessMax    = parseInt(parts[3]) || 100
                    const current                  = parseInt(parts[2]) || 0
                    brightnessBar.brightness       = current / brightnessBar.brightnessMax
                    brightnessBar.ready            = true
                    console.log("brightnessctl device:", parts[0],
                                "brightness:", brightnessBar.brightness)
                }
            }
        }

        onExited: code => {
            if (!brightnessBar.ready) {
                console.log("brightnessctl list failed (code " + code + "), trying sysfs")
                sysfsReadProc.running = true
            }
        }
    }

    Process {
        id: sysfsReadProc
        command: ["sh", "-c",
            "f=$(ls /sys/class/backlight/*/brightness 2>/dev/null | head -1); " +
            "[ -z \"$f\" ] && exit 1; " +
            "cur=$(cat $f); " +
            "max=$(cat $(dirname $f)/max_brightness); " +
            "dev=$(basename $(dirname $f)); " +
            "echo \"$dev,$cur,$max\""]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(",")
                if (parts.length === 3) {
                    brightnessBar.brightnessDevice = parts[0]
                    const cur = parseInt(parts[1])
                    const max = parseInt(parts[2])
                    if (max > 0) {
                        brightnessBar.brightnessMax = max
                        brightnessBar.brightness    = cur / max
                        brightnessBar.ready         = true
                        console.log("sysfs device:", parts[0], "brightness:", brightnessBar.brightness)
                    }
                }
            }
        }
    }

    Process {
        id: bctlSetter
        command: ["brightnessctl", "--device", brightnessBar.brightnessDevice,
                  "set", "50%"]
    }

    Timer {
        id: settleTimer
        interval: 300
        onTriggered: {
            if (brightnessBar.useBrightnessctl) {
                const pct = Math.max(1, Math.round(brightnessBar.pendingBrightness * 100))
                bctlSetter.command = ["brightnessctl",
                                      "--device", brightnessBar.brightnessDevice,
                                      "set", pct + "%"]
                bctlSetter.running = false
                bctlSetter.running = true
            } else {
                const raw = Math.max(1, Math.floor(brightnessBar.pendingBrightness * 100))
                setter.command = ["ddcutil", "-b", brightnessBar.busNum,
                                  "setvcp", "10", raw + ""]
                setter.running = false
                setter.running = true
            }
        }
    }

    onScrolled: delta => {
        const newVal = Math.max(0, Math.min(1, brightnessBar.brightness + delta))
        brightnessBar.brightness       = newVal
        brightnessBar.pendingBrightness = newVal
        settleTimer.restart()
    }
}
