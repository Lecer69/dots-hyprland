pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    function isMonitorVertical(m) {
        return (m?.height ?? 0) > (m?.width ?? 0)
    }

    function isMonitorHorizontal(m) {
        return (m?.width ?? 0) >= (m?.height ?? 0)
    }
}