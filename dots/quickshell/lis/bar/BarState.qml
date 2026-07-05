pragma Singleton
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

QtObject {
    id: root

    property bool barShown: true

    function toggle(): void {
        root.barShown = !root.barShown
    }

    function show(): void {
        root.barShown = true
    }

    function hide(): void {
        root.barShown = false
    }

    property IpcHandler ipc: IpcHandler {
        target: "overlayToggle"

        function toggle(): void {
            root.toggle()
        }

        function show(): void {
            root.show()
        }

        function hide(): void {
            root.hide()
        }
    }

    property GlobalShortcut shortcut: GlobalShortcut {
        name: "overlayToggle"
        description: "Toggles the widget bar overlay"
        onPressed: {
            root.toggle()
        }
    }
}
