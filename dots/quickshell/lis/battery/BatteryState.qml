import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property int percent: 0
    property bool charging: false
    property bool available: false
    property string statusText: "Unknown"

    property int health: 100
    property bool healthAvailable: false

    // "performance" | "balanced" | "power-saver"
    property string profile: "balanced"
    property bool profileAvailable: false

    // list of profile names that actually exist on this system, e.g. ["balanced", "power-saver"]
    property var availableProfiles: []
    readonly property bool hasPerformance: availableProfiles.indexOf("performance") !== -1
    readonly property bool hasPowerSaver: availableProfiles.indexOf("power-saver") !== -1

    function refresh(): void {
        capProc.running = false
        capProc.running = true
        statProc.running = false
        statProc.running = true
        healthProc.running = false
        healthProc.running = true
        profileProc.running = false
        profileProc.running = true
        profileListProc.running = false
        profileListProc.running = true
    }

    function setProfile(name: string): void {
        setProfileProc.command = ["powerprofilesctl", "set", name]
        setProfileProc.running = false
        setProfileProc.running = true
        root.profile = name
    }

    property Process capProc: Process {
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || " +
            "cat /sys/class/power_supply/BAT1/capacity 2>/dev/null || echo -1"]
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (v < 0) {
                    root.available = false
                    return
                }
                root.available = true
                root.percent = Math.max(0, Math.min(100, v))
            }
        }
    }

    property Process statProc: Process {
        command: ["bash", "-c",
            "cat /sys/class/power_supply/BAT0/status 2>/dev/null || " +
            "cat /sys/class/power_supply/BAT1/status 2>/dev/null || echo Unknown"]
        stdout: SplitParser {
            onRead: data => {
                const v = data.trim()
                root.statusText = v.length > 0 ? v : "Unknown"
                root.charging = (v === "Charging" || v === "Full")
            }
        }
    }

    // Health = energy_full / energy_full_design (falls back to charge_*)
    property Process healthProc: Process {
        command: ["bash", "-c",
            "for B in BAT0 BAT1; do " +
            "  D=/sys/class/power_supply/$B; " +
            "  if [ -f \"$D/energy_full\" ] && [ -f \"$D/energy_full_design\" ]; then " +
            "    F=$(cat \"$D/energy_full\"); FD=$(cat \"$D/energy_full_design\"); " +
            "  elif [ -f \"$D/charge_full\" ] && [ -f \"$D/charge_full_design\" ]; then " +
            "    F=$(cat \"$D/charge_full\"); FD=$(cat \"$D/charge_full_design\"); " +
            "  else continue; fi; " +
            "  if [ \"$FD\" -gt 0 ] 2>/dev/null; then " +
            "    echo $((F * 100 / FD)); exit 0; " +
            "  fi; " +
            "done; echo -1"]
        stdout: SplitParser {
            onRead: data => {
                const v = parseInt(data.trim())
                if (v < 0) {
                    root.healthAvailable = false
                    return
                }
                root.healthAvailable = true
                root.health = Math.max(0, Math.min(100, v))
            }
        }
    }

    property Process profileProc: Process {
        command: ["bash", "-c", "powerprofilesctl get 2>/dev/null || echo -1"]
        stdout: SplitParser {
            onRead: data => {
                const v = data.trim()
                if (v === "-1" || v.length === 0) {
                    root.profileAvailable = false
                    return
                }
                root.profileAvailable = true
                root.profile = v
            }
        }
    }

    // Parses lines like "  performance:" or "* balanced:" into profile names
    property Process profileListProc: Process {
        command: ["bash", "-c",
            "powerprofilesctl list 2>/dev/null | grep -E '^[\\* ] *[a-zA-Z-]+:' | sed -E 's/^[\\* ]+//; s/:$//'"]
        property var collected: []
        stdout: SplitParser {
            onRead: data => {
                const v = data.trim()
                if (v.length > 0) {
                    profileListProc.collected.push(v)
                }
            }
        }
        onRunningChanged: {
            if (!running) {
                root.availableProfiles = profileListProc.collected
                profileListProc.collected = []
            } else {
                profileListProc.collected = []
            }
        }
    }

    property Process setProfileProc: Process {
        command: []
    }

    property Timer pollTimer: Timer {
        interval: 1000
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}