pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import qs.settings.data

Singleton {
    id: root

    property bool idleInhibited: SettingsData.s.general.enableIdleInhibitedByDefault

    Process {
        id: hypridleStart
        command: ["hypridle"]
    }

    Process {
        id: hypridleStop
        command: ["sh", "-c", "pkill -KILL hypridle"]
    }

    Timer {
        id: initTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (root.idleInhibited) {
                hypridleStop.running = true
            } else {
                Quickshell.execDetached(["sh", "-c", "pkill hypridle; hypridle"])
            }
        }
    }

    Component.onCompleted: initTimer.start()

    function toggle() {
        if (idleInhibited) {
            hypridleStart.running = true
            idleInhibited = false
        } else {
            hypridleStop.running = true
            idleInhibited = true
        }
    }
}
