import QtQuick
import QtQuick.Layouts
import qs.tools

// CPU, memory, each GPU and disk, and network traffic, in `columns` columns
// of equal width
GridLayout {
    id: root

    required property SystemStats stats

    columns: 1
    columnSpacing: 24
    rowSpacing: 14

    // Cells share the width by these equal preferred widths
    UsageMeter {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        label: "CPU"
        value: ResourceUsage.cpuUsage
        valueText: Math.round(ResourceUsage.cpuUsage * 100) + "%"
            + (root.stats.cpuTemp >= 0 ? " · " + Math.round(root.stats.cpuTemp) + "°C" : "")
    }

    UsageMeter {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        label: "Memory"
        value: ResourceUsage.memoryUsedPercentage
        valueText: Format.bytes(ResourceUsage.memoryUsed * 1024) + " / " + Format.bytes(ResourceUsage.memoryTotal * 1024)
    }

    // By count, so the meters stay (and animate) as the figures change
    Repeater {
        model: root.stats.gpus.length

        UsageMeter {
            required property int index
            readonly property var gpu: root.stats.gpus[index] ?? ({})

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: gpu.name ?? ""
            value: Math.max(0, gpu.usage ?? 0)
            valueText: Format.gpu(gpu)
        }
    }

    Repeater {
        model: root.stats.disks.length

        UsageMeter {
            required property int index
            readonly property var disk: root.stats.disks[index] ?? ({})

            Layout.fillWidth: true
            Layout.preferredWidth: 1
            label: "Disk " + (disk.mount ?? "")
            value: disk.size > 0 ? disk.used / disk.size : 0
            valueText: Format.bytes(disk.used) + " / " + Format.bytes(disk.size)
        }
    }

    InfoRow {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        label: "Network"
        value: Format.network(root.stats)
    }
}
