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

        Component.onCompleted: {
            Quickshell.execDetached(["mkdir", "-p", homeDir + "/.config/lis"])
            reload()
            initTimer.start()
        }

        JsonAdapter {
            id: adapter

            // General
            property JsonObject general: JsonObject {
                property bool notificationsEnabled: true
                property bool enableIdleInhibitedByDefault: false
                property int notificationTimeout: 5
                property string accentColor: '#822828'
            }

            // Bar
            property JsonObject bar: JsonObject {
                property bool showBluetooth: true
                property bool showGameMode: true
                property bool showNetwork: true
                property bool showClockAndDate: true
                property bool showClockOnly: false
                property bool showColorPicker: true
                property bool showScreenshot: true
                property int workspaceNumbers: 10
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
           }

            // osu!
            property JsonObject osu: JsonObject {
                property bool disableNotifications: true
                property bool backdropOtherMonitors: false
                property real backdropOpacity: 0.6
                property string backdropColor: "#000000"
            }
        }
    }

    Timer {
        id: initTimer
        interval: 100
        repeat: false
        onTriggered: {
            if (!root._ready) {
                console.log("[SettingsData] seeding defaults")
                root._ready = true
                fileView.writeAdapter()
            } else {
                console.log("[SettingsData] loaded from disk")
            }
        }
    }

    Connections {
        target: fileView
        function onAdapterUpdated() {
            if (!root._ready) {
                console.log("[SettingsData] adapter populated from disk")
                root._ready = true
            }
        }
    }
}
