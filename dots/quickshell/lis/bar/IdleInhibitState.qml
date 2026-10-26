pragma Singleton
import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.settings.data

// Blocks idle actions (lock, screen off, suspend) through the Wayland
// idle-inhibit protocol, which hypridle honors. hypridle itself keeps
// running, so its before_sleep_cmd still locks the screen on suspend.
// hypridle/HypridleService.qml starts it.
Singleton {
    id: root

    property bool idleInhibited: SettingsData.s.general.enableIdleInhibitedByDefault

    function toggle() {
        root.idleInhibited = !root.idleInhibited
    }

    // Hyprland only counts an inhibitor whose surface already shows when the
    // inhibitor is created (it rechecks on inhibitor changes only), so the
    // inhibitor is made a moment after its window shows, and again if the
    // window is shown anew
    property bool _surfaceReady: false

    IdleInhibitor {
        enabled: root.idleInhibited && root._surfaceReady
        // An inhibitor needs a surface: an empty one that takes no input
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
