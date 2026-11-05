import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.settings.components
import qs.settings.data
import qs.settings

// The preview stays above the list, so every change shows in it
Item {
    id: root

    // What SettingsPanel's PgUp/PgDn scroll
    readonly property Item contentItem: scroll.contentItem

    // The StackLayout sizes from its pages' implicit size
    implicitWidth: scroll.implicitWidth
    implicitHeight: scroll.implicitHeight + preview.height + 24

    Loader {
        id: preview

        anchors { top: parent.top; horizontalCenter: parent.horizontalCenter; topMargin: 16 }
        width: 320
        height: 180
        active: root.visible && (QsWindow.window?.visible ?? false)

        sourceComponent: LockPreview {}
    }

    ScrollView {
        id: scroll

        anchors { top: preview.bottom; left: parent.left; right: parent.right; bottom: parent.bottom; topMargin: 8 }
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0

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

            Item {
                height: 16
            }
            SectionHeader {
                title: "Privacy"
            }

            SettingRow {
                label: "Mute microphone while locked"
                ToggleSwitch {
                    checked: SettingsData.s.lockScreen.muteMicOnLock
                    onToggled: v => SettingsData.s.lockScreen.muteMicOnLock = v
                }
            }
            SettingRow {
                label: "Mute speaker while locked"
                ToggleSwitch {
                    checked: SettingsData.s.lockScreen.muteSpeakerOnLock
                    onToggled: v => SettingsData.s.lockScreen.muteSpeakerOnLock = v
                }
            }

            Item {
                height: 16
            }
        }
    }
}
