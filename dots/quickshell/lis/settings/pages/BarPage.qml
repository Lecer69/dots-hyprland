import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
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
        SectionHeader { title: "Layout" }

        SettingRow {
            label: "Bar Position"
            description: "Edge of the screen the bar docks to"
            ChipSelector {
                options: ["top", "bottom"]
                value: SettingsData.s.bar.position
                onSelected: v => SettingsData.s.bar.position = v
            }
        }

        Item { height: 8 }
        SectionHeader { title: "Workspace" }

        SettingRow {
            label: "Workspace Numbers"
            description: "Default for every screen"
            IntSlider {
                from: 5; to: 30; stepSize: 1
                value: SettingsData.s.bar.workspaceNumbers
                onChanged: v => SettingsData.s.bar.workspaceNumbers = v
            }
        }

        // A screen set to the default keeps following it
        Repeater {
            model: Quickshell.screens

            SettingRow {
                id: screenRow

                required property var modelData
                readonly property int count: SettingsData.s.bar.workspaceNumbersPerMonitor[modelData.name] ?? SettingsData.s.bar.workspaceNumbers

                Layout.leftMargin: 16
                label: modelData.name
                IntSlider {
                    id: screenSlider
                    from: 5; to: 30; stepSize: 1
                    value: screenRow.count
                    onChanged: v => {
                        const counts = Object.assign({}, SettingsData.s.bar.workspaceNumbersPerMonitor)
                        if (v === SettingsData.s.bar.workspaceNumbers) delete counts[screenRow.modelData.name]
                        else counts[screenRow.modelData.name] = v
                        SettingsData.s.bar.workspaceNumbersPerMonitor = counts
                        // Dragging replaced the binding to the setting
                        screenSlider.value = Qt.binding(() => screenRow.count)
                    }
                }
            }
        }

        SettingRow {
            label: "Workspace Style"
            description: "Dots or numbers on the bar"
            ChipSelector {
                options: ["numbers", "dots"]
                value: SettingsData.s.bar.workspaceStyle
                onSelected: v => SettingsData.s.bar.workspaceStyle = v
            }
        }

        SettingRow {
            label: "Only Accessible Workspaces"
            description: "Show only this screen's workspaces, hiding ones owned by other screens"
            ToggleSwitch {
                checked: SettingsData.s.bar.onlyAccessibleWorkspaces
                onToggled: v => SettingsData.s.bar.onlyAccessibleWorkspaces = v
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
            label: "Show Clock Only"
            ToggleSwitch {
                checked: SettingsData.s.bar.showClockOnly
                onToggled: v => SettingsData.s.bar.showClockOnly = v
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

        Item { height: 8 }
        SectionHeader { title: "Colors" }

        SettingRow {
            label: "Pill Color"
            description: "Background of the bar's pills"
            ColorPicker {
                value: SettingsData.s.bar.pillColor
                defaultValue: "#c30f0f0f"
                onSelected: v => SettingsData.s.bar.pillColor = v
            }
        }
        SettingRow {
            label: "Pill Border"
            description: "Border width around the bar's pills, 0 for none"
            IntSlider {
                from: 0; to: 4; stepSize: 1; suffix: "px"
                value: SettingsData.s.bar.pillBorderWidth
                onChanged: v => SettingsData.s.bar.pillBorderWidth = v
            }
        }
        SettingRow {
            label: "Border Color"
            description: "Color of the pills' border"
            ColorPicker {
                value: SettingsData.s.bar.pillBorderColor
                defaultValue: "#26ffffff"
                onSelected: v => SettingsData.s.bar.pillBorderColor = v
            }
        }
        SettingRow {
            label: "Pill Blur"
            description: "Blur what's behind the bar's pills"
            ToggleSwitch {
                checked: SettingsData.s.bar.pillBlur
                onToggled: v => SettingsData.s.bar.pillBlur = v
            }
        }
        SettingRow {
            label: "Tint Tray Icons"
            description: "Colorize system tray icons with the accent color"
            ToggleSwitch {
                checked: SettingsData.s.bar.trayIconTint
                onToggled: v => SettingsData.s.bar.trayIconTint = v
            }
        }
        SettingRow {
            label: "Tint Workspace Icons"
            description: "Colorize workspace app icons with the accent color"
            ToggleSwitch {
                checked: SettingsData.s.bar.workspaceIconTint
                onToggled: v => SettingsData.s.bar.workspaceIconTint = v
            }
        }

        Item { height: 16 }
    }
}
