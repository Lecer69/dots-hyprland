import QtQuick
import QtQuick.Layouts
import qs.common
import qs.tools

// The phone's figures
ColumnLayout {
    id: root

    required property var stats

    spacing: 12

    UsageMeter {
        Layout.fillWidth: true
        label: "Battery"
        value: (root.stats?.battery_percent ?? 0) / 100
        valueText: (root.stats?.battery_percent ?? 0) + "%" + (root.stats?.charging ? " · Charging" : "")
    }

    UsageMeter {
        Layout.fillWidth: true
        label: "Storage"
        value: root.stats?.storage_total > 0 ? root.stats.storage_used / root.stats.storage_total : 0
        valueText: Format.bytes(root.stats?.storage_used ?? 0) + " / " + Format.bytes(root.stats?.storage_total ?? 0)
    }

    UsageMeter {
        Layout.fillWidth: true
        label: "Memory"
        value: root.stats?.memory_total > 0 ? root.stats.memory_used / root.stats.memory_total : 0
        valueText: Format.bytes(root.stats?.memory_used ?? 0) + " / " + Format.bytes(root.stats?.memory_total ?? 0)
    }

    InfoRow {
        Layout.fillWidth: true
        label: "Network"
        value: root.stats?.network ?? ""
    }
}
