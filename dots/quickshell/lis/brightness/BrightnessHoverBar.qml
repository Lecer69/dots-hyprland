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
    property var ddcMonitors: []

    property bool useBrightnessctl: false
    property string brightnessDevice: ""
    property int brightnessMax: 100

    value: brightness
    onValueChanged: if (ready) BrightnessPopupState.show(value)

    Process {
        id: detectProc
        command: ["ddcutil", "detect", "--brief"]
        running: true

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
                        brightnessBar.ddcMonitors.push({ name: drm, busNum: bus })
                    }
                }
            }
        }

        onExited: code => {
            console.log("ddcutil detect exited, code:", code)
            console.log("screen name:", brightnessBar.screen?.name)

            const match = brightnessBar.ddcMonitors.find(m => {
                const stripped = m.name.replace(/^card\d+-/, "")
                return stripped === brightnessBar.screen?.name
            })

            if (match) {
                brightnessBar.busNum = match.busNum
                initProc.running = true
            } else {
                // No valid ddcutil display found — fall back to brightnessctl
                console.log("ddcutil: no matching display, trying brightnessctl")
                brightnessBar.useBrightnessctl = true
                bctlListProc.running = true
            }
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
