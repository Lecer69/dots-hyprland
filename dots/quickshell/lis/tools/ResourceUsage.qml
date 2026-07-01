pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real memoryTotal: 1
    property real memoryFree: 0
    property real memoryUsed: memoryTotal - memoryFree
    property real memoryUsedPercentage: memoryUsed / memoryTotal
    property real swapTotal: 1
    property real swapFree: 0
    property real swapUsed: swapTotal - swapFree
    property real swapUsedPercentage: swapTotal > 0 ? (swapUsed / swapTotal) : 0
    property real cpuUsage: 0
    property string maxAvailableCpuString: "--"

    property real _prevCpuTotal: -1
    property real _prevCpuIdle: -1

    signal updated()

    readonly property var _reMemTotal: /MemTotal:\s+(\d+)/
    readonly property var _reMemAvail: /MemAvailable:\s+(\d+)/
    readonly property var _reSwapTotal: /SwapTotal:\s+(\d+)/
    readonly property var _reSwapFree: /SwapFree:\s+(\d+)/
    readonly property var _reCpuLine: /^cpu\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)/

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: root._poll()
    }

    function _poll() {
        fileMeminfo.reload()
        fileStat.reload()

        const textMeminfo = fileMeminfo.text()

        root.memoryTotal = Number(_reMemTotal.exec(textMeminfo)?.[1] ?? 1)
        root.memoryFree = Number(_reMemAvail.exec(textMeminfo)?.[1] ?? 0)
        root.swapTotal = Number(_reSwapTotal.exec(textMeminfo)?.[1] ?? 1)
        root.swapFree = Number(_reSwapFree.exec(textMeminfo)?.[1] ?? 0)

        const textStat = fileStat.text()
        const cpuLine = _reCpuLine.exec(textStat)

        if (cpuLine) {
            const v0 = Number(cpuLine[1])
            const v1 = Number(cpuLine[2])
            const v2 = Number(cpuLine[3])
            const idle = Number(cpuLine[4])
            const v4 = Number(cpuLine[5])
            const v5 = Number(cpuLine[6])
            const v6 = Number(cpuLine[7])
            const total = v0 + v1 + v2 + idle + v4 + v5 + v6

            if (root._prevCpuTotal >= 0) {
                const totalDiff = total - root._prevCpuTotal
                const idleDiff = idle - root._prevCpuIdle
                root.cpuUsage = totalDiff > 0 ? (1 - idleDiff / totalDiff) : 0
            }

            root._prevCpuTotal = total
            root._prevCpuIdle = idle
        }

        root.updated()
    }

    FileView { id: fileMeminfo; path: "/proc/meminfo" }
    FileView { id: fileStat; path: "/proc/stat" }

    Process {
        id: findCpuMaxFreqProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        command: ["bash", "-c", "lscpu | grep 'CPU max MHz' | awk '{print $4}'"]
        running: true
        stdout: StdioCollector {
            id: outputCollector
            onStreamFinished: {
                root.maxAvailableCpuString = (parseFloat(outputCollector.text) / 1000).toFixed(0) + " GHz"
            }
        }
    }
}
