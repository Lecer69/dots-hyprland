import QtQuick
import qs.settings.data
import qs.settings.pages
import qs.settings

Row {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: ""

    signal changed(int v)

    spacing: 8

    Rectangle {
        width: 44; height: 24
        radius: 6
        color: "#1e1e1e"
        border.color: "#333333"
        border.width: 1
        anchors.verticalCenter: parent.verticalCenter

        Text {
            anchors.centerIn: parent
            text: root.value + root.suffix
            font { pixelSize: 11; weight: Font.Medium }
            color: "#eeeeee"
        }
    }

    Item {
        id: track
        width: 130
        height: 24
        anchors.verticalCenter: parent.verticalCenter

        readonly property real ratio: root.to > root.from
            ? (root.value - root.from) / (root.to - root.from)
            : 0

        Rectangle {
            id: trackBg
            anchors.verticalCenter: parent.verticalCenter
            x: 0; width: parent.width
            height: 4; radius: 2
            color: "#2a2a2a"

            Rectangle {
                width: track.ratio * parent.width
                height: parent.height
                radius: parent.radius
                color: "#5c8aff"
            }
        }

        Rectangle {
            id: handle
            width: 14; height: 14; radius: 7
            color: dragArea.pressed ? "#dddddd" : "#ffffff"
            border.color: "#404040"
            border.width: 1
            anchors.verticalCenter: parent.verticalCenter
            x: track.ratio * (track.width - width)

            Behavior on color { ColorAnimation { duration: 60 } }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            cursorShape: Qt.SizeHorCursor
            preventStealing: true

            function valueFromX(mx) {
                var clamped = Math.max(0, Math.min(mx, track.width))
                var ratio = clamped / track.width
                var raw = root.from + ratio * (root.to - root.from)
                var steps = Math.round((raw - root.from) / root.stepSize)
                var v = root.from + steps * root.stepSize
                return Math.max(root.from, Math.min(root.to, v))
            }

            onPressed: mouse => {
                var v = valueFromX(mouse.x)
                if (v !== root.value) {
                    root.value = v
                    root.changed(v)
                }
            }
            onPositionChanged: mouse => {
                if (pressed) {
                    var v = valueFromX(mouse.x)
                    if (v !== root.value) {
                        root.value = v
                        root.changed(v)
                    }
                }
            }
        }
    }
}
