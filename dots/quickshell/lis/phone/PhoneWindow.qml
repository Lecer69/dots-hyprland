import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

PanelWindow {
    id: root

    property bool shown: false

    signal settingsRequested()

    // Out of the way of the file chooser, which can't rise above an overlay
    visible: shown && !panel.picking
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
        open: root.visible
        initialFocus: panel.initialFocus
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.shown = false
    }

    PhonePanel {
        id: panel
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 80)
        height: panel.wantedHeight
        shown: root.shown
        onCloseRequested: root.shown = false
        onSettingsRequested: {
            root.shown = false
            root.settingsRequested()
        }
    }

    IpcHandler {
        target: "phone"

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
        name: "phone"
        description: "Toggles the phone panel"
        onPressed: root.shown = !root.shown
    }
}
