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
        SectionHeader { title: "Appearance" }

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
                    color: "#eeeeee"
                }
                Text {
                    text: "Material You scheme variant used when applying colors"
                    font.pixelSize: 11
                    color: "#777777"
                }
            }

            ChipSelector {
                Layout.fillWidth: true
                Layout.leftMargin: 16
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
                height: 30
                width: applyLabel.implicitWidth + 22
                radius: 8
                color: applyArea.pressed ? "#40ffffff" : (applyArea.containsMouse ? "#30ffffff" : "#14ffffff")
                border.color: "#44ffffff"
                border.width: 1

                Behavior on color { ColorAnimation { duration: 100 } }

                Text {
                    id: applyLabel
                    anchors.centerIn: parent
                    text: "Apply"
                    font { pixelSize: 12; weight: Font.Medium }
                    color: "#ffffff"
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
    }
}
