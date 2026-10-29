pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import qs.tools
import qs.settings.data

QtObject {
    id: root

    property bool isLocked: false
    signal lockedChanged()

    // Pre-blurred wallpaper disk cache (instant lock, re-blurs on wallpaper update)
    property WallpaperBlurCache _blurCache: WallpaperBlurCache {}

    // monitor -> wallpaper. hyprpaper.conf is read synchronously, since at
    // boot the lock shows before hyprpaper is even running; hyprpaper's
    // live state takes precedence once it answers (runtime changes).
    property var _confWallpapers: ({})
    property string _confFallback: ""
    property var _liveWallpapers: ({})

    function wallpaperFor(monitorName) {
        if (monitorName) {
            if (root._liveWallpapers[monitorName]) return root._liveWallpapers[monitorName]
            if (root._confWallpapers[monitorName]) return root._confWallpapers[monitorName]
        }
        return root._confFallback
    }

    property bool _initialized: false

    // Everything the first lock needs, without spawning a process: settings
    // (loaded synchronously by SettingsData), wallpapers (conf file) and
    // the cached blur (stamp files). Called from lock() too, since the boot
    // lock can run before this object's onCompleted.
    function _init() {
        if (root._initialized) return
        root._initialized = true
        root._parseHyprpaperConf()
        root._hyprpaperQuery.running = true
    }

    Component.onCompleted: root._init()

    // Primes (sync) and validates (background) the blur for every screen
    // that will show a lock surface, so the next lock is instant
    function _warmBlurCache() {
        const ls = SettingsData.s.lockScreen
        if (!ls.enableBlur) return
        const seen = {}
        const screens = Quickshell.screens
        for (let i = 0; i < screens.length; i++) {
            const s = screens[i]
            if (ls.blockVerticalScreens && s.height > s.width) continue
            const wp = root.wallpaperFor(s.name)
            if (!wp || seen[wp]) continue
            seen[wp] = true
            root._blurCache.prime(wp, ls.blurSize, ls.blurPasses)
            root._blurCache.ensureCached(wp, ls.blurSize, ls.blurPasses)
        }
    }

    // Re-warm after settings/screen changes settle (sliders fire per step)
    property Timer _warmDebounce: Timer {
        interval: 1500
        onTriggered: root._warmBlurCache()
    }

    property Connections _lockSettingsWatcher: Connections {
        target: SettingsData.s.lockScreen
        function onEnableBlurChanged() { root._warmDebounce.restart() }
        function onBlurSizeChanged() { root._warmDebounce.restart() }
        function onBlurPassesChanged() { root._warmDebounce.restart() }
        function onBlockVerticalScreensChanged() { root._warmDebounce.restart() }
    }

    property Connections _screensWatcher: Connections {
        target: Quickshell
        function onScreensChanged() { root._warmDebounce.restart() }
    }

    property FileView _hyprpaperConf: FileView {
        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        blockLoading: true
        printErrors: false
        watchChanges: true
        // The displays panel writes it once hyprpaper shows a new wallpaper
        onFileChanged: {
            reload()
            root._hyprpaperQuery.running = true
        }
        onLoaded: root._parseHyprpaperConf()
    }

    // Reads `source = ...` includes of hyprpaper.conf
    property FileView _includeReader: FileView {
        blockAllReads: true
        printErrors: false
    }

    function _expandPath(p) {
        return p.replace(/^~(?=\/|$)/, Quickshell.env("HOME") ?? "")
            .replace(/\$\{?([A-Za-z_][A-Za-z0-9_]*)\}?/g, (m, name) => Quickshell.env(name) ?? "")
    }

    function _confText() {
        let out = ""
        const lines = root._hyprpaperConf.text().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const src = lines[i].trim().match(/^source\s*=\s*(.+)$/)
            if (!src) {
                out += lines[i] + "\n"
                continue
            }
            root._includeReader.path = root._expandPath(src[1].trim())
            out += root._includeReader.text() + "\n"
        }
        return out
    }

    function _parseHyprpaperConf() {
        const map = {}
        let fallback = ""
        let inBlock = false
        let curMonitor = ""
        let curPath = ""

        function assign(monitor, path) {
            if (path.length === 0) return
            if (monitor.length > 0) map[monitor] = root._expandPath(path)
            else fallback = root._expandPath(path)
        }

        const lines = root._confText().split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (line.length === 0 || line.startsWith("#")) continue

            if (line.startsWith("wallpaper") && line.indexOf("{") >= 0) {
                inBlock = true
                curMonitor = ""
                curPath = ""
                continue
            }
            if (inBlock && line === "}") {
                assign(curMonitor, curPath)
                inBlock = false
                continue
            }

            const eq = line.indexOf("=")
            if (eq < 0) continue
            const key = line.slice(0, eq).trim()
            const val = line.slice(eq + 1).trim()

            if (inBlock) {
                if (key === "monitor") curMonitor = val
                else if (key === "path") curPath = val
            } else if (key === "wallpaper") {
                // Pre-0.8 syntax: wallpaper = MONITOR,PATH
                const comma = val.indexOf(",")
                if (comma >= 0) assign(val.slice(0, comma).trim(), val.slice(comma + 1).trim())
            }
        }

        root._confWallpapers = map
        root._confFallback = fallback
        root._warmBlurCache()
    }

    property Process _hyprpaperQuery: Process {
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            id: hyprpaperOut
            onStreamFinished: root._parseLiveWallpapers(hyprpaperOut.text)
        }
    }

    function _parseLiveWallpapers(text) {
        const map = {}
        const lines = (text || "").split("\n")
        for (let i = 0; i < lines.length; i++) {
            // "MONITOR: /path" (current hyprpaper) or "MONITOR = /path" (older)
            const m = lines[i].trim().match(/^([^\s=:]+)\s*[:=]\s*(\/.*)$/)
            if (m) map[m[1]] = m[2].trim()
        }
        // Not running yet (boot) or nothing active: keep using the conf
        if (Object.keys(map).length === 0) return
        if (JSON.stringify(map) === JSON.stringify(root._liveWallpapers)) return
        root._liveWallpapers = map
        root._warmBlurCache()
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

    // Mic is muted while locked; only restored on unlock if we were
    // the ones who muted it (a mic muted before locking stays muted).
    property bool _micMutedByLock: false

    property PwObjectTracker _micTracker: PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    // Re-mute whenever the mic comes back unmuted while locked: covers
    // the startup lock (Pipewire not bound yet, and the node's initial
    // param sync overwrites a mute written right as it becomes ready)
    // and a source that appears or changes while locked.
    property bool _micReady: Pipewire.defaultAudioSource?.ready ?? false
    on_MicReadyChanged: root._muteMic()

    property Connections _micWatcher: Connections {
        target: Pipewire.defaultAudioSource?.audio ?? null
        function onMutedChanged() {
            root._muteMic()
        }
    }

    function _muteMic() {
        const audio = Pipewire.defaultAudioSource?.audio
        if (!root.isLocked || !SettingsData.s.lockScreen.muteMicOnLock
                || !root._micReady || !audio || audio.muted) return
        audio.muted = true
        root._micMutedByLock = true
    }

    function _restoreMic() {
        if (!root._micMutedByLock) return
        root._micMutedByLock = false
        const audio = Pipewire.defaultAudioSource?.audio
        if (audio) audio.muted = false
    }

    // At boot hyprpaper is started here, once the lock covers every screen,
    // not by Hyprland: started alongside the shell, it showed the wallpapers
    // for as long as the shell took to load
    property bool _wallpaperPending: false

    function _startWallpaper(confirmed) {
        if (!root._wallpaperPending) return
        root._wallpaperPending = false
        _wallpaperFallback.stop()
        console.log(confirmed ? "[lock] boot lock covers the screens, starting hyprpaper"
            : "[lock] boot lock not confirmed in 10 s, starting hyprpaper anyway")
        Quickshell.execDetached(["sh", "-c", "pgrep -x hyprpaper >/dev/null || exec hyprpaper"])
    }

    // Should the lock never be confirmed
    property Timer _wallpaperFallback: Timer {
        interval: 10000
        onTriggered: root._startWallpaper(false)
    }

    function lockAtBoot() {
        root._wallpaperPending = true
        _wallpaperFallback.restart()
        root.lock()
    }

    function lock() {
        if (root.isLocked || _wlLock.locked) return
        root._init()
        root.isLocked = true
        root._muteMic()

        // Picks up wallpapers changed at runtime (hyprctl hyprpaper ...);
        // the surfaces show the known blur meanwhile and swap if it differs
        if (SettingsData.s.lockScreen.enableBlur) {
            _hyprpaperQuery.running = true
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
        root._restoreMic()

        Qt.callLater(root._focusFirstHorizontalMonitor)

        root.lockedChanged()
    }

    property LockContext _ctx: LockContext {
        id: lockCtx
        active: root.isLocked
        onUnlocked: root._unlock()
        onUnlockedWithPassword: (pw) => {
            if (root._keyringUnlock.running) return
            root._keyringUnlock.password = pw
            root._keyringUnlock.running = true
        }
    }

    // The password goes through stdin: on a command line any local user
    // could read it, and a shell would mangle quotes, $ or backticks
    property Process _keyringUnlock: Process {
        property string password: ""

        command: ["gnome-keyring-daemon", "--replace", "--unlock", "--components=secrets"]
        stdinEnabled: true

        onStarted: {
            write(password)
            password = ""
            stdinEnabled = false // EOF: the daemon reads up to it
        }
        onExited: stdinEnabled = true
    }

    property WlSessionLock _wlLock: WlSessionLock {
        id: _wlLock
        locked: false

        // Hyprland has confirmed every screen shows a lock surface
        onSecureChanged: if (secure) root._startWallpaper(true)

        onLockedChanged: {
            if (!locked && root.isLocked) {
                // Compositor tore down the lock out from under us
                // (e.g. another lock client grabbed it, or a race
                // with unlock). Keep our flag in sync so lock()
                // stays callable and doesn't re-enter while stale.
                root.isLocked = false
                root._restoreMic()
                root.lockedChanged()
            }
        }

        WlSessionLockSurface {
            id: lockSurfaceRoot
            color: "transparent"

            readonly property bool isVertical: screen ? screen.height > screen.width : false
            readonly property bool blockThisScreen: SettingsData.s.lockScreen.blockVerticalScreens && isVertical

            Rectangle {
                id: blockedCover
                anchors.fill: parent
                visible: lockSurfaceRoot.blockThisScreen
                color: "black"

                // Typing still works if this screen holds keyboard focus
                focus: visible
                Keys.onPressed: (event) => lockCtx.handleKey(event)

                MouseArea {
                    anchors.fill: parent
                    onClicked: blockedCover.forceActiveFocus()
                }
            }

            // Blocked screens get no lock surface at all (it used to be
            // created hidden: image load, timers, battery polling)
            Loader {
                anchors.fill: parent
                active: !lockSurfaceRoot.blockThisScreen
                focus: active

                sourceComponent: LockSurface {
                    context: lockCtx
                    enableBlur: SettingsData.s.lockScreen.enableBlur
                    blurSize: SettingsData.s.lockScreen.blurSize
                    blurPasses: SettingsData.s.lockScreen.blurPasses
                    brightness: SettingsData.s.lockScreen.brightness
                    blurCache: root._blurCache
                    wallpaperPath: root.wallpaperFor(lockSurfaceRoot.screen ? lockSurfaceRoot.screen.name : "")
                }
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