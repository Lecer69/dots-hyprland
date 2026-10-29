pragma Singleton

import QtCore
import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings.components
import qs.settings.pages
import qs.settings

Singleton {
    id: root

    readonly property string homeDir: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")
    readonly property var s: adapter

    property bool _ready: false

    FileView {
        id: fileView
        path: homeDir + "/.config/lis/settings.json"
        watchChanges: true

        onFileChanged: reload()

        onAdapterUpdated: {
            if (root._ready)
                writeAdapter()
        }

        onLoaded: root._ready = true

        // Only seed when there is no file; writing on any other failure (or
        // on a timer, as before) could overwrite the user's settings.
        // Writing creates ~/.config/lis if needed.
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return
            console.log("[SettingsData] seeding defaults")
            root._ready = true
            writeAdapter()
        }

        // Block until settings.json is parsed so everything created at
        // startup (e.g. the boot lock screen) sees the real values instead
        // of defaults that change a moment later
        Component.onCompleted: waitForJob()

        JsonAdapter {
            id: adapter

            // General
            property JsonObject general: JsonObject {
                property bool notificationsEnabled: true
                property bool enableIdleInhibitedByDefault: false
                property int notificationTimeout: 5
                property bool notificationsMainMonitorOnly: true
                property string accentColor: '#822828'
                property string colorScheme: 'expressive'
            }

            // Bar
            property JsonObject bar: JsonObject {
                property string position: "top"
                property string pillColor: "#c30f0f0f"
                // 0 hides the border
                property int pillBorderWidth: 1
                property string pillBorderColor: "#26ffffff"
                property bool pillBlur: false
                property bool showBluetooth: true
                property bool showGameMode: true
                property bool showNetwork: true
                property bool showClockAndDate: true
                property bool showClockOnly: false
                property bool showColorPicker: true
                property bool showScreenshot: true
                property int workspaceNumbers: 10
                // Screens that show their own number of workspaces, by
                // screen name; the rest use workspaceNumbers
                property var workspaceNumbersPerMonitor: ({})
                property string workspaceStyle: "numbers"
                property bool onlyAccessibleWorkspaces: false
                property bool trayIconTint: true
                property bool workspaceIconTint: true
            }

            // Tracking
            property JsonObject tracking: JsonObject {
                property bool wellbeingEnabled: true
                property bool internetUsageEnabled: true
            }

            // Workspace Overview
            property JsonObject workspaceOverview: JsonObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.15
                property bool orderBottomUp: true
                property bool orderRightLeft: false
                property bool centerIcons: false
            }

            // Lock Screen
            property JsonObject lockScreen: JsonObject {
                property bool enableBlur: false
                property int blurSize: 15
                property int blurPasses: 5
                property real brightness: 0.8
                property bool blockVerticalScreens: false
                property bool muteMicOnLock: true
           }

            // Hypridle timers in minutes (hypridle/HypridleService.qml turns
            // these into its config)
            property JsonObject hypridle: JsonObject {
                property int lockTimeout: 5
                property int screenOffTimeout: 10
                property int suspendTimeout: 15
            }

            // osu!
            property JsonObject osu: JsonObject {
                property bool disableNotifications: true
                property bool backdropOtherMonitors: false
                property real backdropOpacity: 0.6
                property string backdropColor: "#000000"
                // How long the backdrop takes to fade in or out, in ms
                property int backdropFadeDuration: 400
            }

            // Cleanup page (~/.config/hypr/hyprland/scripts/cleanup.sh)
            property JsonObject cleanup: JsonObject {
                // Cached versions of each package the pacman cache keeps
                property int pacmanKeep: 2
                // Ticked items, by cleanup.sh's item names
                property var selected: ["pacman", "coredumps", "yay", "thumbnails", "crashes"]
            }
        }
    }
}
