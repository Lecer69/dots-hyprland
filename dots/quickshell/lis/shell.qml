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
import qs.calendar
import qs.cheatsheet
import qs.wellbeing
import qs.battery
import qs.workspaces
import qs.internet
import qs.network
import qs.bluetooth
import qs.audio
import qs.taskmanager
import qs.displays
import qs.osu
import qs.hypridle
import qs.desktop
import qs.notes
import qs.goals
import qs.screenshot
import qs.leftsidebar
import qs.phone
import qs.proton

ShellRoot {
    id: root

    // Kept across hot reloads, which would otherwise lock the screen again
    PersistentProperties {
        reloadableId: "bootLock"

        property bool done: false

        onLoaded: {
            if (!done && Quickshell.env("ON_HYPRSTART") === "true") {
                done = true
                screenLock.lockAtBoot()
                WorkspaceBlocks.focusStartWorkspaces()
            }
        }
    }

    property ScreenLock screenLock: ScreenLock {
    }

    HypridleService {
    }

    WorkspaceOverviewLayer {
        id: workspaceOverviewLayer
    }

    DesktopOverview {
        locked: screenLock.isLocked
        onTodoRequested: todoWindow.shown = true
        onCalendarRequested: calendarWindow.shown = true
    }

    WellbeingWindow {
        id: wellbeingWindow
        locked: screenLock.isLocked
    }

    InternetUsageWindow {
        id: internetUsageWindow
    }

    BatteryWindow {
        id: batteryWindow
    }

    CheatsheetWindow {
        id: cheatsheetWindow
    }

    SettingsWindow {
        id: settingsWindow
    }

    NotificationCenterWindow {
        id: notificationCenterWindow
    }

    GammaWindow {
        id: gammaWindow
    }

    NetworkWindow {
        id: networkWindow
    }

    BluetoothWindow {
        id: bluetoothWindow
    }

    AudioWindow {
        id: audioWindow
    }

    TaskManagerWindow {
        id: taskManagerWindow
    }

    ProtonWindow {
        id: protonWindow
    }

    DisplaysWindow {
        id: displaysWindow
    }

    PhoneWindow {
        id: phoneWindow
        onSettingsRequested: settingsWindow.shown = true
    }

    TodoWindow {
        id: todoWindow
    }

    NotesWindow {
        id: notesWindow
    }

    GoalsWindow {
        id: goalsWindow
    }

    ScreenFreeze {
    }

    CalendarWindow {
        id: calendarWindow
    }

    PowerDialog {
        id: powerDialog
    }

    SidebarMenu {
        id: sidebarMenu
    }

    LeftSidebarWindow {
        id: leftSidebar
        onTodoRequested: todoWindow.shown = true
    }

    BarBlur {
    }

    Process {
        command: ["snixembed", "--fork"]
        running: true
    }

    NotificationPopup {
        visible: !screenLock.isLocked
    }

    OsuBackdrop {
    }

    Overview {
    }

    Variants {
        model: Quickshell.screens
        delegate: QtObject {
            id: screenCtx

            required property var modelData


            property var hyprMonitor: Hyprland.monitorFor(modelData)
            property int wsId: hyprMonitor?.activeWorkspace?.id ?? -1
            property bool fullscreen: HyprlandData.hasFullscreen(wsId)
            property bool show: !screenLock.isLocked && !fullscreen

            property var bar: Bar {
                screen: modelData
                // Stays mapped while locked: Hyprland puts a newly mapped top layer above a fullscreen window
                visible: BarState.barShown
                sidebarOpen: sidebarMenu.isOpen && sidebarMenu.screen === modelData
                onSidebarRequested: sidebarMenu.toggle(modelData)
            }
            property var volBar: Loader {
                active: screenCtx.show
                sourceComponent: Component {
                    VolumeHoverBar {
                        screen: modelData
                        onClicked: sidebarMenu.toggle(modelData)
                    }
                }
            }
            property var volPop: Loader {
                active: screenCtx.show
                sourceComponent: Component {
                    VolumePopup {
                        screen: modelData
                    }
                }
            }
            property var briBar: Loader {
                active: screenCtx.show
                sourceComponent: Component {
                    BrightnessHoverBar {
                        screen: modelData
                        onClicked: leftSidebar.toggle(modelData)
                    }
                }
            }
            property var briPop: Loader {
                active: screenCtx.show
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
    }
}