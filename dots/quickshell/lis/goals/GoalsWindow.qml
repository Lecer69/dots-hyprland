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

    // A title being typed is saved now, not after the pause
    onShownChanged: if (!shown) GoalsService.flush()

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.shown = false
    }

    GoalsPanel {
        anchors.centerIn: parent
        width: Math.min(600, parent.width - 80)
        height: Math.min(640, parent.height - 80)
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "goals"

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
        name: "goals"
        description: "Toggles the goals panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}
