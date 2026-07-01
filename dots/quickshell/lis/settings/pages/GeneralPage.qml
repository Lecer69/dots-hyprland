import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.components
import qs.settings.data
import qs.settings

ScrollView {
    id: root
    clip: true
    contentWidth: availableWidth

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Item { height: 16 }
        SectionHeader { title: "Appearance" }

        SettingRow {
            label: "Accent Color"
            description: "Used across bar, overview, and controls"
            ColorPicker {
                value: SettingsData.s.general.accentColor
                onSelected: v => SettingsData.s.general.accentColor = v
            }
        }

        Item { height: 16 }
        SectionHeader { title: "Notifications" }

        SettingRow {
            label: "Enable Notifications"
            ToggleSwitch {
                checked: SettingsData.s.general.notificationsEnabled
                onToggled: v => SettingsData.s.general.notificationsEnabled = v
            }
        }
        SettingRow {
            label: "Enable Idle Inhibit State by Default"
            ToggleSwitch {
                checked: SettingsData.s.general.enableIdleInhibitedByDefault
                onToggled: v => SettingsData.s.general.enableIdleInhibitedByDefault = v
            }
        }
        SettingRow {
            label: "Notification Timeout"
            description: "Auto-dismiss after N seconds (10)"
            IntSlider {
                from: 1; to: 10; stepSize: 1; suffix: "s"
                value: SettingsData.s.general.notificationTimeout
                onChanged: v => SettingsData.s.general.notificationTimeout = v
            }
        }

        Item { height: 16 }
        SectionHeader { title: "Workspace Overview" }

        SettingRow {
            label: "Rows"
            description: "Number of workspace rows (4)"
            IntSlider {
                from: 1; to: 10; stepSize: 1
                value: SettingsData.s.workspaceOverview.rows
                onChanged: v => SettingsData.s.workspaceOverview.rows = v
            }
        }
        SettingRow {
            label: "Columns"
            description: "Number of workspace columns (5)"
            IntSlider {
                from: 1; to: 10; stepSize: 1
                value: SettingsData.s.workspaceOverview.columns
                onChanged: v => SettingsData.s.workspaceOverview.columns = v
            }
        }
        SettingRow {
            label: "Scale"
            description: "Preview tile scale (0.15)"
            FloatSlider {
                from: 0.05; to: 0.5; stepSize: 0.01; decimals: 2
                value: SettingsData.s.workspaceOverview.scale
                onChanged: v => SettingsData.s.workspaceOverview.scale = v
            }
        }
        SettingRow {
            label: "Order Bottom Up"
            description: "Start workspace tiles from the bottom"
            ToggleSwitch {
                checked: SettingsData.s.workspaceOverview.orderBottomUp
                onToggled: v => SettingsData.s.workspaceOverview.orderBottomUp = v
            }
        }
        SettingRow {
            label: "Order Right to Left"
            description: "Start workspace tiles from the right"
            ToggleSwitch {
                checked: SettingsData.s.workspaceOverview.orderRightLeft
                onToggled: v => SettingsData.s.workspaceOverview.orderRightLeft = v
            }
        }
        SettingRow {
            label: "Center Icons"
            ToggleSwitch {
                checked: SettingsData.s.workspaceOverview.centerIcons
                onToggled: v => SettingsData.s.workspaceOverview.centerIcons = v
            }
        }

        Item { height: 16 }
    }
}
