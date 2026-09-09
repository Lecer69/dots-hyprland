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

PanelWindow {
    id: bar
    color: "transparent"

    // Only top/bottom docking is supported; stale values fall back to top
    readonly property string position: SettingsData.s.bar.position === "bottom" ? "bottom" : "top"
    // Compact layout: a portrait (vertical) screen
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

    property int pageSize: SettingsData.s.bar.workspaceNumbers
    property var monitor: Hyprland.monitorFor(bar.screen)
    property int currentWs: monitor?.activeWorkspace?.id ?? 1
    property int startWs: Math.floor((currentWs - 1) / pageSize) * pageSize + 1

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel

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

                Image {
                    visible: !bar.compact
                    source: "../icons/arch-symbolic.svg"
                    width: 16
                    height: 16
                    fillMode: Image.PreserveAspectFit
                }

                CpuPercentage   { visible: bar.compact }
                Divider         { visible: bar.compact }
                MemoryPercentage { visible: bar.compact }

                Text {
                    id: windowTitle
                    visible: !bar.compact
                    width: Math.min(implicitWidth, 400)
                    elide: Text.ElideRight
                    text: ToplevelManager.activeToplevel?.title ?? ("Desktop - Workspace " + (bar.monitor?.activeWorkspace?.id ?? "?"))
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#bdbdbd"
                }

                Text {
                    id: windowAppId
                    visible: !bar.compact
                    elide: Text.ElideRight
                    text: ToplevelManager.activeToplevel?.appId ?? ""
                    font.pixelSize: 11
                    color: '#909090'
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
                    model: pageSize

                    WorkspacePill {
                        wsIndex: startWs + index
                        focused: bar.monitor?.activeWorkspace?.id === (startWs + index)
                        occupied: {
                            const ws = Hyprland.workspaces.values.find(w => w.id === (startWs + index))
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

            Grid {
                rows: 1
                columns: 0
                horizontalItemAlignment: Qt.AlignLeft
                verticalItemAlignment: Qt.AlignVCenter
                spacing: 10

                BatteryWidget {
                    id: batteryWidget
                    visible: !bar.compact
                }

                Divider {
                    visible: !bar.compact && mediaWidget.hasMedia
                }

                MediaWidget {
                    id: mediaWidget
                    visible: !bar.compact && hasMedia
                    screen: bar.screen
                }

                Divider {
                    visible: !bar.compact && sysTray.count > 0
                }

                SysTrayWidget {
                    id: sysTray
                    visible: !bar.compact
                    screen: bar.screen
                }

                Divider { visible: !bar.compact && sysTray.count > 0 }

                UtilityButtons { }

                Divider { visible: SettingsData.s.bar.showClockAndDate }

                ClockWidget {
                    visible: SettingsData.s.bar.showClockAndDate
                }

                Divider { }

                BluetoothWidget {
                    visible: !bar.compact && SettingsData.s.bar.showBluetooth
                }

                WifiWidget {
                    visible: !bar.compact && SettingsData.s.bar.showNetwork
                }

                SettingsButton {
                    id: settingsBtn
                    otherMenu: powerBtn.menu
                    screen: bar.screen
                }

                PowerButton {
                    id: powerBtn
                    visible: !bar.compact
                    otherMenu: settingsBtn.menu
                    screen: bar.screen
                }
            }
        }
    }
}
