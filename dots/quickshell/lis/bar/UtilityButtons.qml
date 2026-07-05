import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.notification
import qs.settings.data

Row {
    id: root
    spacing: 9

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

    // Microphone
    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true

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

    // Screenshot
    Loader {
        active: SettingsData.s.bar.showScreenshot
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                mipmap: true

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

    // Color Picker
    Loader {
        active: SettingsData.s.bar.showColorPicker
        visible: active
        sourceComponent: Item {
            width: 16
            height: 16

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                mipmap: true

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

    // Game Mode
    Loader {
        active: SettingsData.s.bar.showGameMode
        visible: active
        sourceComponent: Item {
            id: gameModeItem
            width: 16
            height: 16

            property bool toggled: false

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                mipmap: true

                source: gameModeItem.toggled ? "../icons/gamemode-on.svg" : "../icons/gamemode-off.svg"
                opacity: gameModeItem.toggled ? 1.0 : 0.5
                fillMode: Image.PreserveAspectFit

                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    gameModeItem.toggled = !gameModeItem.toggled

                    if (gameModeItem.toggled) {
                        Quickshell.execDetached(["bash", "-c", `hyprctl --batch "keyword animations:enabled 0; keyword decoration:shadow:enabled 0; keyword decoration:blur:enabled 0; keyword general:gaps_in 0; keyword general:gaps_out 5; keyword general:border_size 1; keyword decoration:rounding 0; keyword general:allow_tearing 1"`])
                    } else {
                        Quickshell.execDetached(["hyprctl", "reload"])
                    }
                }
            }
        }
    }

    // Idle inhibit
    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16
                smooth: true
                antialiasing: true
                mipmap: true
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

    // Notifications
    Loader {
        sourceComponent: Item {
            width: 16
            height: 16

            Image {
                anchors.centerIn: parent
                width: 16
                height: 16

                smooth: true
                antialiasing: true
                mipmap: true

                source: NotificationState.notificationsEnabled ? "../icons/notification.svg" : "../icons/notification-off.svg"
                fillMode: Image.PreserveAspectFit
                opacity: NotificationState.notificationsEnabled ? 1.0 : 0.5

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
                        NotificationState.notificationsEnabled = !NotificationState.notificationsEnabled
                    }
                }
            }
        }
    }
}