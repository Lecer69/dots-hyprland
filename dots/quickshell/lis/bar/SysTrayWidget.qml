import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import qs.settings.data

Item {
    id: root

    property var screen: null
    property bool vertical: false

    implicitWidth: root.vertical ? 22 : trayRow.implicitWidth
    implicitHeight: root.vertical ? trayRow.implicitHeight : 22

    property int count: repeater.count

    TrayTooltip { id: tooltip }

    SysTrayMenu {
        id: contextMenu
        screen: root.screen
    }

    Grid {
        id: trayRow
        anchors.centerIn: parent
        rows: root.vertical ? 0 : 1
        columns: root.vertical ? 1 : 0
        horizontalItemAlignment: root.vertical ? Qt.AlignHCenter : Qt.AlignLeft
        spacing: 8

        Repeater {
            id: repeater
            model: SystemTray.items

            Item {
                id: trayItem
                required property SystemTrayItem modelData
                width: 20
                height: 20

                Rectangle {
                    id: hoverBg
                    anchors.fill: parent
                    radius: 5
                    color: "#ffffff"
                    opacity: 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }

                Item {
                    id: iconContainer

                    property bool tintOff: !SettingsData.s.bar.trayIconTint

                    anchors.centerIn: parent
                    width: 16
                    height: 16

                    Image {
                        id: trayIcon
                        anchors.centerIn: parent
                        width: 16
                        height: 16
                        source: trayItem.modelData.icon ?? ""
                        sourceSize.width: width * 2
                        sourceSize.height: height * 2
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready
                        layer.enabled: !iconContainer.tintOff
                        layer.smooth: true
                        layer.mipmap: true
                        layer.effect: MultiEffect {
                            colorization: 1.0
                            colorizationColor: "#e8e8e8"
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 6
                        height: 6
                        radius: 3
                        color: "#666666"
                        visible: trayIcon.status !== Image.Ready
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: {
                        hoverBg.opacity = 0.08
                        const text = trayItem.modelData.tooltipTitle
                            ?? trayItem.modelData.title ?? ""
                        if (text !== "") tooltip.showFor(trayItem, text)
                    }

                    onExited: {
                        hoverBg.opacity = 0
                        tooltip.hide()
                    }

                    onClicked: mouse => {
                        // Real click position in global coordinates: apps like
                        // Discord use it to place their tray window correctly
                        const g = trayItem.mapToGlobal(mouse.x, mouse.y)
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(Qt.point(g.x, g.y))
                        }
                        if (mouse.button === Qt.RightButton) {
                            contextMenu.openFor(trayItem.modelData, trayItem)
                        }
                    }
                }
            }
        }
    }
}