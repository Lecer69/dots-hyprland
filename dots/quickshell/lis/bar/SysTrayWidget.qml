import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray

Item {
    id: root
    implicitWidth: trayRow.implicitWidth
    implicitHeight: 22

    property int count: repeater.count

    TrayTooltip { id: tooltip }

    SysTrayMenu { id: contextMenu }

    Row {
        id: trayRow
        anchors.centerIn: parent
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

                Image {
                    id: trayIcon
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: trayItem.modelData.icon ?? ""
                    smooth: true
                    mipmap: true
                    visible: status === Image.Ready
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 6
                    height: 6
                    radius: 3
                    color: "#3a5a7a"
                    visible: trayIcon.status !== Image.Ready
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
                        if (mouse.button === Qt.LeftButton) {
                            trayItem.modelData.activate(Qt.point(0, 0))
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