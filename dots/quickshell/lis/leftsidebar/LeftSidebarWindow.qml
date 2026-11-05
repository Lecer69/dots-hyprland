import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import qs.common

// Left-edge sidebar on the focused screen
Scope {
    id: root

    property var targetScreen: null
    property bool isOpen: false
    readonly property var screen: root.targetScreen ?? Quickshell.screens[0]

    signal todoRequested()

    function focusedScreen(): var {
        return Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null;
    }

    // Closes instead when already open on that screen
    function toggle(screen: var): void {
        if (root.isOpen && root.screen === screen) {
            root.isOpen = false;
            return;
        }
        root.targetScreen = screen;
        root.isOpen = true;
    }

    IpcHandler {
        target: "leftsidebar"

        function toggle(): void {
            root.toggle(root.focusedScreen());
        }

        function close(): void {
            root.isOpen = false;
        }
    }

    GlobalShortcut {
        name: "leftsidebar"
        description: "Toggles the left sidebar"
        onPressed: root.toggle(root.focusedScreen())
    }

    // Click-outside catcher, on the top layer so the sidebar stays above it
    PanelWindow {
        screen: root.screen
        visible: root.isOpen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:leftsidebarbackdrop"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Hyprland slides it (rules.lua); a QML slide runs at 60 fps on NVIDIA
    PanelWindow {
        screen: root.screen
        visible: root.isOpen
        color: "transparent"
        implicitWidth: 340
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: keyboard.mode
        WlrLayershell.namespace: "quickshell:leftsidebar"

        anchors {
            top: true
            bottom: true
            left: true
        }

        margins {
            top: 8
            bottom: 8
            left: 8
        }

        PanelKeyboard {
            id: keyboard

            open: root.isOpen
            initialFocus: panel.initialFocus
        }

        Shortcut {
            sequences: ["Escape"]
            onActivated: root.isOpen = false
        }

        LeftSidebarPanel {
            id: panel

            anchors.fill: parent
            shown: root.isOpen
            onCloseRequested: root.isOpen = false
            onTodoRequested: {
                root.isOpen = false;
                root.todoRequested();
            }
        }
    }
}
