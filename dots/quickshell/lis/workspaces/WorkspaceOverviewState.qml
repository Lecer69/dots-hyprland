pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Singleton {
    id: root

    property bool overviewOpen: false

    IpcHandler {
        target: "workspaces"

        function toggle(): void {
            root.overviewOpen = !root.overviewOpen
        }

        function open(): void {
            root.overviewOpen = true
        }

        function close(): void {
            root.overviewOpen = false
        }
    }

    GlobalShortcut {
        name: "workspaces"
        description: "Toggle the workspaces overview"
        onPressed: {
            root.overviewOpen = !root.overviewOpen
        }
    }
}