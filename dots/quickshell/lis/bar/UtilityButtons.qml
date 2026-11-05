import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.settings.data
import qs.common
import qs.gamma

Grid {
    id: root
    property bool vertical: false
    // Made while the shell loads, as only then does a reload hand it its old state
    readonly property bool gameMode: GameModeState.active

    rows: root.vertical ? 0 : 1
    columns: root.vertical ? 1 : 0
    horizontalItemAlignment: root.vertical ? Qt.AlignHCenter : Qt.AlignLeft
    verticalItemAlignment: root.vertical ? Qt.AlignVCenter : Qt.AlignTop
    spacing: 9

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)

                source: Pipewire.defaultAudioSource?.audio?.muted ? "../icons/mic-off.svg" : "../icons/mic-on.svg"
                opacity: Pipewire.defaultAudioSource?.audio?.muted ? 0.5 : 1.0
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Quickshell.execDetached([
                        "sh", "-c",
                        "pactl set-source-mute @DEFAULT_SOURCE@ toggle && " +
                        "[ $(pactl get-source-mute @DEFAULT_SOURCE@ | grep -o yes) ] && " +
                        "paplay ~/.config/hypr/sounds/mute.wav || " +
                        "paplay ~/.config/hypr/sounds/unmute.wav"
                    ])
                }
            }
        }
    }

    Loader {
        active: SettingsData.s.bar.showScreenshot
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)

                source: "../icons/screenshot.svg"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    Quickshell.execDetached([
                        "bash", Quickshell.env("HOME") + "/.config/hypr/hyprland/scripts/screenshot-region.sh"
                    ])
                }
            }
        }
    }

    Loader {
        active: SettingsData.s.bar.showColorPicker
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)

                source: "../icons/color-picker.svg"
                fillMode: Image.PreserveAspectFit
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                onClicked: {
                    Quickshell.execDetached(["hyprpicker", "-a"])
                }
            }
        }
    }

    Loader {
        active: SettingsData.s.bar.showNightLight
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                mipmap: true
                sourceSize: Qt.size(32, 32)

                source: GammaService.nightLight ? "../icons/night-light-on.svg" : "../icons/night-light.svg"
                opacity: GammaService.nightLight ? 1.0 : 0.5
                fillMode: Image.PreserveAspectFit

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: GammaService.toggleNightLight()
            }
        }
    }

    Loader {
        active: SettingsData.s.bar.showGameMode
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)

                source: root.gameMode ? "../icons/gamemode-on.svg" : "../icons/gamemode-off.svg"
                opacity: root.gameMode ? 1.0 : 0.5
                fillMode: Image.PreserveAspectFit

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: GameModeState.toggle()
            }
        }
    }

    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16
                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)
                source: IdleInhibitState.idleInhibited ? "../icons/sleep-off.svg" : "../icons/sleep.svg"
                opacity: IdleInhibitState.idleInhibited ? 1.0 : 0.5
                fillMode: Image.PreserveAspectFit

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: IdleInhibitState.toggle()
            }
        }
    }

    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Icon {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                sourceSize: Qt.size(16, 16)

                source: SettingsData.s.general.notificationsEnabled ? "../icons/notification.svg" : "../icons/notification-off.svg"
                fillMode: Image.PreserveAspectFit
                opacity: SettingsData.s.general.notificationsEnabled ? 1.0 : 0.5

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        notificationCenterWindow.shown = true
                    } else {
                        SettingsData.s.general.notificationsEnabled = !SettingsData.s.general.notificationsEnabled
                    }
                }
            }
        }
    }
}