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

    MouseArea {
        anchors.fill: parent
        onClicked: root.shown = false
    }

    CalendarPanel {
        anchors.centerIn: parent
        width: 460
        height: 520
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