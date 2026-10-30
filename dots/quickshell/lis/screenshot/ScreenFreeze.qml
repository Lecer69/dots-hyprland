pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Freezes the screens with grim's capture while a region is picked (hyprpicker draws rotated monitors sideways)
Scope {
    id: root

    // "" while nothing is frozen
    property string path: ""
    // If the script dies, the freeze ends
    property int owner: 0

    // grim captures every screen at their highest scale
    readonly property real left: Math.min(...Quickshell.screens.map(s => s.x))
    readonly property real top: Math.min(...Quickshell.screens.map(s => s.y))
    readonly property real scale: Math.max(...Quickshell.screens.map(s => s.devicePixelRatio))

    IpcHandler {
        target: "screenshot"

        function freeze(path: string, pid: int): void {
            root.owner = pid
            root.path = path
            watchdog.running = pid > 0
        }

        function unfreeze(): void {
            root.path = ""
            watchdog.running = false
        }
    }

    // Exits once the script does
    Process {
        id: watchdog

        command: ["tail", "--pid=" + root.owner, "-s", "0.1", "-f", "/dev/null"]
        onExited: root.path = ""
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: window

            required property ShellScreen modelData

            screen: modelData
            visible: root.path !== ""
            color: "black"
            WlrLayershell.layer: WlrLayer.Overlay
            // Shown at once: Hyprland's pop-in would show the live screen
            WlrLayershell.namespace: "quickshell:freeze"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Image {
                anchors.fill: parent
                source: root.path === "" ? "" : "file://" + root.path
                sourceClipRect: Qt.rect((window.modelData.x - root.left) * root.scale, (window.modelData.y - root.top) * root.scale,
                    window.modelData.width * root.scale, window.modelData.height * root.scale)
                cache: false
            }
        }
    }
}
