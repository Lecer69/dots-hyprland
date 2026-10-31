import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.common

Rectangle {
    id: root

    signal dismissed()

    property var entry

    radius: 8
    color: itemHover.containsMouse || root.activeFocus ? Theme.hover : "transparent"
    implicitHeight: rowLayout.implicitHeight + 20

    MouseArea {
        id: itemHover

        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: rowLayout

        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
            topMargin: 10
            bottomMargin: 10
        }
        spacing: 10

        Item {
            width: 32
            height: 32
            Layout.alignment: Qt.AlignVCenter
            visible: iconImage.status === Image.Ready || hintImage.status === Image.Ready

            Image {
                id: hintImage

                anchors.fill: parent
                source: root.entry.image ?? ""
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready
                clip: true

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: hintImage.width
                        height: hintImage.height
                        radius: 16
                    }
                }
            }

            Image {
                id: iconImage

                anchors.fill: parent
                source: hintImage.status === Image.Ready ? "" : (root.entry.appIcon ?? "")
                fillMode: Image.PreserveAspectCrop
                visible: status === Image.Ready

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: iconImage.width
                        height: iconImage.height
                        radius: 16
                    }
                }
            }
        }

        Rectangle {
            width: 32
            height: 32
            radius: 16
            color: Theme.border
            Layout.alignment: Qt.AlignVCenter
            visible: iconImage.status !== Image.Ready && hintImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: (root.entry.appName ?? "?").charAt(0).toUpperCase()
                color: Theme.adapt("#999999")
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: root.entry.appName ?? ""
                    color: Theme.adapt("#808080")
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.entry.time ?? ""
                    color: Theme.textDim
                    font.pixelSize: 11
                }
            }

            Text {
                text: root.entry.summary ?? ""
                color: Theme.text
                font.pixelSize: 13
                font.weight: Font.Medium
                elide: Text.ElideRight
                maximumLineCount: 1
                wrapMode: Text.NoWrap
                Layout.fillWidth: true
                visible: text !== ""
            }

            Text {
                property string cleaned: (root.entry.body ?? "")
                    .replace(/<img[^>]*>/gi, "")
                    .replace(/<[^>]*>/g, "")
                    .trim()

                text: cleaned
                color: Theme.adapt("#999999")
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: cleaned !== ""
                textFormat: Text.PlainText
            }
        }

        Item {
            width: 24
            height: 24
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: closeHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                font.pixelSize: 11
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
}
