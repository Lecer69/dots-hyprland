import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import Quickshell.Widgets
import qs.bar
import qs.common
import qs.settings.data
import qs.tools

// The bar over this screen's wallpaper, scaled down and inert; made of the bar's own widgets
ClippingRectangle {
    id: bar

    // WorkspacePill reads it
    readonly property var screen: QsWindow.window?.screen ?? null
    readonly property var monitor: Hyprland.monitorFor(bar.screen)
    readonly property bool atTop: SettingsData.s.bar.position !== "bottom"
    readonly property string wallpaper: screenLock.wallpaperFor(bar.screen?.name ?? "")

    readonly property int pageSize: SettingsData.s.bar.workspaceNumbersPerMonitor[bar.screen?.name] ?? SettingsData.s.bar.workspaceNumbers
    readonly property var workspaceIds: {
        const first = WorkspaceBlocks.pageOf(bar.screen?.name ?? "", bar.monitor?.activeWorkspace?.id ?? 1, bar.pageSize)
        return Array.from({ length: bar.pageSize }, (_, i) => first + i)
    }

    radius: 8
    color: Theme.adapt("#131313")
    border.width: 1
    border.color: Theme.border

    Image {
        anchors.fill: parent
        source: bar.wallpaper === "" ? "" : "file://" + bar.wallpaper.split("/").map(encodeURIComponent).join("/")
        sourceSize.width: 1024
        fillMode: Image.PreserveAspectCrop
        verticalAlignment: bar.atTop ? Image.AlignTop : Image.AlignBottom
        asynchronous: true
    }

    Item {
        id: stage

        readonly property real factor: Math.max(0.01, bar.width / width)

        width: 1280
        height: bar.height / factor
        scale: factor
        transformOrigin: Item.TopLeft
        enabled: false

        Item {
            x: 8
            y: bar.atTop ? 0 : stage.height - height
            width: stage.width - 16
            height: 36

            BarPill {
                horizontalPadding: 8
                x: 0
                y: (parent.height - height) / 2

                Grid {
                    rows: 1
                    columns: 0
                    verticalItemAlignment: Qt.AlignVCenter
                    spacing: 10

                    Icon {
                        source: "../../icons/arch-symbolic.svg"
                        width: 16
                        height: 16
                        sourceSize: Qt.size(16, 16)
                        fillMode: Image.PreserveAspectFit
                    }

                    Text {
                        width: Math.min(implicitWidth, 240)
                        elide: Text.ElideRight
                        text: ToplevelManager.activeToplevel?.title ?? ("Desktop - Workspace " + (bar.monitor?.activeWorkspace?.id ?? "?"))
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: Theme.adapt("#bdbdbd")
                    }

                    Text {
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
                    verticalItemAlignment: Qt.AlignVCenter
                    spacing: 4

                    Repeater {
                        model: bar.workspaceIds

                        WorkspacePill {
                            wsIndex: modelData
                            focused: bar.monitor?.activeWorkspace?.id === modelData
                            occupied: Hyprland.workspaces.values.some(w => w.id === modelData)
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
                    verticalItemAlignment: Qt.AlignVCenter
                    spacing: 10

                    BatteryWidget {
                        id: battery
                        visible: available
                    }

                    Divider { visible: battery.visible && tray.visible }

                    Row {
                        id: tray

                        visible: trayItems.count > 0
                        spacing: 8

                        Repeater {
                            id: trayItems

                            model: SystemTray.items

                            Item {
                                required property SystemTrayItem modelData

                                width: 20
                                height: 20

                                Image {
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    source: parent.modelData.icon ?? ""
                                    sourceSize: Qt.size(16, 16)
                                    layer.enabled: SettingsData.s.bar.trayIconTint
                                    layer.effect: MultiEffect {
                                        colorization: 1
                                        colorizationColor: Theme.appIconTint
                                    }
                                }
                            }
                        }
                    }

                    Divider { visible: tray.visible }

                    UtilityButtons {}

                    Divider { visible: SettingsData.s.bar.showClockAndDate }

                    ClockWidget { visible: SettingsData.s.bar.showClockAndDate }

                    Divider { visible: SettingsData.s.bar.showBluetooth || SettingsData.s.bar.showNetwork }

                    BluetoothWidget { visible: SettingsData.s.bar.showBluetooth }

                    WifiWidget { visible: SettingsData.s.bar.showNetwork }

                    Divider {}

                    Icon {
                        width: 16
                        height: 16
                        source: "../../icons/settings.svg"
                        sourceSize: Qt.size(32, 32)
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        opacity: 0.75
                    }
                }
            }
        }
    }
}
