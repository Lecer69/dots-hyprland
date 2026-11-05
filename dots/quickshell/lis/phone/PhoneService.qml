pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings.data

// lis-daemon (the Lis App project), running while Phone Sync is on; it outlives hot reloads
Singleton {
    id: root

    readonly property string daemonPath: Quickshell.env("HOME") + "/.local/bin/lis-daemon"
    readonly property bool enabled: SettingsData.s.phone?.enabled ?? false
    readonly property bool running: socket.connected
    property bool installed: true

    property var status: null
    readonly property var phones: root.status?.phones ?? []
    // The connected one first
    readonly property var phone: root.phones.find(p => p.connected) ?? root.phones[0] ?? null
    readonly property bool connected: root.phone?.connected === true
    readonly property var stats: root.phone?.stats ?? null
    // { camera, width, height, fps, measured_fps, mbps, viewers }, null when it's off
    readonly property var camera: root.status?.camera ?? null
    readonly property var pairCode: root.status?.pair_code ?? null
    readonly property bool pairing: root.status?.pairing === true
    property string pairMessage: ""

    property string transfer: ""

    property var _callbacks: ({})
    property int _nextId: 1
    property int _attempts: 0

    onEnabledChanged: {
        root._attempts = 0;
        if (root.enabled) {
            installCheck.running = true;
        } else if (socket.connected) {
            root.request({ cmd: "quit" });
            root.status = null;
        }
    }

    Component.onCompleted: {
        if (root.enabled)
            installCheck.running = true;
    }

    function request(command: var, callback: var): void {
        if (!socket.connected)
            return;

        const id = root._nextId++;
        if (callback)
            root._callbacks[id] = callback;
        socket.write(JSON.stringify(Object.assign({ id: id }, command)) + "\n");
        socket.flush();
    }

    function refresh(): void {
        root.request({ cmd: "status" }, reply => {
            if (reply.ok)
                root.status = reply.result;
        });
    }

    function openPairing(): void {
        root.pairMessage = "";
        root.request({ cmd: "pair_open" });
    }

    function closePairing(): void {
        root.request({ cmd: "pair_close" });
    }

    function answerCode(accept: bool): void {
        root.request({ cmd: "pair_confirm", accept: accept });
    }

    function unpair(fingerprint: string): void {
        root.request({ cmd: "unpair", fingerprint: fingerprint });
    }

    function sendFile(path: string): void {
        const name = path.substring(path.lastIndexOf("/") + 1);
        root.transfer = "Sending " + name;
        root.request({ cmd: "send_file", path: path }, reply => {
            if (!reply.ok)
                root.transfer = reply.error;
        });
    }

    function _onLine(line: string): void {
        let message;
        try {
            message = JSON.parse(line);
        } catch (e) {
            console.warn("[phone] unreadable line from the daemon");
            return;
        }

        if (message.id !== undefined) {
            const callback = root._callbacks[message.id];
            delete root._callbacks[message.id];
            if (callback)
                callback(message);
            return;
        }

        switch (message.event) {
        case "status":
            root.status = message.status;
            break;
        case "pair_result":
            root.pairMessage = message.ok ? "" : message.reason;
            root.refresh();
            break;
        case "file_progress":
            root.transfer = message.name + ": " + Math.round(message.done * 100 / Math.max(1, message.total)) + "%";
            break;
        case "file_finished":
            root.transfer = message.ok ? (message.incoming ? "Saved " : "Sent ") + message.name : "Couldn't transfer " + message.name;
            break;
        }
    }

    Socket {
        id: socket

        path: Quickshell.env("XDG_RUNTIME_DIR") + "/lis-app.sock"

        parser: SplitParser {
            onRead: data => root._onLine(data)
        }

        onConnectedChanged: {
            if (connected) {
                root._attempts = 0;
                root.refresh();
            } else {
                root.status = null;
                root._callbacks = {};
            }
        }
    }

    // Tries the socket first, as the daemon may already be running from before a reload
    Timer {
        interval: 1000
        repeat: true
        running: root.enabled && root.installed && !socket.connected
        triggeredOnStart: true
        onTriggered: {
            socket.connected = true;
            if (root._attempts % 5 === 1)
                Quickshell.execDetached([root.daemonPath]);
            root._attempts++;
        }
    }

    // The daemon only reports pairing closing when something else changes
    Timer {
        interval: 5000
        repeat: true
        running: root.pairing
        onTriggered: root.refresh()
    }

    // Notices the daemon being installed while Phone Sync is on
    Timer {
        interval: 5000
        repeat: true
        running: root.enabled && !root.installed
        onTriggered: installCheck.running = true
    }

    Process {
        id: installCheck

        command: ["test", "-x", root.daemonPath]
        onExited: code => root.installed = code === 0
    }
}
