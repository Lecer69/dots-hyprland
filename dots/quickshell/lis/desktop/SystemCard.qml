import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.common
import qs.tools

OverviewCard {
    id: root

    required property SystemStats stats

    title: "System"
    subtitle: root.stats.uptime > 0 ? "up " + Format.duration(root.stats.uptime) : ""
    implicitHeight: root.headerHeight + column.implicitHeight + 24

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 14

        SystemMeters {
            Layout.fillWidth: true
            stats: root.stats
        }

        InfoRow {
            Layout.fillWidth: true
            visible: BatteryData.available
            label: "Battery"
            value: BatteryData.percent + "%" + (BatteryData.charging ? " · Charging" : "")
        }
    }
}
