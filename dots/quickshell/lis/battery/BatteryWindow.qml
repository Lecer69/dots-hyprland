import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool shown: false

    visible: shown
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.shown = false
    }

    BatteryPanel {
        id: batteryPanel
        anchors.centerIn: parent
        width: 460
        height: contentHeight
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "battery"

        function toggle(): void {
            root.shown = !root.shown
        }

        function open(): void {
            root.shown = true
        }

        function close(): void {
            root.shown = false
        }
    }

    GlobalShortcut {
        name: "battery"
        description: "Toggles the battery panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}