import QtQuick
import QtQuick.Layouts
import Quickshell

ColumnLayout {
    id: root

    property string appName: ""
    property int seconds: 0
    property int maxSeconds: 1
    property bool isActive: false
    property string timeLabel: "0s"
    property string iconName: "application-x-executable"
    // Visible in the QtQuick scene-graph sense (covers ScrollView clipping/parent visibility too)
    property bool _onScreen: root.visible && root.Window.window && root.Window.window.visible

    spacing: 6
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true
        spacing: 10

        Item {
            width: 26
            height: 26

            Image {
                id: iconImg

                anchors.centerIn: parent
                width: 22
                height: 22
                source: {
                    if (!root.iconName || root.iconName.length === 0) return "";
                    return Quickshell.iconPath(root.iconName, true);
                }
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                visible: status === Image.Ready
            }

            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: "#808080"
                visible: !iconImg.visible

                SequentialAnimation on opacity {
                    running: root.isActive && !iconImg.visible && root._onScreen
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.25
                        duration: 700
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: 1
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 22 + 4
                height: 22 + 4
                radius: (22 + 4) / 2
                color: "transparent"
                border.color: "#bbbbbb"
                border.width: 1.5
                visible: root.isActive && iconImg.visible
                opacity: 0.6

                SequentialAnimation on opacity {
                    running: root.isActive && iconImg.visible && root._onScreen
                    loops: Animation.Infinite

                    NumberAnimation {
                        to: 0.15
                        duration: 700
                        easing.type: Easing.InOutSine
                    }

                    NumberAnimation {
                        to: 0.7
                        duration: 700
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }

        Text {
            text: root.appName
            color: root.isActive ? "#ffffff" : "#e6e6e6"
            font.pixelSize: 12
            font.weight: root.isActive ? Font.Medium : Font.Normal
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        Text {
            text: root.timeLabel
            color: "#999999"
            font.pixelSize: 12
        }
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 3

        Rectangle {
            anchors.fill: parent
            radius: 1.5
            color: "#1f1f1f"
        }

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: 1.5
            color: root.isActive ? "#e6e6e6" : "#808080"
            width: root.maxSeconds > 0 ? Math.max(5, parent.width * Math.min(root.seconds / root.maxSeconds, 1)) : 5

            Behavior on width {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
