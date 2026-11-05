import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

// A panel's window, keybind and IPC; the window and the panel are built on the first open
Scope {
    id: root

    // IPC target and global shortcut name
    required property string name
    required property string description
    // Its parent is the size of the screen
    default property Component panel
    property string namespace: "quickshell"
    // Out of the way of a file chooser, which can't rise above an overlay
    property bool hidden: false
    property bool closeOnClickOutside: false

    property bool shown: false
    // Turns true after the panel exists, so it sees its first open as a change too
    readonly property bool panelShown: root.shown && root._ready
    // The panel, once built
    property Item item: null

    // What the keybind, the IPC and Escape do
    property var toggle: () => {
        root.shown = !root.shown;
    }
    property var open: () => {
        root.shown = true;
    }
    property var close: () => {
        root.shown = false;
    }

    property bool _built: false
    property bool _ready: false

    onShownChanged: if (root.shown) root._built = true

    // For something that has to read the panel before it's first opened
    function build(): void {
        root._built = true;
    }

    // The next open builds it again
    function release(): void {
        if (root.shown)
            return;
        root._ready = false;
        root._built = false;
    }

    LazyLoader {
        active: root._built

        PanelWindow {
            visible: root.panelShown && !root.hidden
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: keyboard.mode
            WlrLayershell.exclusiveZone: -1
            WlrLayershell.namespace: root.namespace

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            PanelKeyboard {
                id: keyboard

                open: root.panelShown
                initialFocus: root.item?.initialFocus ?? null
            }

            Shortcut {
                sequences: ["Escape"]
                onActivated: root.close()
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.closeOnClickOutside
                onClicked: root.close()
            }

            Item {
                id: slot

                anchors.fill: parent

                Component.onCompleted: {
                    root.item = root.panel.createObject(slot);
                    root._ready = true;
                }
            }
        }
    }

    IpcHandler {
        target: root.name

        function toggle(): void {
            root.toggle();
        }

        function open(): void {
            root.open();
        }

        function close(): void {
            root.close();
        }
    }

    GlobalShortcut {
        name: root.name
        description: root.description
        onPressed: root.toggle()
    }
}
