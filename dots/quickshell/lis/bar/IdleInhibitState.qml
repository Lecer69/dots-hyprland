pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.settings.data

// Blocks idle actions via idle-inhibit; hypridle keeps running, so suspend still locks
Singleton {
    id: root

    property bool idleInhibited: SettingsData.s.general.enableIdleInhibitedByDefault

    function toggle() {
        root.idleInhibited = !root.idleInhibited
    }

    // Hyprland only counts an inhibitor whose surface already shows, so it's made after the window
    property bool _surfaceReady: false

    IdleInhibitor {
        enabled: root.idleInhibited && root._surfaceReady
        // An inhibitor needs a surface
        window: PanelWindow {
            id: inhibitorWindow
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            anchors {
                right: true
                bottom: true
            }
            mask: Region {}

            onBackingWindowVisibleChanged: {
                root._surfaceReady = false
                if (backingWindowVisible) surfaceTimer.restart()
            }
        }
    }

    Timer {
        id: surfaceTimer
        interval: 1000
        running: true
        onTriggered: root._surfaceReady = inhibitorWindow.backingWindowVisible
    }
}
