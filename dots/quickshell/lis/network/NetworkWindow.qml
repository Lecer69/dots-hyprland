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
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.shown = false
    }

    NetworkPanel {
        id: networkPanel

        anchors.centerIn: parent
        width: 460
        height: Math.min(networkPanel.implicitHeight, parent.height - 80)
        shown: root.shown
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "network"

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
        name: "network"
        description: "Toggles the network panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}
