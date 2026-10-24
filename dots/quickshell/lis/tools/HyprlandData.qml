// this utility class is from end-4
pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Singleton {
    id: root

    property var windowList: []
    property var addresses: []
    property var windowByAddress: ({})
    property var workspaces: []
    property var workspaceIds: []
    property var workspaceById: ({})
    property var activeWorkspace: null
    property var monitors: []
    property var layers: ({})

    // Checked synchronously (tiny file read) so dispatches made during
    // startup, like the boot lock focusing a monitor, use the right syntax
    property bool isLuaConfig: false

    FileView {
        id: luaConfig
        path: Quickshell.env("HOME") + "/.config/hypr/hyprland.lua"
        blockLoading: true
        printErrors: false
        Component.onCompleted: {
            text()
            root.isLuaConfig = loaded
        }
    }

    function toplevelsForWorkspace(workspace) {
        return ToplevelManager.toplevels.values.filter(toplevel => {
            const address = `0x${toplevel.HyprlandToplevel?.address}`;
            var win = HyprlandData.windowByAddress[address];
            return win?.workspace?.id === workspace;
        })
    }

    function hyprlandClientsForWorkspace(workspace) {
        return root.windowList.filter(win => win.workspace.id === workspace);
    }

    function clientForToplevel(toplevel) {
        if (!toplevel || !toplevel.HyprlandToplevel) {
            return null;
        }
        const address = `0x${toplevel?.HyprlandToplevel?.address}`;
        return root.windowByAddress[address];
    }

    function updateWindowList() {
        getClients.running = true;
    }

    function updateLayers() {
        getLayers.running = true;
    }

    function updateMonitors() {
        getMonitors.running = true;
    }

    function updateWorkspaces() {
        getWorkspaces.running = true;
        getActiveWorkspace.running = true;
    }

    function updateAll() {
        updateWindowList();
        updateMonitors();
        updateLayers();
        updateWorkspaces();
    }

    function biggestWindowForWorkspace(workspaceId) {
        const windowsInThisWorkspace = HyprlandData.windowList.filter(w => w.workspace.id == workspaceId);
        return windowsInThisWorkspace.reduce((maxWin, win) => {
            const maxArea = (maxWin?.size?.[0] ?? 0) * (maxWin?.size?.[1] ?? 0);
            const winArea = (win?.size?.[0] ?? 0) * (win?.size?.[1] ?? 0);
            return winArea > maxArea ? win : maxWin;
        }, null);
    }


    Component.onCompleted: {
        updateAll();
    }

    function dispatchWorkspace(index) {
        if (HyprlandData.isLuaConfig)
            Hyprland.dispatch('hl.dsp.focus({ workspace = "' + index + '" })')
        else
            Hyprland.dispatch("workspace " + index)
    }

    function dispatchFocusMonitor(monitor) {
        if (root.isLuaConfig)
            Hyprland.dispatch('hl.dsp.focus({ monitor = "' + monitor + '" })')
        else
            Hyprland.dispatch("focusmonitor " + monitor)
    }

    function dispatchMoveWorkspaceToMonitor(workspace, monitor) {
        if (root.isLuaConfig)
            Hyprland.dispatch('hl.dsp.workspace.move_to_monitor({ workspace = "' + workspace + '", monitor = "' + monitor + '" })')
        else
            Hyprland.dispatch("moveworkspacetomonitor " + workspace + " " + monitor)
    }

    readonly property int _refreshWindows: 1
    readonly property int _refreshWorkspaces: 2
    readonly property int _refreshMonitors: 4

    property int _pendingRefreshMask: 0

    function _requestRefresh(mask) {
        root._pendingRefreshMask |= mask;
        refreshCoalescer.restart();
    }

    Timer {
        id: refreshCoalescer
        interval: 120
        running: false
        onTriggered: {
            if (root._pendingRefreshMask & root._refreshWindows) {
                getClients.running = true;
                getActiveWorkspace.running = true;
            }
            if (root._pendingRefreshMask & root._refreshWorkspaces) {
                getWorkspaces.running = true;
                getActiveWorkspace.running = true;
            }
            if (root._pendingRefreshMask & root._refreshMonitors) {
                getMonitors.running = true;
            }
            root._pendingRefreshMask = 0;
        }
    }

    // Per-group event names (Hyprland socket2). Deliberately excludes
    // continuous events like tick / mouse* / *moveloop / screencast, and
    // title changes, which are applied from the event itself.
    readonly property var _windowEvents: new Set([
        "openwindow", "closewindow", "movewindow", "movewindowv2", "movewindowortho",
        "changefloatingmode", "fullscreen", "pin", "alterzorder", "activespecial",
        "activewindow", "activewindowv2",
        "moveintogroup", "moveoutofgroup", "movewindowgroupid"
    ])
    readonly property var _workspaceEvents: new Set([
        "workspace", "workspacev2", "createworkspace", "createworkspacev2",
        "destroyworkspace", "destroyworkspacev2", "moveworkspace", "moveworkspacev2",
        "focusedmon", "focusedmonv2"
    ])
    readonly property var _monitorEvents: new Set([
        "monitoradded", "monitoraddedv2", "monitorremoved", "configreloaded"
    ])

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            const name = event.name;
            if (name === "windowtitlev2")
                root._setTitle(event.data);
            else if (root._windowEvents.has(name))
                root._requestRefresh(root._refreshWindows);
            else if (root._workspaceEvents.has(name))
                root._requestRefresh(root._refreshWorkspaces);
            else if (root._monitorEvents.has(name))
                root._requestRefresh(root._refreshMonitors);
        }
    }

    // windowtitlev2>>ADDRESS,TITLE (address without 0x). Titles can change
    // many times a second (terminals, players), too often for hyprctl.
    function _setTitle(data) {
        const comma = data.indexOf(",");
        if (comma < 0) return;
        const address = "0x" + data.slice(0, comma);
        const win = root.windowByAddress[address];
        const title = data.slice(comma + 1);
        if (!win || win.title === title) return;

        const updated = Object.assign({}, win, { title: title });
        root.windowList = root.windowList.map(w => w.address === address ? updated : w);
        const byAddress = Object.assign({}, root.windowByAddress);
        byAddress[address] = updated;
        root.windowByAddress = byAddress;
    }

    // hyprctl prints an error instead of JSON when it can't reach Hyprland
    // (e.g. mid-reload); the last good data is kept then
    function _parse(text, what) {
        try {
            return JSON.parse(text);
        } catch (e) {
            console.warn("[HyprlandData] unreadable hyprctl " + what + " output:", e);
            return null;
        }
    }

    Process {
        id: getClients
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            id: clientsCollector
            onStreamFinished: {
                const list = root._parse(clientsCollector.text, "clients");
                if (!Array.isArray(list)) return;
                root.windowList = list;
                let tempWinByAddress = {};
                for (var i = 0; i < root.windowList.length; ++i) {
                    var win = root.windowList[i];
                    tempWinByAddress[win.address] = win;
                }
                root.windowByAddress = tempWinByAddress;
                root.addresses = root.windowList.map(win => win.address);
            }
        }
    }

    Process {
        id: getMonitors
        command: ["hyprctl", "monitors", "-j"]
        stdout: StdioCollector {
            id: monitorsCollector
            onStreamFinished: {
                const list = root._parse(monitorsCollector.text, "monitors");
                if (Array.isArray(list)) root.monitors = list;
            }
        }
    }

    Process {
        id: getLayers
        command: ["hyprctl", "layers", "-j"]
        stdout: StdioCollector {
            id: layersCollector
            onStreamFinished: {
                const layers = root._parse(layersCollector.text, "layers");
                if (layers) root.layers = layers;
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["hyprctl", "workspaces", "-j"]
        stdout: StdioCollector {
            id: workspacesCollector
            onStreamFinished: {
                const list = root._parse(workspacesCollector.text, "workspaces");
                if (!Array.isArray(list)) return;
                root.workspaces = list;
                let tempWorkspaceById = {};
                for (var i = 0; i < root.workspaces.length; ++i) {
                    var ws = root.workspaces[i];
                    tempWorkspaceById[ws.id] = ws;
                }
                root.workspaceById = tempWorkspaceById;
                root.workspaceIds = root.workspaces.map(ws => ws.id);
            }
        }
    }

    Process {
        id: getActiveWorkspace
        command: ["hyprctl", "activeworkspace", "-j"]
        stdout: StdioCollector {
            id: activeWorkspaceCollector
            onStreamFinished: {
                const ws = root._parse(activeWorkspaceCollector.text, "activeworkspace");
                if (ws) root.activeWorkspace = ws;
            }
        }
    }
}
