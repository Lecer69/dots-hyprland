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

    MouseArea {
        anchors.fill: parent
        onClicked: root.shown = false
    }

    CalendarPanel {
        id: panel
        anchors.centerIn: parent
        width: 460
        height: 720
        onCloseRequested: root.shown = false
    }

    IpcHandler {
        target: "calendar"

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
        name: "calendar"
        description: "Toggles the calendar panel"
        onPressed: {
            root.shown = !root.shown
        }
    }
}