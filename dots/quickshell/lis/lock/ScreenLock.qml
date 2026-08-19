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

    property var _wallpaperPaths: ({})
    property string _wallpaperFallback: ""

    Component.onCompleted: {
        if (SettingsData.s.lockScreen.enableBlur) {
            _hyprctlActiveQuery.running = true
        }
    }

    property bool _wallpaperResolvedForBlur: false

    onEnableBlurStateChanged: {
        var enabled = SettingsData.s.lockScreen.enableBlur
        if (enabled && !root._wallpaperResolvedForBlur) {
            root._wallpaperResolvedForBlur = true
            _hyprctlActiveQuery.running = true
        } else if (!enabled) {
            root._wallpaperResolvedForBlur = false
        }
    }

    signal enableBlurStateChanged()

    property Connections _enableBlurWatcher: Connections {
        target: SettingsData.s ? SettingsData.s.lockScreen : null
        function onEnableBlurChanged() {
            root.enableBlurStateChanged()
        }
    }

    property Process _hyprctlActiveQuery: Process {
        id: hyprctlActiveQuery
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector { id: hyprctlActiveOutput }
        stderr: StdioCollector { id: hyprctlActiveError }
        onRunningChanged: {
            if (!running) {
                var resolvedOk = false
                if (hyprctlActiveQuery.exitCode === 0) {
                    var out = hyprctlActiveOutput.text.trim()
                    if (out.length > 0) {
                        resolvedOk = root._parseHyprctlActive(out)
                    }
                }

                if (!resolvedOk) {
                    _wallpaperConfCat.running = true
                }
            }
        }
    }

    function _parseHyprctlActive(text) {
        var map = {}
        var lines = text.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length === 0) continue
            var eq = line.indexOf("=")
            if (eq < 0) continue
            var mon = line.slice(0, eq).trim()
            var path = line.slice(eq + 1).trim()
            if (mon.length === 0 || path.length === 0) continue
            map[mon] = path
        }
        var merged = Object.assign({}, root._wallpaperPaths, map)
        root._wallpaperPaths = merged
        root._hpHyprctlMonitors = Object.keys(map)
        return Object.keys(map).length > 0
    }

    property var _hpHyprctlMonitors: []

    property Process _wallpaperConfCat: Process {
        id: wallpaperConfCat
        command: ["bash", "-c",
            "conf=\"$HOME/.config/hypr/hyprpaper.conf\"; " +
            "if [ ! -f \"$conf\" ]; then echo \"HYPRPAPER_CONF_MISSING:$conf\" >&2; exit 0; fi; " +
            "while IFS= read -r line; do " +
            "  trimmed=$(echo \"$line\" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'); " +
            "  case \"$trimmed\" in " +
            "    source\\ =*|source=*) " +
            "      src=$(echo \"$trimmed\" | sed -e 's/^source[[:space:]]*=[[:space:]]*//'); " +
            "      src=$(eval echo \"$src\"); " +
            "      for f in $src; do " +
            "        if [ -f \"$f\" ]; then cat \"$f\"; else echo \"HYPRPAPER_SOURCE_MISSING:$f\" >&2; fi; " +
            "      done ;; " +
            "    *) echo \"$line\" ;; " +
            "  esac; " +
            "done < \"$conf\""
        ]
        stdout: StdioCollector { id: wallpaperConfOutput }
        stderr: StdioCollector { id: wallpaperConfError }
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

        var hyprctlMonitors = root._hpHyprctlMonitors || []
        for (var k = 0; k < hyprctlMonitors.length; k++) {
            var name = hyprctlMonitors[k]
            if (map.hasOwnProperty(name)) {
                delete map[name]
            }
        }

        root._wallpaperPaths = Object.assign({}, root._wallpaperPaths, map)
        if (fallback.length > 0 || root._wallpaperFallback.length === 0) {
            root._wallpaperFallback = fallback
        }
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

    function _focusFirstHorizontalMonitor() {
        var screens = Quickshell.screens
        for (var j = 0; j < screens.length; j++) {
            var s = screens[j]
            if (s.width >= s.height) {
                HyprlandData.dispatchFocusMonitor(s.name)
                break
            }
        }
    }

    function lock() {
        if (root.isLocked || _wlLock.locked) return
        root.isLocked = true

        if (SettingsData.s.lockScreen.enableBlur) {
            _hyprctlActiveQuery.running = true
        }

        _wlLock.locked = true
        Qt.callLater(root._focusFirstHorizontalMonitor)

        root.lockedChanged()
    }

    function refocusLock() {
        if (!root.isLocked) return
        Qt.callLater(root._focusFirstHorizontalMonitor)
    }

    function _unlock() {
        _wlLock.locked = false
        root.isLocked = false

        Qt.callLater(root._focusFirstHorizontalMonitor)

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

        onLockedChanged: {
            if (!locked && root.isLocked) {
                // Compositor tore down the lock out from under us
                // (e.g. another lock client grabbed it, or a race
                // with unlock). Keep our flag in sync so lock()
                // stays callable and doesn't re-enter while stale.
                root.isLocked = false
                root.lockedChanged()
            }
        }

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
        onPressed: root.refocusLock()
    }
}