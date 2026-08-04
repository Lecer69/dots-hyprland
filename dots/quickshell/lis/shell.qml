pragma ComponentBehavior: Bound
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import qs.bar
import qs.notification
import qs.volume
import qs.brightness
import qs.hover
import qs.overview
import qs.tools
import qs.lock
import qs.polkit
import qs.settings
import qs.gamma
import qs.todo
import qs.cheatsheet
import qs.wellbeing
import qs.battery
import qs.workspaces
import qs.internet
import qs.osu

ShellRoot {
    id: root

    property bool startupMode: Quickshell.env("ON_HYPRSTART") === "true"

    Connections {
        target: Quickshell
        function onReloadCompleted() {
            console.log("[shell] reload completed")
            startupMode = false
        }
    }

    Component.onCompleted: {
        console.log("[shell] ShellRoot completed")
        if (root.startupMode) {
            screenLock.lock()
            root.startupMode = false
        }
    }

    property ScreenLock screenLock: ScreenLock {
        Component.onCompleted: console.log("[shell] ScreenLock completed")
    }

    WorkspaceOverviewLayer {
        id: workspaceOverviewLayer
        Component.onCompleted: console.log("[shell] WorkspaceOverviewLayer completed")
    }

    WellbeingWindow {
        id: wellbeingWindow
        Component.onCompleted: console.log("[shell] WellbeingWindow completed")
    }

    InternetUsageWindow {
        id: internetUsageWindow
        Component.onCompleted: console.log("[shell] InternetUsageWindow completed")
    }

    BatteryWindow {
        id: batteryWindow
        Component.onCompleted: console.log("[shell] BatteryWindow completed")
    }

    CheatsheetWindow {
        id: cheatsheetWindow
        Component.onCompleted: console.log("[shell] CheatsheetWindow completed")
    }

    SettingsWindow {
        id: settingsWindow
        Component.onCompleted: console.log("[shell] SettingsWindow completed")
    }

    NotificationCenterWindow {
        id: notificationCenterWindow
        Component.onCompleted: console.log("[shell] NotificationCenterWindow completed")
    }

    GammaWindow {
        id: gammaWindow
        Component.onCompleted: console.log("[shell] GammaWindow completed")
    }

    TodoWindow {
        id: todoWindow
        Component.onCompleted: console.log("[shell] TodoWindow completed")
    }

    Process {
        command: ["snixembed", "--fork"]
        running: true
        Component.onCompleted: console.log("[shell] snixembed Process completed")
    }

    NotificationPopup {
        visible: !screenLock.isLocked
        Component.onCompleted: console.log("[shell] NotificationPopup completed")
    }

    OsuBackdrop {
        Component.onCompleted: console.log("[shell] OsuBackdrop completed")
    }

    Overview {
        Component.onCompleted: console.log("[shell] Overview completed")
    }

    Variants {
        model: Quickshell.screens
        Component.onCompleted: console.log("[shell] Variants completed")
        delegate: QtObject {
            id: screenCtx

            required property var modelData

            Component.onCompleted: console.log("[shell] Variants delegate completed for screen: " + modelData)

            property var hyprMonitor: Hyprland.monitorFor(modelData)
            property int wsId: hyprMonitor?.activeWorkspace?.id ?? -1
            property bool fullscreen: HyprlandData.windowList.some(w => w.workspace.id === wsId && w.fullscreen > 0)
            property bool show: !screenLock.isLocked && !fullscreen

            property var bar: Bar {
                screen: modelData
                visible: !screenLock.isLocked && BarState.barShown
                Component.onCompleted: console.log("[shell] Bar completed")
            }
            property var volBar: Loader {
                active: screenCtx.show
                Component.onCompleted: console.log("[shell] volBar Loader completed")
                sourceComponent: Component {
                    VolumeHoverBar {
                        screen: modelData
                    }
                }
            }
            property var volPop: Loader {
                active: screenCtx.show
                Component.onCompleted: console.log("[shell] volPop Loader completed")
                sourceComponent: Component {
                    VolumePopup {
                        screen: modelData
                    }
                }
            }
            property var briBar: Loader {
                active: screenCtx.show
                Component.onCompleted: console.log("[shell] briBar Loader completed")
                sourceComponent: Component {
                    BrightnessHoverBar {
                        screen: modelData
                    }
                }
            }
            property var briPop: Loader {
                active: screenCtx.show
                Component.onCompleted: console.log("[shell] briPop Loader completed")
                sourceComponent: Component {
                    BrightnessPopup {
                        screen: modelData
                    }
                }
            }
        }
    }

    PolkitPopup {
        visible: !screenLock.isLocked
        Component.onCompleted: console.log("[shell] PolkitPopup completed")
    }
}