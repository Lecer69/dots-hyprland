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

    TaskManagerPanel {
        id: taskManagerPanel

        anchors.centerIn: parent
        width: 640
        height: Math.min(730, parent.height - 80)
        shown: root.shown
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "taskmanager"

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
        name: "taskmanager"
        description: "Toggles the task manager"
        onPressed: {
            root.shown = !root.shown
        }
    }
}
