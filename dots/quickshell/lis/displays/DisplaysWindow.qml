import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool shown: false

    // Hidden while the file chooser is open
    visible: shown && !displaysPanel.picking
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

    // Stays open while the new settings wait to be kept
    Shortcut {
        sequences: ["Escape"]
        onActivated: if (!displaysPanel.confirming) root.shown = false
    }

    DisplaysPanel {
        id: displaysPanel

        anchors.centerIn: parent
        width: 736
        height: Math.min(displaysPanel.implicitHeight, parent.height - 80)
        shown: root.shown
        onCloseRequested: if (!displaysPanel.confirming) root.shown = false
    }

    // While picking, opening it again closes the chooser
    function toggle(): void {
        if (displaysPanel.picking) displaysPanel.cancelPick()
        else if (!displaysPanel.confirming) root.shown = !root.shown
    }

    IpcHandler {
        target: "displays"

        function toggle(): void {
            root.toggle()
        }

        function open(): void {
            displaysPanel.cancelPick()
            root.shown = true
        }

        function close(): void {
            displaysPanel.cancelPick()
            if (!displaysPanel.confirming) root.shown = false
        }
    }

    GlobalShortcut {
        name: "displays"
        description: "Toggles the display settings"
        onPressed: root.toggle()
    }
}
