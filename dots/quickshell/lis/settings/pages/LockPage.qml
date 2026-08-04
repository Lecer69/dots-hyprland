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

        Item {
            height: 16
        }
        SectionHeader {
            title: "Appearance"
        }

        SettingRow {
            label: "Enable Blur Shader"
            ToggleSwitch {
                checked: SettingsData.s.lockScreen.enableBlur
                onToggled: v => SettingsData.s.lockScreen.enableBlur = v
            }
        }
        SettingRow {
            label: "Blur Size"
            IntSlider {
                from: 1;
                to: 30; stepSize: 1
                value: SettingsData.s.lockScreen.blurSize
                onChanged: v => SettingsData.s.lockScreen.blurSize = v
            }
        }
        SettingRow {
            label: "Blur Passes"
            IntSlider {
                from: 1
                to: 8; stepSize: 1
                value: SettingsData.s.lockScreen.blurPasses
                onChanged: v => SettingsData.s.lockScreen.blurPasses = v
            }
        }
        SettingRow {
            label: "Brightness"
            FloatSlider {
                from: 0.0
                to: 2.0; stepSize: 0.01; decimals: 2
                value: SettingsData.s.lockScreen.brightness
                onChanged: v => SettingsData.s.lockScreen.brightness = v
            }
        }

        Item {
            height: 16
        }
        SectionHeader {
            title: "Display"
        }

        SettingRow {
            label: "Block vertical screens"
            ToggleSwitch {
                checked: SettingsData.s.lockScreen.blockVerticalScreens
                onToggled: v => SettingsData.s.lockScreen.blockVerticalScreens = v
            }
        }
    }
}
