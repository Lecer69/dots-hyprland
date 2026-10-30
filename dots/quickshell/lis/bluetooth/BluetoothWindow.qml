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

    BluetoothPanel {
        id: bluetoothPanel

        anchors.centerIn: parent
        width: 460
        height: Math.min(bluetoothPanel.implicitHeight, parent.height - 80)
        shown: root.shown
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "bluetooth"

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
        name: "bluetooth"
        description: "Toggles the Bluetooth panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}
