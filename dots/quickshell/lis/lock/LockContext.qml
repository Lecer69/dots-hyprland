pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.Pam
import QtQuick

QtObject {
    id: root

    signal unlocked()
    signal unlockedWithPassword(string password)
    signal authFailed()

    // Set while the screen is locked
    property bool active: false

    property bool authenticating: false
    property string password: ""
    property bool capsLockOn: false

    // Shared by every lock surface (each screen used to spawn its own
    // processes and poll the layout every 5s)
    readonly property string userName: Quickshell.env("USER") || "user"
    property string keyboardLayout: "en"
    property string _mainKeyboard: ""

    property string _submitted: ""

    // One hyprctl call per lock for layout + caps lock; layout switches
    // while locked arrive as Hyprland events
    onActiveChanged: {
        if (active) _devicesProc.running = true
    }

    property Process _devicesProc: Process {
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            id: devicesOut
            onStreamFinished: {
                try {
                    const kbs = JSON.parse(devicesOut.text).keyboards ?? []
                    const kb = kbs.find(k => k.main) ?? kbs[0]
                    if (!kb) return
                    root._mainKeyboard = kb.name
                    root.keyboardLayout = kb.active_keymap || "en"
                    root.capsLockOn = kb.capsLock === true
                } catch (e) {
                    console.warn("[lock] failed to read keyboard state:", e)
                }
            }
        }
    }

    property Connections _layoutWatcher: Connections {
        target: Hyprland
        enabled: root.active

        function onRawEvent(event) {
            // activelayout>>KEYBOARD,LAYOUT
            if (event.name !== "activelayout") return
            const comma = event.data.indexOf(",")
            if (comma < 0) return
            if (root._mainKeyboard.length > 0 && event.data.slice(0, comma) !== root._mainKeyboard) return
            root.keyboardLayout = event.data.slice(comma + 1)
        }
    }

    property PamContext _pam: PamContext {
        config: "hyprlock"

        onPamMessage: {
            if (_pam.responseRequired && root._submitted.length > 0) {
                _pam.respond(root._submitted)
            }
        }

        onCompleted: (result) => {
            root.authenticating = false
            if (result === PamResult.Success) {
                root.unlockedWithPassword(root._submitted)
                root.unlocked()
            } else {
                root.authFailed()
            }
            root._submitted = ""
            root.password = ""
        }
    }

    property Timer _watchdog: Timer {
        interval: 10000
        repeat: false
        onTriggered: {
            if (root.authenticating) {
                root._pam.abort()
                root.authenticating = false
                root._submitted = ""
                root.password = ""
                root.authFailed()
            }
        }
    }

    function submit() {
        if (root.authenticating || root.password.length === 0) return
        root._submitted = root.password
        root.authenticating = true
        _watchdog.restart()
        _pam.start()
    }

    function appendChar(ch) {
        if (!root.authenticating)
            root.password += ch
    }

    function backspace() {
        if (!root.authenticating && root.password.length > 0)
            root.password = root.password.slice(0, -1)
    }

    function clearPassword() {
        root.password = ""
    }

    function selectAllClear() {
        if (!root.authenticating)
            root.password = ""
    }

    // Password entry, shared by every screen (including blocked ones)
    function handleKey(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.submit()
            event.accepted = true
        } else if (event.key === Qt.Key_Backspace) {
            root.backspace()
            event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
            root.clearPassword()
            event.accepted = true
        } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
            root.selectAllClear()
            event.accepted = true
        } else if (event.key === Qt.Key_CapsLock) {
            root.capsLockOn = !root.capsLockOn
            event.accepted = false
        } else if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
            event.accepted = true
        } else if (event.text.length > 0 && !event.isAutoRepeat) {
            root.appendChar(event.text)
            event.accepted = true
        }
    }
}
