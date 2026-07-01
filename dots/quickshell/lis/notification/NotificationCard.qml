import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.settings.data

Rectangle {
    id: root
    width: 400
    height: cardLayout.implicitHeight + 16
    radius: height / 2
    color: '#0b0b0b'

    signal dismissed

    property var notification
    property int timeout: (root.notification && root.notification.expireTimeout > 0) ? root.notification.expireTimeout : (SettingsData.s.general.notificationTimeout * 1000)

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: true
        onTriggered: root.dismissed()
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        onContainsMouseChanged: {
            if (containsMouse) {
                dismissTimer.stop()
            } else {
                dismissTimer.restart()
            }
        }
    }

    RowLayout {
        id: cardLayout
        anchors {
            fill: parent
            leftMargin: 8
            rightMargin: 8
            topMargin: 8
            bottomMargin: 8
        }
        spacing: 2

        Item {
            width: 34
            height: 34
            Layout.alignment: Qt.AlignVCenter
            visible: iconImage.status === Image.Ready || hintImage.status === Image.Ready

            Image {
                id: hintImage
                anchors.fill: parent
                source: root.notification.image ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: hintImage.width
                        height: hintImage.height
                        radius: 17
                    }
                }
            }

            Image {
                id: iconImage
                anchors.fill: parent
                visible: hintImage.status !== Image.Ready
                source: {
                    const icon = root.notification.appIcon
                    if (!icon || icon === "") return ""
                    if (icon.startsWith("/") || icon.startsWith("file://")) return icon
                    return "image://icon/" + icon
                }
                fillMode: Image.PreserveAspectCrop
                onStatusChanged: {
                    if (status === Image.Error)
                        console.log("[Notifications] Icon failed:", source)
                }
                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: hintImage.width
                        height: hintImage.height
                        radius: 17
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: root.notification.summary
                color: '#e2e2e2'
                font.pixelSize: 13
                font.weight: Font.Medium
                Layout.leftMargin: 8
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                Layout.fillWidth: true
                visible: text !== ""
            }

            Text {
                property string cleaned: root.notification.body
                    .replace(/<img[^>]*>/gi, "")
                    .replace(/<[^>]*>/g, "")
                    .trim()

                text: cleaned
                color: '#858585'
                font.pixelSize: 12
                elide: Text.ElideRight
                Layout.leftMargin: 8
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                Layout.fillWidth: true
                visible: cleaned !== ""
                textFormat: Text.PlainText
            }

            RowLayout {
                spacing: 4
                visible: root.notification.actions.length > 0

                Repeater {
                    model: root.notification.actions
                    delegate: Rectangle {
                        radius: 6
                        color: actionHover.containsMouse ? "#40ffffff" : "#20ffffff"
                        height: 22
                        width: actionLabel.implicitWidth + 14

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: modelData.text
                            color: "#ffffff"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.notification.invokeAction(modelData.identifier)
                                root.dismissed()
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            width: 22
            height: 22
            radius: 11
            color: closeHover.containsMouse ? "#40ffffff" : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "#80ffffff"
                font.pixelSize: 12
            }

            MouseArea {
                id: closeHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissed()
            }
        }
    }

    NumberAnimation on opacity {
        running: true
        from: 0
        to: 1
        duration: 150
    }
}