import QtQuick
import qs.settings.data
import qs.settings.pages
import qs.settings
import qs.common

Row {
    id: root

    property int value: 0
    property int from: 0
    property int to: 100
    property int stepSize: 1
    property string suffix: ""

    signal changed(int v)

    spacing: 10

    // About 2% of the range, in whole steps
    readonly property int keyStep: root.stepSize * Math.max(1, Math.round((root.to - root.from) / root.stepSize / 50))

    function nudge(direction: int): void {
        const raw = root.value + direction * root.keyStep
        const v = Math.max(root.from, Math.min(root.to, root.from + Math.round((raw - root.from) / root.stepSize) * root.stepSize))
        if (v !== root.value) {
            root.value = v
            root.changed(v)
        }
    }

    activeFocusOnTab: true
    Keys.onLeftPressed: root.nudge(-1)
    Keys.onRightPressed: root.nudge(1)

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
            color: Theme.adapt("#2a2a2a")

            Rectangle {
                width: track.ratio * parent.width
                height: parent.height
                radius: parent.radius
                color: root.activeFocus ? Theme.adapt("#ffffff") : Theme.adapt("#bbbbbb")
            }
        }

        Rectangle {
            width: root.activeFocus ? 14 : 12
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: track.ratio * (track.width - width)
            color: Theme.adapt("#ffffff")
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
        color: Theme.adapt("#999999")
    }
}
