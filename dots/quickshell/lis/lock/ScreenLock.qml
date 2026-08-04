pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.tools
import qs.settings.data

QtObject {
    id: root

    property bool isLocked: false
    signal lockedChanged()

    property var _savedWorkspaces: ({})
    property bool _lockPending: false
    property var _wallpaperPaths: ({})
    property string _wallpaperFallback: ""

    Component.onCompleted: {
        if (SettingsData.s.lockScreen.enableBlur) {
            _wallpaperConfCat.running = true
        }
    }

    property Process _wallpaperConfCat: Process {
        id: wallpaperConfCat
        command: ["bash", "-c",
            "conf=\"$HOME/.config/hypr/hyprpaper.conf\"; " +
            "[ -f \"$conf\" ] || exit 0; " +
            "while IFS= read -r line; do " +
            "  trimmed=$(echo \"$line\" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'); " +
            "  case \"$trimmed\" in " +
            "    source\\ =*|source=*) " +
            "      src=$(echo \"$trimmed\" | sed -e 's/^source[[:space:]]*=[[:space:]]*//'); " +
            "      src=$(eval echo \"$src\"); " +
            "      for f in $src; do [ -f \"$f\" ] && cat \"$f\"; done ;; " +
            "    *) echo \"$line\" ;; " +
            "  esac; " +
            "done < \"$conf\""
        ]
        stdout: StdioCollector { id: wallpaperConfOutput }
        onRunningChanged: {
            if (!running) {
                root._parseWallpaperConf(wallpaperConfOutput.text)
            }
        }
    }

    function _parseWallpaperConf(text) {
        var map = {}
        var fallback = ""
        var lines = text.split("\n")

        var inBlock = false
        var curMonitor = null
        var curPath = null

        function flush() {
            if (curPath === null) return
            var path = root._expandPath(curPath)
            if (curMonitor && curMonitor.length > 0) {
                map[curMonitor] = path
            } else {
                fallback = path
            }
        }

        for (var i = 0; i < lines.length; i++) {
            var raw = lines[i]
            var line = raw.trim()
            if (line.length === 0 || line.startsWith("#")) continue

            if (line.startsWith("wallpaper") && line.indexOf("{") >= 0) {
                inBlock = true
                curMonitor = null
                curPath = null
                continue
            }
            if (inBlock && line === "}") {
                flush()
                inBlock = false
                continue
            }
            if (!inBlock) continue

            var eq = line.indexOf("=")
            if (eq < 0) continue
            var key = line.slice(0, eq).trim()
            var val = line.slice(eq + 1).trim()

            if (key === "monitor") {
                curMonitor = val
            } else if (key === "path") {
                curPath = val
            }
        }

        root._wallpaperPaths = map
        root._wallpaperFallback = fallback
    }

    function _expandPath(p) {
        if (p.startsWith("~/") || p === "~") {
            var home = Quickshell.env("HOME") ?? ""
            return home + p.slice(1)
        }
        return p
    }

    function wallpaperFor(monitorName) {
        if (monitorName && root._wallpaperPaths[monitorName]) {
            return root._wallpaperPaths[monitorName]
        }
        return root._wallpaperFallback
    }

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

        if (SettingsData.s.lockScreen.enableBlur) {
            _wallpaperConfCat.running = true
        }

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

    property LockContext _ctx: LockContext {
        id: lockCtx
        onUnlocked: root._unlock()
        onUnlockedWithPassword: (pw) => {
            Quickshell.execDetached(["sh", "-c", "echo -n \"" + pw + "\" | gnome-keyring-daemon --replace --unlock --components=secrets"])
        }
    }

    property WlSessionLock _wlLock: WlSessionLock {
        id: _wlLock
        locked: false

        WlSessionLockSurface {
            id: lockSurfaceRoot
            color: "transparent"

            readonly property bool isVertical: screen ? screen.height > screen.width : false
            readonly property bool blockThisScreen: SettingsData.s.lockScreen.blockVerticalScreens && isVertical

            Rectangle {
                anchors.fill: parent
                visible: lockSurfaceRoot.blockThisScreen
                color: "black"
            }

            LockSurface {
                id: lockSurfaceItem
                anchors.fill: parent
                context: lockCtx
                visible: !lockSurfaceRoot.blockThisScreen
                enableBlur: SettingsData.s.lockScreen.enableBlur
                blurSize: SettingsData.s.lockScreen.blurSize
                blurPasses: SettingsData.s.lockScreen.blurPasses
                brightness: SettingsData.s.lockScreen.brightness
                wallpaperPath: root.wallpaperFor(lockSurfaceRoot.screen ? lockSurfaceRoot.screen.name : "")
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