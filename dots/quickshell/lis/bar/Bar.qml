import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.notification
import qs.tools
import qs.settings.data
import qs.media
import qs.common

PanelWindow {
    id: bar
    color: "transparent"
    WlrLayershell.namespace: "quickshell:bar"

    readonly property string position: SettingsData.s.bar.position === "bottom" ? "bottom" : "top"
    readonly property bool compact: bar.screen.height > bar.screen.width

    anchors {
        top: position === "top"
        bottom: position === "bottom"
        left: true
        right: true
    }

    implicitHeight: 36
    implicitWidth: 36
    exclusiveZone: 29

    property int pageSize: SettingsData.s.bar.workspaceNumbersPerMonitor[bar.screen?.name] ?? SettingsData.s.bar.workspaceNumbers
    property var monitor: Hyprland.monitorFor(bar.screen)
    property int currentWs: monitor?.activeWorkspace?.id ?? 1
    property int startWs: Math.floor((currentWs - 1) / pageSize) * pageSize + 1

    readonly property bool onlyAccessibleWorkspaces: SettingsData.s.bar.onlyAccessibleWorkspaces
    readonly property string monitorName: bar.monitor?.name ?? ""

    function isSpecialWorkspace(name) {
        return (name ?? "").startsWith("special:")
    }

    property int pageStart: 1

    function rowFrom(start, asFree) {
        const taken = ({})
        for (const ws of Hyprland.workspaces.values) {
            // Ids below 1 are special workspaces; a new one has no monitor until activated
            if (ws.id >= 1 && ws.id !== asFree && ws.monitor && ws.monitor !== bar.monitor)
                taken[ws.id] = true
        }
        const ids = []
        for (let id = start; ids.length < bar.pageSize && id < start + 1000; ++id) {
            if (!taken[id])
                ids.push(id)
        }
        return ids
    }

    function updatePageStart() {
        const ws = bar.currentWs
        if (ws >= bar.pageStart && bar.rowFrom(bar.pageStart, ws).includes(ws))
            return

        let start = 1
        for (let i = 0; i < 1000; ++i) {
            const row = bar.rowFrom(start, ws)
            if (row.length === 0 || row.includes(ws))
                break
            start = row[row.length - 1] + 1
        }
        bar.pageStart = start
    }

    onCurrentWsChanged: updatePageStart()
    onPageSizeChanged: updatePageStart()
    onAccessibleWorkspaceIdsChanged: updatePageStart()
    Component.onCompleted: updatePageStart()

    readonly property var accessibleWorkspaceIds: {
        if (!bar.onlyAccessibleWorkspaces)
            return []

        const ids = bar.rowFrom(bar.pageStart, -1)
        const active = bar.monitor?.activeWorkspace
        if (active && active.id >= 1 && !bar.isSpecialWorkspace(active.name) && !ids.includes(active.id))
            ids.push(active.id)
        return ids.sort((a, b) => a - b)
    }

    readonly property var workspaceModel: {
        if (bar.onlyAccessibleWorkspaces)
            return bar.accessibleWorkspaceIds
        const arr = []
        for (let i = 0; i < bar.pageSize; ++i)
            arr.push(bar.startWs + i)
        return arr
    }

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool activeMaximized: ((HyprlandData.clientForToplevel(activeWindow)?.fullscreen ?? 0) & 1) !== 0

    property bool sidebarOpen: false
    signal sidebarRequested()

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        BarPill {
            horizontalPadding: 8

            x: 0
            y: (parent.height - height) / 2

            Grid {
                rows: 1
                columns: 0
                horizontalItemAlignment: Qt.AlignLeft
                verticalItemAlignment: Qt.AlignVCenter
                spacing: 10

                Icon {
                    visible: !bar.compact
                    source: "../icons/arch-symbolic.svg"
                    width: 16
                    height: 16
                    sourceSize: Qt.size(16, 16)
                    fillMode: Image.PreserveAspectFit
                }

                CpuPercentage   { visible: bar.compact }
                Divider         { visible: bar.compact }
                MemoryPercentage { visible: bar.compact }

                Row {
                    visible: !bar.compact

                    Item {
                        id: maximizedMark

                        readonly property bool shown: bar.activeMaximized

                        // The icon and the gap after it
                        width: shown ? 20 : 0
                        height: 14
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on width { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

                        Icon {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            source: "../icons/maximized.svg"
                            sourceSize: Qt.size(14, 14)
                            opacity: maximizedMark.shown ? 0.85 : 0
                            scale: maximizedMark.shown ? 1 : 0.4
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
                        }
                    }

                    Text {
                        id: windowTitle
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(implicitWidth, 400)
                        elide: Text.ElideRight
                        text: ToplevelManager.activeToplevel?.title ?? ("Desktop - Workspace " + (bar.monitor?.activeWorkspace?.id ?? "?"))
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.adapt("#bdbdbd")
                    }
                }

                Text {
                    id: windowAppId
                    visible: !bar.compact
                    elide: Text.ElideRight
                    text: ToplevelManager.activeToplevel?.appId ?? ""
                    font.pixelSize: 11
                    color: Theme.adapt("#909090")
                }
            }
        }

        BarPill {
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2

            Grid {
                rows: 1
                columns: 0
                horizontalItemAlignment: Qt.AlignLeft
                verticalItemAlignment: Qt.AlignVCenter
                spacing: 4

                Repeater {
                    // Keeps the pills, so they fade between states
                    model: ScriptModel {
                        values: bar.workspaceModel
                    }

                    WorkspacePill {
                        wsIndex: modelData
                        focused: bar.monitor?.activeWorkspace?.id === modelData
                        occupied: {
                            const ws = Hyprland.workspaces.values.find(w => w.id === modelData)
                            return ws !== undefined && ws !== null
                        }
                    }
                }
            }
        }

        BarPill {
            horizontalPadding: 7

            x: parent.width - width
            y: (parent.height - height) / 2

            Row {
                Grid {
                    anchors.verticalCenter: parent.verticalCenter
                    rows: 1
                    columns: 0
                    horizontalItemAlignment: Qt.AlignLeft
                    verticalItemAlignment: Qt.AlignVCenter
                    spacing: 10

                    // Only with a laptop battery
                    BatteryWidget {
                        id: batteryWidget
                        visible: !bar.compact && available
                    }

                    Divider {
                        visible: batteryWidget.visible && mediaWidget.visible
                    }

                    MediaWidget {
                        id: mediaWidget
                        visible: !bar.compact && hasMedia
                        screen: bar.screen
                    }

                    Divider {
                        visible: sysTray.visible && (batteryWidget.visible || mediaWidget.visible)
                    }

                    SysTrayWidget {
                        id: sysTray
                        visible: count > 0
                        screen: bar.screen
                    }

                    Divider { visible: sysTray.visible }

                    UtilityButtons { }

                    Divider { visible: SettingsData.s.bar.showClockAndDate }

                    ClockWidget {
                        visible: SettingsData.s.bar.showClockAndDate
                    }

                    Divider {
                        visible: !bar.compact && (SettingsData.s.bar.showBluetooth || SettingsData.s.bar.showNetwork)
                    }

                    BluetoothWidget {
                        visible: !bar.compact && SettingsData.s.bar.showBluetooth
                    }

                    WifiWidget {
                        visible: !bar.compact && SettingsData.s.bar.showNetwork
                    }
                }

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: settingsButton.width
                    height: settingsButton.height

                    Row {
                        id: settingsButton

                        leftPadding: 10
                        spacing: 8

                        Divider {
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Icon {
                            id: settingsIcon

                            width: 16
                            height: 16
                            source: "../icons/settings.svg"
                            sourceSize: Qt.size(32, 32)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            opacity: settingsArea.containsMouse || bar.sidebarOpen ? 1 : 0.75
                        }
                    }

                    MouseArea {
                        id: settingsArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: bar.sidebarRequested()
                    }
                }
            }
        }
    }
}
