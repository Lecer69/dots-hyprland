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
        SectionHeader { title: "In-Game Settings" }

        SettingRow {
            label: "Disable Notifications"
            description: "Disables notifications in-game"
            ToggleSwitch {
                checked: SettingsData.s.osu.disableNotifications
                onToggled: v => SettingsData.s.osu.disableNotifications = v
            }
        }
        SettingRow {
            label: "Backdrop Other Monitors"
            description: "Makes other monitors darker"
            ToggleSwitch {
                checked: SettingsData.s.osu.backdropOtherMonitors
                onToggled: v => SettingsData.s.osu.backdropOtherMonitors = v
            }
        }
        SettingRow {
            label: "Backdrop Opacity"
            description: "Opacity for backdrop"
            FloatSlider {
                from: 0.01; to: 0.95; stepSize: 0.01; decimals: 2
                value: SettingsData.s.osu.backdropOpacity
                onChanged: v => SettingsData.s.osu.backdropOpacity = v
            }
        }

        Item { height: 16 }
    }
}
