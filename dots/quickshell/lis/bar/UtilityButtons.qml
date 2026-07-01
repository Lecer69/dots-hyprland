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
                        "sh", "-c",
                        "hyprshot --freeze --mode region --silent --output-folder /tmp && wl-copy < /tmp/screenshot_tmp.png && mkdir -p \"$(xdg-user-dir PICTURES)/Screenshots\" && cp \"$(ls -t /tmp/*.png | head -1)\" \"$(xdg-user-dir PICTURES)/Screenshots/screenshot_$(date '+%Y-%m-%d_%H.%M.%S').png\""
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
                onClicked: NotificationState.notificationsEnabled = !NotificationState.notificationsEnabled
            }
        }
    }
}