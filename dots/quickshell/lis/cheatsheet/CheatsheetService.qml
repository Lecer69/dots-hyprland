pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property var keybinds: []
    property var keybindCategories: []

    function refresh() {
        getKeybinds.running = true
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name == "configreloaded") {
                root.refresh()
            }
        }
    }

    Process {
        id: getKeybinds
        running: true
        command: ["hyprctl", "binds", "-j"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    root.keybinds = parsed

                    const groups = []
                    for (let i = 0; i < parsed.length; i++) {
                        const desc = parsed[i].description || ""
                        const idx = desc.indexOf(":")
                        if (idx <= 0) continue
                        const group = desc.substring(0, idx).trim()
                        if (group.length > 0 && !groups.includes(group)) {
                            groups.push(group)
                        }
                    }
                    root.keybindCategories = groups

                    const withDesc = parsed.filter(b => b.description && b.description.length > 0).length
                    console.log("[Cheatsheet] loaded", parsed.length, "binds (", withDesc, "described,",
                        parsed.length - withDesc, "fallback ), categories:", JSON.stringify(groups))
                } catch (e) {
                    console.error("[Cheatsheet] Failed to parse hyprctl binds output:", e)
                }
            }
        }
    }
}