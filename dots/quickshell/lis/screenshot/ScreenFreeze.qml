pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Holds the screens still while a region is picked for a screenshot
// (~/.config/hypr/hyprland/scripts/screenshot-region.sh): grim's capture of
// every screen, shown over each screen. hyprpicker's freeze, which hyprshot
// uses, draws rotated monitors sideways.
Scope {
    id: root

    // The capture, "" while nothing is frozen
    property string path: ""
    // The script that froze the screens: if it dies, the freeze ends too
    property int owner: 0

    // grim captures the area of every screen, at the highest scale of them
    readonly property real left: Math.min(...Quickshell.screens.map(s => s.x))
    readonly property real top: Math.min(...Quickshell.screens.map(s => s.y))
    readonly property real scale: Math.max(...Quickshell.screens.map(s => s.devicePixelRatio))

    IpcHandler {
        target: "screenshot"

        // path: grim's capture; pid: the script's
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

    // Exits once the script does, checking every 0.1s
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
            // under it
            WlrLayershell.namespace: "quickshell:freeze"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            WlrLayershell.exclusiveZone: -1

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            // This screen's part of the capture
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
