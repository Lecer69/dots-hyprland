import QtQuick
import Quickshell
import Quickshell.Io

// GPUs, disks, network, CPU temperature and uptime from scripts/system-stats.sh, every 2 s
Scope {
    id: root

    property bool running: false

    // Seconds
    property real uptime: 0
    property string netInterface: ""
    // Bytes per second, -1 until two samples
    property real downRate: -1
    property real upRate: -1
    // { mount, size, used } in bytes
    property var disks: []
    // °C, -1 without a sensor
    property real cpuTemp: -1
    // { name, off, usage (0-1), memUsed, memTotal (MiB), temp (°C) }, -1 when unknown
    property var gpus: []

    property var _lastNet: null

    // Rates shouldn't average over the stopped time
    onRunningChanged: {
        root._lastNet = null;
        root.downRate = -1;
        root.upRate = -1;
    }

    Timer {
        interval: 2000
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }

    Process {
        id: sampler

        command: ["sh", Quickshell.shellPath("scripts/system-stats.sh")]

        stdout: StdioCollector {
            onStreamFinished: root._ingest(text)
        }
    }

    function _number(text: string): real {
        const n = parseFloat(text);
        return isNaN(n) ? -1 : n;
    }

    // "NVIDIA GeForce RTX 3050" and "GA106 [Geforce RTX 3050]" both become "RTX 3050"
    function _gpuName(text: string): string {
        const bracket = text.match(/\[(.+)\]/);
        const name = (bracket ? bracket[1] : text).replace(/^(NVIDIA|AMD)\s+/i, "").replace(/^GeForce\s+/i, "").trim();
        return name || "GPU";
    }

    function _ingest(text: string): void {
        const disks = [];
        const gpus = [];
        let net = null;
        let cpuTemp = -1;

        for (const line of text.split("\n")) {
            const f = line.split(" ");
            if (f[0] === "uptime") {
                root.uptime = root._number(f[1]);
            } else if (f[0] === "net") {
                net = { iface: f[1], rx: Number(f[2]), tx: Number(f[3]), time: Date.now() };
            } else if (f[0] === "disk") {
                disks.push({ mount: f.slice(3).join(" "), size: Number(f[1]), used: Number(f[2]) });
            } else if (f[0] === "cputemp") {
                cpuTemp = Number(f[1]) / 1000;
            } else if (f[0] === "gpu" && f[1] === "off") {
                gpus.push({ name: root._gpuName(f.slice(2).join(" ")), off: true, usage: -1, memUsed: -1, memTotal: -1, temp: -1 });
            } else if (f[0] === "gpu") {
                const usage = root._number(f[1]);
                gpus.push({
                    name: root._gpuName(f.slice(5).join(" ")),
                    off: false,
                    usage: usage < 0 ? -1 : usage / 100,
                    memUsed: root._number(f[2]),
                    memTotal: root._number(f[3]),
                    temp: root._number(f[4])
                });
            }
        }

        const last = root._lastNet;
        if (net && last && last.iface === net.iface && net.time > last.time) {
            const seconds = (net.time - last.time) / 1000;
            root.downRate = Math.max(0, (net.rx - last.rx) / seconds);
            root.upRate = Math.max(0, (net.tx - last.tx) / seconds);
        } else {
            root.downRate = -1;
            root.upRate = -1;
        }
        root._lastNet = net;
        root.netInterface = net ? net.iface : "";

        root.disks = disks;
        root.gpus = gpus;
        root.cpuTemp = isNaN(cpuTemp) ? -1 : cpuTemp;
    }
}
