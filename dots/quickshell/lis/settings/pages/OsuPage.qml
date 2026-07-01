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
            label: "Disable Overview"
            description: "Disables any overview keybinds in-game"
            ToggleSwitch {
                checked: SettingsData.s.osu.disableOverview
                onToggled: v => SettingsData.s.osu.disableOverview = v
            }
        }

        Item { height: 16 }
    }
}
