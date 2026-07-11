pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Pam
import QtQuick

QtObject {
    id: root

    signal unlocked()
    signal unlockedWithPassword(string password)
    signal authFailed()

    property bool authenticating: false
    property string password: ""
    property bool capsLockOn: false

    property string _submitted: ""

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
}
