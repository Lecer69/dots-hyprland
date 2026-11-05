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

    readonly property bool usb: SettingsData.s.phone?.usb ?? false
    readonly property bool usbForwarding: root.status?.usb?.forwarding === true
    readonly property bool ringing: root.phone?.ringing === true
    // { id, name, command }; a phone only ever gets the names
    readonly property var actions: root.status?.actions ?? []
    property string actionError: ""
    // A connected phone that may unlock this PC
    readonly property bool canUnlock: root.phones.some(p => p.connected && p.unlock === "on")

    // Only after the daemon checked a signature from the phone's hardware key
    signal unlockGranted(string by)

    property bool _locked: false
    property bool _passwordRequired: true

    property var _callbacks: ({})
    property int _nextId: 1
    property int _attempts: 0

    onUsbChanged: root._sendUsb()

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

    function ring(on: bool): void {
        root.request({ cmd: "ring_phone", ring: on });
    }

    function setActions(actions: var): void {
        root.actionError = "";
        root.request({ cmd: "actions_set", actions: actions }, reply => {
            if (!reply.ok)
                root.actionError = reply.error;
        });
    }

    function answerUnlock(fingerprint: string, accept: bool): void {
        root.request({ cmd: "unlock_answer", fingerprint: fingerprint, accept: accept });
    }

    function disableUnlock(fingerprint: string): void {
        root.request({ cmd: "unlock_disable", fingerprint: fingerprint });
    }

    // The daemon only offers phone unlock while this says so
    function reportLock(locked: bool, passwordRequired: bool): void {
        root._locked = locked;
        root._passwordRequired = passwordRequired;
        root._sendLock();
    }

    // Someone is at the lock screen, so the phone can offer its fingerprint prompt
    function askToUnlock(): void {
        root.request({ cmd: "unlock_prompt" });
    }

    function _sendLock(): void {
        root.request({ cmd: "lock_state", locked: root._locked, password_required: root._passwordRequired });
    }

    function _sendUsb(): void {
        root.request({ cmd: "usb_mode", enabled: root.usb });
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
        case "unlock_granted":
            root.unlockGranted(message.by ?? "");
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
                root._sendLock();
                root._sendUsb();
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
