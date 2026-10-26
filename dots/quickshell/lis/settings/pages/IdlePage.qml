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
        SectionHeader { title: "Timers" }

        SettingRow {
            label: "Lock"
            description: "Lock the screen after this long idle (5 min)"
            IntSlider {
                from: 1; to: 60; stepSize: 1; suffix: " min"
                value: SettingsData.s.hypridle.lockTimeout
                onChanged: v => SettingsData.s.hypridle.lockTimeout = v
            }
        }
        SettingRow {
            label: "Screen Off"
            description: "Turn off the screens after this long idle (10 min)"
            IntSlider {
                from: 1; to: 60; stepSize: 1; suffix: " min"
                value: SettingsData.s.hypridle.screenOffTimeout
                onChanged: v => SettingsData.s.hypridle.screenOffTimeout = v
            }
        }
        SettingRow {
            label: "Suspend"
            description: "Suspend after this long idle (15 min)"
            IntSlider {
                from: 1; to: 60; stepSize: 1; suffix: " min"
                value: SettingsData.s.hypridle.suspendTimeout
                onChanged: v => SettingsData.s.hypridle.suspendTimeout = v
            }
        }

        Item { height: 16 }
        SectionHeader { title: "Inhibit" }

        SettingRow {
            label: "Inhibit Idle by Default"
            description: "Start with the bar's idle inhibit button on"
            ToggleSwitch {
                checked: SettingsData.s.general.enableIdleInhibitedByDefault
                onToggled: v => SettingsData.s.general.enableIdleInhibitedByDefault = v
            }
        }

        Item { height: 16 }
    }
}
