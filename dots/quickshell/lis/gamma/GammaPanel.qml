import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    GammaState {
        id: state
    }

    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Display"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#dddddd"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: closeHover.containsMouse ? "#252525" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: "#888888"
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    Rectangle {
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: "#222222"
    }

    ColumnLayout {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        anchors.topMargin: 28
        spacing: 20

        GammaSlider {
            label: "Brightness"
            value: state.brightness
            accent: "#f9e2af"
            onMoved: function(v) {
                state.brightness = v;
            }
            onReleased: function(v) {
                state.brightness = v;
                state.apply();
            }
        }

        GammaSlider {
            label: "Contrast"
            value: state.contrast
            accent: "#89b4fa"
            onMoved: function(v) {
                state.contrast = v;
            }
            onReleased: function(v) {
                state.contrast = v;
                state.apply();
            }
        }

        GammaSlider {
            label: "Gamma"
            value: state.gamma
            accent: "#a6e3a1"
            onMoved: function(v) {
                state.gamma = v;
            }
            onReleased: function(v) {
                state.gamma = v;
                state.apply();
            }
        }

        GammaSlider {
            label: "Saturation"
            value: state.saturation
            accent: "#cba6f7"
            onMoved: function(v) {
                state.saturation = v;
            }
            onReleased: function(v) {
                state.saturation = v;
                state.apply();
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: -12
            height: 38
            radius: 8
            color: resetHover.containsMouse ? "#252525" : "#1a1a1a"
            border.color: "#2a2a2a"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Reset to defaults"
                color: "#888888"
                font.pixelSize: 13
            }

            MouseArea {
                id: resetHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: state.reset()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }

            }

        }

    }

}
