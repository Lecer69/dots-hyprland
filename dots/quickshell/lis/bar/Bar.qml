import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import qs.notification
import qs.tools
import qs.settings.data

PanelWindow {
    id: bar
    color: "transparent"

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 36
    exclusiveZone: implicitHeight - 7

    property int pageSize: SettingsData.s.bar.workspaceNumbers
    property var monitor: Hyprland.monitorFor(bar.screen)
    property int currentWs: monitor?.activeWorkspace?.id ?? 1
    property int startWs: Math.floor((currentWs - 1) / pageSize) * pageSize + 1

    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property bool vertical: bar.screen.height > bar.screen.width

    Item {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8

        BarPill {
            horizontalPadding: 8
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter

            Row {
                spacing: 10
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Image {
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                    source: "../icons/arch-symbolic.svg"
                    width: 16
                    height: 16
                    fillMode: Image.PreserveAspectFit
                }

                CpuPercentage   { visible: vertical }
                Divider         { visible: vertical }
                MemoryPercentage { visible: vertical }

                Text {
                    id: windowTitle
                    visible: !vertical
                    width: Math.min(implicitWidth, vertical ? 250 : 400)
                    elide: Text.ElideRight
                    text: ToplevelManager.activeToplevel?.title ?? ("Desktop - Workspace " + (monitor?.activeWorkspace?.id ?? "?"))
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#bdbdbd"
                }

                Text {
                    id: windowAppId
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    text: ToplevelManager.activeToplevel?.appId ?? ""
                    font.pixelSize: 11
                    color: '#909090'
                }
            }
        }

        BarPill {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: workspacesRow
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Repeater {
                    model: pageSize

                    WorkspacePill {
                        wsIndex: startWs + index
                        focused: monitor?.activeWorkspace?.id === (startWs + index)
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
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                BatteryWidget {
                    id: batteryWidget
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                }

                Divider {
                    visible: !vertical
                }

                SysTrayWidget {
                    id: sysTray
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                }

                Divider { visible: !vertical && sysTray.count > 0 }

                UtilityButtons { anchors.verticalCenter: parent.verticalCenter }

                Divider { visible: SettingsData.s.bar.showClockAndDate }

                ClockWidget {
                    visible: SettingsData.s.bar.showClockAndDate
                    anchors.verticalCenter: parent.verticalCenter
                }

                Divider { visible: !vertical }

                BluetoothWidget {
                    visible: !vertical && SettingsData.s.bar.showBluetooth
                    anchors.verticalCenter: parent.verticalCenter
                }

                WifiWidget {
                    visible: !vertical && SettingsData.s.bar.showNetwork
                    anchors.verticalCenter: parent.verticalCenter
                }

                SettingsButton {
                    id: settingsBtn
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                    otherMenu: powerBtn.menu
                    screen: bar.screen
                }

                PowerButton {
                    id: powerBtn
                    visible: !vertical
                    anchors.verticalCenter: parent.verticalCenter
                    otherMenu: settingsBtn.menu
                    screen: bar.screen
                }
            }
        }
    }
}
