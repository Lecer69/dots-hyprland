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

        // Only seed when there's no file; writing on other failures could lose the user's settings
        onLoadFailed: error => {
            if (error !== FileViewError.FileNotFound)
                return
            console.log("[SettingsData] seeding defaults")
            root._ready = true
            writeAdapter()
        }

        // Blocks until parsed, so things made at startup (the boot lock) see real values
        Component.onCompleted: waitForJob()

        JsonAdapter {
            id: adapter

            property JsonObject general: JsonObject {
                property bool notificationsEnabled: true
                property bool enableIdleInhibitedByDefault: false
                property int notificationTimeout: 5
                property bool notificationsMainMonitorOnly: true
                property string accentColor: '#822828'
                property string colorScheme: 'expressive'
                property bool lightMode: false
            }

            property JsonObject bar: JsonObject {
                property string position: "top"
                // The colors have a light mode copy
                property string pillColor: "#c30f0f0f"
                property string pillColorLight: "#c3f5f5f5"
                // 0 hides the border
                property int pillBorderWidth: 1
                property string pillBorderColor: "#26ffffff"
                property string pillBorderColorLight: "#26000000"
                property bool pillBlur: false
                property bool showBluetooth: true
                property bool showGameMode: true
                property bool showNetwork: true
                property bool showClockAndDate: true
                property bool showClockOnly: false
                property bool showColorPicker: true
                property bool showScreenshot: true
                property int workspaceNumbers: 10
                // Screen name -> its own workspace count; others use workspaceNumbers
                property var workspaceNumbersPerMonitor: ({})
                property string workspaceStyle: "numbers"
                property bool onlyAccessibleWorkspaces: false
                property bool trayIconTint: true
                property bool workspaceIconTint: true
            }

            property JsonObject tracking: JsonObject {
                property bool wellbeingEnabled: true
                property bool internetUsageEnabled: true
            }

            property JsonObject workspaceOverview: JsonObject {
                property int rows: 2
                property int columns: 5
                property real scale: 0.15
                property bool orderBottomUp: true
                property bool orderRightLeft: false
                property bool centerIcons: false
            }

            property JsonObject lockScreen: JsonObject {
                property bool enableBlur: false
                property int blurSize: 15
                property int blurPasses: 5
                property real brightness: 0.8
                property bool blockVerticalScreens: false
                property bool muteMicOnLock: true
           }

            // Minutes
            property JsonObject hypridle: JsonObject {
                property int lockTimeout: 5
                property int screenOffTimeout: 10
                property int suspendTimeout: 15
            }

            property JsonObject osu: JsonObject {
                property bool disableNotifications: true
                property bool backdropOtherMonitors: false
                property real backdropOpacity: 0.6
                property string backdropColor: "#000000"
                // ms
                property int backdropFadeDuration: 400
            }

            // ~/.config/hypr/hyprland/scripts/cleanup.sh
            property JsonObject cleanup: JsonObject {
                // Package versions the pacman cache keeps
                property int pacmanKeep: 2
                // cleanup.sh item names
                property var selected: ["pacman", "coredumps", "yay", "thumbnails", "crashes"]
            }

            // scripts/dots-update.sh
            property JsonObject dotsUpdater: JsonObject {
                // Zip hypr and quickshell into ~/.dots-hyprland-backups first
                property bool backup: true
                // Replace ~/.config/quickshell and restart the shell
                property bool updateShell: true
            }
        }
    }
}
