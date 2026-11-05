import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.settings.components
import qs.settings.data
import qs.settings
import qs.common

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
            label: "Light Mode"
            description: "Dark text and icons on light backgrounds"
            ToggleSwitch {
                checked: SettingsData.s.general.lightMode
                onToggled: v => SettingsData.s.general.lightMode = v
            }
        }

        SettingRow {
            label: "Accent Color"
            description: "Used across bar, overview, and controls"
            ColorPicker {
                value: SettingsData.s.general.accentColor
                onSelected: v => SettingsData.s.general.accentColor = v
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 8
            Layout.bottomMargin: 8
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 2

                Text {
                    text: "Color Scheme"
                    font.pixelSize: 13
                    color: Theme.text
                }
                Text {
                    text: "Material You scheme variant used when applying colors"
                    font.pixelSize: 12
                    color: Theme.textDim
                }
            }

            ChipSelector {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 16
                options: ["content", "expressive", "fidelity", "monochrome", "neutral", "tonal-spot", "vibrant", "rainbow", "fruit-salad"]
                value: SettingsData.s.general.colorScheme
                onSelected: v => SettingsData.s.general.colorScheme = v
            }
        }

        SettingRow {
            label: "Apply Colors"
            description: "Generate and apply the color scheme from your accent color"
            Rectangle {
                id: applyButton
                height: 28
                width: applyLabel.implicitWidth + 24
                radius: 6
                color: applyArea.pressed ? Theme.adapt("#333333") : (applyArea.containsMouse ? Theme.adapt("#2a2a2a") : Theme.border)

                Text {
                    id: applyLabel
                    anchors.centerIn: parent
                    text: "Apply"
                    font { pixelSize: 12; weight: Font.Medium }
                    color: Theme.text
                }

                MouseArea {
                    id: applyArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const hex = SettingsData.s.general.accentColor.replace("#", "")
                        const scheme = SettingsData.s.general.colorScheme
                        Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "matugen", "#" + hex, scheme])
                    }
                }
            }
        }

        Item { height: 16 }
        SectionHeader { title: "Night Light" }

        SettingRow {
            label: "Night Light"
            description: "Applied with wl-gammactl-rust; the bar's button turns it on and off too"
            ToggleSwitch {
                id: nightLightSwitch
                checked: SettingsData.s.nightLight.enabled
                onToggled: v => {
                    SettingsData.s.nightLight.enabled = v
                    // Flipping replaced the binding, and the bar's button can change it too
                    nightLightSwitch.checked = Qt.binding(() => SettingsData.s.nightLight.enabled)
                }
            }
        }
        SettingRow {
            label: "Brightness"
            FloatSlider {
                from: 0.6; to: 1.2; stepSize: 0.01; decimals: 2
                value: SettingsData.s.nightLight.brightness
                onChanged: v => SettingsData.s.nightLight.brightness = v
            }
        }
        SettingRow {
            label: "Contrast"
            FloatSlider {
                from: 0.4; to: 1.2; stepSize: 0.01; decimals: 2
                value: SettingsData.s.nightLight.contrast
                onChanged: v => SettingsData.s.nightLight.contrast = v
            }
        }
        SettingRow {
            label: "Gamma"
            FloatSlider {
                from: 0.5; to: 1.5; stepSize: 0.01; decimals: 2
                value: SettingsData.s.nightLight.gamma
                onChanged: v => SettingsData.s.nightLight.gamma = v
            }
        }
        SettingRow {
            label: "Saturation"
            description: "Lower cuts blue light the most"
            FloatSlider {
                from: 0.2; to: 1.2; stepSize: 0.01; decimals: 2
                value: SettingsData.s.nightLight.saturation
                onChanged: v => SettingsData.s.nightLight.saturation = v
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
            label: "Main Monitor Only"
            description: "Show popups on the main (first landscape) monitor instead of the focused one"
            ToggleSwitch {
                checked: SettingsData.s.general.notificationsMainMonitorOnly
                onToggled: v => SettingsData.s.general.notificationsMainMonitorOnly = v
            }
        }
        SettingRow {
            label: "Keep History After Restart"
            description: "Saves notification text to ~/.local/state/lis"
            ToggleSwitch {
                checked: SettingsData.s.general.keepNotificationHistory
                onToggled: v => SettingsData.s.general.keepNotificationHistory = v
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
        SectionHeader { title: "Tracking" }

        SettingRow {
            label: "Enable Digital Wellbeing"
            description: "Track active-app usage time for the Wellbeing panel"
            ToggleSwitch {
                checked: SettingsData.s.tracking.wellbeingEnabled
                onToggled: v => SettingsData.s.tracking.wellbeingEnabled = v
            }
        }
        SettingRow {
            label: "Enable Internet Usage"
            description: "Track per-app network traffic for the Internet Usage panel"
            ToggleSwitch {
                checked: SettingsData.s.tracking.internetUsageEnabled
                onToggled: v => SettingsData.s.tracking.internetUsageEnabled = v
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
        SectionHeader { title: "Configuration" }

        SettingRow {
            label: "Export Configuration"
            description: "Saves the JSON files of ~/.config/lis to a .lisc file"
            PanelButton {
                text: "Export…"
                enabled: !ConfigTransfer.busy
                onClicked: ConfigTransfer.startExport()
            }
        }
        SettingRow {
            label: "Import Configuration"
            description: ConfigTransfer.pending
                ? "Replaces " + ConfigTransfer.pending.files.length + " files with the ones from " + ConfigTransfer.pending.host + ", " + ConfigTransfer.pending.created
                : "Replaces them from a .lisc file and restarts the shell"
            Row {
                spacing: 6

                PanelButton {
                    visible: ConfigTransfer.pending !== null
                    text: "Cancel"
                    onClicked: ConfigTransfer.cancelImport()
                }
                PanelButton {
                    text: ConfigTransfer.pending ? "Import" : "Import…"
                    enabled: !ConfigTransfer.busy
                    onClicked: ConfigTransfer.pending ? ConfigTransfer.confirmImport() : ConfigTransfer.startImport()
                }
            }
        }
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            Layout.topMargin: 4
            visible: ConfigTransfer.status !== ""
            text: ConfigTransfer.status
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Theme.textDim
            font.pixelSize: 12
        }

        Item { height: 16 }
    }
}
