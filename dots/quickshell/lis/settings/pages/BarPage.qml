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
        SectionHeader { title: "Workspace" }

        SettingRow {
            label: "Workspace Numbers"
            IntSlider {
                from: 5; to: 30; stepSize: 1
                value: SettingsData.s.bar.workspaceNumbers
                onChanged: v => SettingsData.s.bar.workspaceNumbers = v
            }
        }

        Item { height: 8 }
        SectionHeader { title: "Modules" }

        SettingRow {
            label: "Show Clock And Date"
            ToggleSwitch {
                checked: SettingsData.s.bar.showClockAndDate
                onToggled: v => SettingsData.s.bar.showClockAndDate = v
            }
        }
        SettingRow {
            label: "Show Color Picker"
            ToggleSwitch {
                checked: SettingsData.s.bar.showColorPicker
                onToggled: v => SettingsData.s.bar.showColorPicker = v
            }
        }
        SettingRow {
            label: "Show Screenshot"
            ToggleSwitch {
                checked: SettingsData.s.bar.showScreenshot
                onToggled: v => SettingsData.s.bar.showScreenshot = v
            }
        }
        SettingRow {
            label: "Show Game Mode"
            ToggleSwitch {
                checked: SettingsData.s.bar.showGameMode
                onToggled: v => SettingsData.s.bar.showGameMode = v
            }
        }
        SettingRow {
            label: "Show Bluetooth"
            ToggleSwitch {
                checked: SettingsData.s.bar.showBluetooth
                onToggled: v => SettingsData.s.bar.showBluetooth = v
            }
        }
        SettingRow {
            label: "Show Network"
            ToggleSwitch {
                checked: SettingsData.s.bar.showNetwork
                onToggled: v => SettingsData.s.bar.showNetwork = v
            }
        }

        Item { height: 16 }
    }
}
