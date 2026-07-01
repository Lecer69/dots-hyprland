pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.tools

QtObject {
    id: root

    property bool isLocked: false
    signal lockedChanged()

    property var _savedWorkspaces: ({})
    property bool _lockPending: false

    property Process _monitorsQuery: Process {
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector { id: monitorsJson }
        onRunningChanged: {
            if (!running && root._lockPending) {
                root._lockPending = false
                root._applyLock(monitorsJson.text.trim())
            }
        }
    }

    function lock() {
        if (root.isLocked) return
        root.isLocked = true
        _wlLock.locked = true
        root._lockPending = true
        _monitorsQuery.running = true
        root.lockedChanged()
    }

    function _applyLock(json) {
        var monitors
        try { monitors = JSON.parse(json) } catch(e) { _wlLock.locked = true; return }

        var saves = {}
        for (var i = 0; i < monitors.length; i++) {
            var mon = monitors[i]
            saves[mon.name] = mon.activeWorkspace.id
            var emptyWs = 2147483647 - i
            HyprlandData.dispatchFocusMonitor(mon.name)
            HyprlandData.dispatchMoveWorkspaceToMonitor(emptyWs, mon.name)
            HyprlandData.dispatchWorkspace(emptyWs)
        }
        root._savedWorkspaces = saves

        var screens = Quickshell.screens
        for (var j = 0; j < screens.length; j++) {
            var s = screens[j]
            if (s.width >= s.height) {
                HyprlandData.dispatchFocusMonitor(s.name)
                break
            }
        }
    }

    function _unlock() {
        _wlLock.locked = false
        root.isLocked = false

        var saves = root._savedWorkspaces
        var names = Object.keys(saves)
        for (var i = 0; i < names.length; i++) {
            var name = names[i]
            var ws = saves[name]
            HyprlandData.dispatchFocusMonitor(name)
            HyprlandData.dispatchMoveWorkspaceToMonitor(ws, name)
            HyprlandData.dispatchWorkspace(ws)
        }
        root._savedWorkspaces = {}

        var screens = Quickshell.screens
        for (var j = 0; j < screens.length; j++) {
            var s = screens[j]
            if (s.width >= s.height) {
                HyprlandData.dispatchFocusMonitor(s.name)
                break
            }
        }

        root.lockedChanged()
    }

    property Process _keyringUnlock: Process {
        id: keyringUnlock
        command: ["gnome-keyring-daemon", "--unlock"]
        stdinEnabled: true
        onStarted: {
            keyringUnlock.write(_pendingPassword + "\n")
            _pendingPassword = ""
        }
    }

    property string _pendingPassword: ""

    property LockContext _ctx: LockContext {
        id: lockCtx
        onUnlocked: root._unlock()
        onUnlockedWithPassword: (pw) => {
            root._pendingPassword = pw
            keyringUnlock.running = true
        }
    }

    property WlSessionLock _wlLock: WlSessionLock {
        id: _wlLock
        locked: false

        WlSessionLockSurface {
            color: "transparent"
            LockSurface {
                anchors.fill: parent
                context: lockCtx
            }
        }
    }

    property GlobalShortcut _shortcutLock: GlobalShortcut {
        name: "lock"
        description: "Lock the screen"
        onPressed: root.lock()
    }

    property GlobalShortcut _shortcutFocus: GlobalShortcut {
        name: "lockFocus"
        description: "Re-focus lock input after suspend/resume"
        onPressed: root.lock()
    }
}