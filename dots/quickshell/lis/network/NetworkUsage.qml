pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Traffic over the last minute, so the graph has data as soon as the panel opens
Singleton {
    id: root

    // Bytes per second, oldest first, one per second
    property var down: []
    property var up: []
    readonly property real downRate: root.down.length > 0 ? root.down[root.down.length - 1] : 0
    readonly property real upRate: root.up.length > 0 ? root.up[root.up.length - 1] : 0

    readonly property int samples: 60
    // Tunnels and bridges carry traffic the real interface already counts
    readonly property var _virtual: /^(lo|docker|veth|br-|virbr|vnet|tun|tap|wg|tailscale|zt)/

    property var _last: null

    function _ingest(text: string): void {
        let rx = 0
        let tx = 0
        for (const line of text.split("\n")) {
            const colon = line.indexOf(":")
            if (colon < 0 || root._virtual.test(line.slice(0, colon).trim()))
                continue
            const fields = line.slice(colon + 1).trim().split(/\s+/)
            rx += Number(fields[0])
            tx += Number(fields[8])
        }

        const now = Date.now()
        const last = root._last
        if (last && now > last.time) {
            const seconds = (now - last.time) / 1000
            root.down = root.down.concat([Math.max(0, (rx - last.rx) / seconds)]).slice(-root.samples)
            root.up = root.up.concat([Math.max(0, (tx - last.tx) / seconds)]).slice(-root.samples)
        }
        root._last = { rx: rx, tx: tx, time: now }
    }

    FileView {
        id: netDev

        path: "/proc/net/dev"
        onLoaded: root._ingest(netDev.text())
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: netDev.reload()
    }
}
