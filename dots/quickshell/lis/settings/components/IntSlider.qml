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

    spacing: 10

    Item {
        id: track
        width: 120
        height: 20
        anchors.verticalCenter: parent.verticalCenter

        readonly property real ratio: root.to > root.from
            ? (root.value - root.from) / (root.to - root.from)
            : 0

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3; radius: 1.5
            color: "#2a2a2a"

            Rectangle {
                width: track.ratio * parent.width
                height: parent.height
                radius: parent.radius
                color: "#bbbbbb"
            }
        }

        Rectangle {
            width: 12; height: 12; radius: 6
            anchors.verticalCenter: parent.verticalCenter
            x: track.ratio * (track.width - width)
            color: "#ffffff"
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

    Text {
        width: 44
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignRight
        text: root.value + root.suffix
        font.pixelSize: 12
        color: "#999999"
    }
}
