pragma Singleton

import QtQuick
import Quickshell
import qs.settings.data

// Each screen's workspace numbers: its pill count from the next x1, so Super+N is the Nth pill
Singleton {
    id: root

    // Landscape first, then left to right: the same order on every boot
    readonly property var screens: Array.from(Quickshell.screens).sort((a, b) =>
        ((a.height > a.width) - (b.height > b.width)) || (a.x - b.x) || a.name.localeCompare(b.name))

    // Screen name -> the first workspace of its block
    readonly property var firsts: {
        const bar = SettingsData.s.bar
        const firsts = {}
        let next = 1
        for (const screen of root.screens) {
            firsts[screen.name] = next
            const count = bar.workspaceNumbersPerMonitor[screen.name] ?? bar.workspaceNumbers
            next = Math.ceil((next + count - 1) / 10) * 10 + 1
        }
        return firsts
    }

    function firstOf(name: string): int {
        return root.firsts[name] ?? 1
    }

    function startOf(name: string): int {
        return SettingsData.s.bar.startWorkspacePerMonitor[name] ?? root.firstOf(name)
    }

    // The first workspace of the page holding `workspace`; pages count from the block, or from 1 below it
    function pageOf(name: string, workspace: int, size: int): int {
        const first = root.firstOf(name)
        const base = workspace >= first ? first : 1
        return base + Math.floor((workspace - base) / size) * size
    }

    // Two screens can't show one workspace, so the first one keeps it
    function focusStartWorkspaces(): void {
        const taken = {}
        for (const screen of root.screens) {
            const start = root.startOf(screen.name)
            if (taken[start])
                continue
            taken[start] = true
            HyprlandData.dispatchFocusMonitor(screen.name)
            HyprlandData.dispatchWorkspaceOnCurrentMonitor(start)
        }
        if (root.screens.length > 0)
            HyprlandData.dispatchFocusMonitor(root.screens[0].name)
    }
}
