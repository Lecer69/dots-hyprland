import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

Rectangle {
    id: root

    signal dismissed()

    property var entry
    property color accent: "#89b4fa"

    radius: 10
    color: itemHover.containsMouse ? "#161616" : "#131313"
    border.color: "#242424"
    border.width: 1
    implicitHeight: rowLayout.implicitHeight + 20

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }

    MouseArea {
        id: itemHover

        anchors.fill: parent
        hoverEnabled: true
    }

    RowLayout {
        id: rowLayout

        anchors {
            fill: parent
            leftMargin: 14
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
            color: Qt.darker(root.accent, 2.6)
            Layout.alignment: Qt.AlignVCenter
            visible: iconImage.status !== Image.Ready && hintImage.status !== Image.Ready

            Text {
                anchors.centerIn: parent
                text: (root.entry.appName ?? "?").charAt(0).toUpperCase()
                color: root.accent
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
                    color: "#888888"
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: root.entry.time ?? ""
                    color: "#5a5a5a"
                    font.pixelSize: 11
                    font.family: "monospace"
                }
            }

            Text {
                text: root.entry.summary ?? ""
                color: "#dddddd"
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
                color: "#828282"
                font.pixelSize: 12
                elide: Text.ElideRight
                maximumLineCount: 2
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                visible: cleaned !== ""
                textFormat: Text.PlainText
            }
        }

        Rectangle {
            width: 24
            height: 24
            radius: 12
            color: closeHover.containsMouse ? "#252525" : "transparent"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "✕"
                color: "#888888"
                font.pixelSize: 11
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.dismissed()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }
    }
}
