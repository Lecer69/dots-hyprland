import QtQuick

// Full-width slider from 0 to `to`. It doesn't move by itself: it emits
// moved() and the owner writes the value back
Item {
    id: root

    property real value: 0
    property real to: 1

    readonly property real ratio: Math.max(0, Math.min(1, value / to))

    signal moved(real value)

    implicitHeight: 20

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 3
        radius: 1.5
        color: "#2a2a2a"

        Rectangle {
            width: root.ratio * parent.width
            height: parent.height
            radius: parent.radius
            color: "#bbbbbb"
        }
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: root.ratio * (root.width - width)
        width: 12
        height: 12
        radius: 6
        color: "#ffffff"
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        cursorShape: Qt.PointingHandCursor

        function valueAt(mx: real): real {
            return Math.max(0, Math.min(1, mx / width)) * root.to
        }

        onPressed: mouse => root.moved(valueAt(mouse.x))
        onPositionChanged: mouse => {
            if (pressed) root.moved(valueAt(mouse.x))
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y === 0) return
            const step = (wheel.angleDelta.y > 0 ? 0.02 : -0.02) * root.to
            root.moved(Math.max(0, Math.min(root.to, root.value + step)))
        }
    }
}
