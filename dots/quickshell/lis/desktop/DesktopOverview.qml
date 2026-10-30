pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.tools

// Day and system overview on an empty workspace; double-click the desktop to open it
Scope {
    id: root

    property bool locked: false

    signal todoRequested()
    signal calendarRequested()

    function _focused(): var {
        const name = Hyprland.focusedMonitor?.name;
        return screens.instances.find(w => w.modelData.name === name) ?? null;
    }

    function setOpen(open: bool): void {
        const w = root._focused();
        if (w)
            w.open = open && w.empty;
    }

    SystemStats {
        id: systemStats

        running: !root.locked && screens.instances.some(w => w.open)
    }

    Variants {
        id: screens

        model: Quickshell.screens

        delegate: PanelWindow {
            id: win

            required property ShellScreen modelData

            readonly property HyprlandWorkspace workspace: Hyprland.monitorFor(modelData)?.activeWorkspace ?? null
            readonly property bool empty: win.workspace !== null
                && !HyprlandData.windowList.some(w => w.workspace?.id === win.workspace.id)
            property bool open: false
            // Stays loaded until it has faded out
            property bool loaded: false
            // Briefly exclusive on opening: Hyprland only focuses a mapped layer that turns exclusive
            property bool grabbing: false

            onOpenChanged: {
                if (win.open) {
                    unload.stop();
                    win.loaded = true;
                    win.grabbing = true;
                    release.restart();
                } else {
                    win.grabbing = false;
                    unload.restart();
                }
            }
            onWorkspaceChanged: win.open = false
            onEmptyChanged: if (!win.empty) win.open = false

            screen: modelData
            // Only on an empty workspace
            visible: empty
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.namespace: "quickshell:desktop"
            WlrLayershell.keyboardFocus: !win.open ? WlrKeyboardFocus.None
                : win.grabbing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onDoubleClicked: win.open = !win.open
            }

            Shortcut {
                sequences: ["Escape"]
                enabled: win.open
                onActivated: win.open = false
            }

            Timer {
                id: release

                interval: 150
                onTriggered: win.grabbing = false
            }

            Timer {
                id: unload

                // DesktopPanel fades out in 200 ms
                interval: 250
                onTriggered: win.loaded = false
            }

            Loader {
                anchors.fill: parent
                active: win.loaded

                sourceComponent: DesktopPanel {
                    stats: systemStats
                    shown: win.open
                    reserved: HyprlandData.monitors.find(m => m.name === win.modelData.name)?.reserved ?? [0, 0, 0, 0]
                    onTodoRequested: root.todoRequested()
                    onCalendarRequested: root.calendarRequested()
                }
            }
        }
    }

    IpcHandler {
        target: "desktop"

        function toggle(): void {
            root.setOpen(!(root._focused()?.open ?? true));
        }

        function open(): void {
            root.setOpen(true);
        }

        function close(): void {
            root.setOpen(false);
        }
    }

    GlobalShortcut {
        name: "desktop"
        description: "Toggles the overview on an empty workspace"
        onPressed: root.setOpen(!(root._focused()?.open ?? true))
    }
}
