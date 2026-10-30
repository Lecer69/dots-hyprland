import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

PanelWindow {
    id: root

    property bool shown: false

    visible: shown
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keyboard.mode
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    PanelKeyboard {
        id: keyboard
        open: root.shown
        initialFocus: panel.initialFocus
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.shown = false
    }

    TodoPanel {
        id: panel
        anchors.centerIn: parent
        width: Math.min(980, parent.width - 160)
        height: Math.min(680, parent.height - 120)
        shown: root.shown
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "todo"

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
        name: "todo"
        description: "Toggles the to-do list panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}
