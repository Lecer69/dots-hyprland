import Quickshell
import Quickshell.Hyprland
import qs.tools

Scope {
    id: root

    property bool isOpen: false
    property string initialQuery: ""

    function open(query) {
        initialQuery = query ?? ""
        isOpen = true
    }

    function close() {
        isOpen = false
        initialQuery = ""
    }

    function toggle() {
        if (isOpen) close()
        else open("")
    }

    function hasFullscreenOnActiveWorkspace() {
        const wsId = HyprlandData.activeWorkspace?.id
        if (wsId === undefined || wsId === null) return false

        return HyprlandData.windowList.some(w => w.workspace.id === wsId && w.fullscreen > 0)
    }

    GlobalShortcut {
        name: "launcherToggle"
        description: "Toggle launcher"
        onPressed: root.toggle()
    }

    GlobalShortcut {
        name: "launcherClipboard"
        description: "Open launcher with clipboard history"
        onPressed: {
            if (root.isOpen && root.initialQuery === ":") root.close()
            else root.open(":")
        }
    }

    GlobalShortcut {
        name: "launcherEmojis"
        description: "Open launcher with emoji search"
        onPressed: {
            if (root.isOpen && root.initialQuery === ";") root.close()
            else root.open(";")
        }
    }

    LauncherWindow {
        isOpen: root.isOpen
        initialQuery: root.initialQuery
        onCloseRequested: root.close()
    }
}
