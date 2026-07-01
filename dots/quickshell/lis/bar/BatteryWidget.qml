import QtQuick
import QtQuick.Shapes
import Quickshell
import qs.tools

Item {
    id: root

    implicitWidth: sz
    implicitHeight: sz

    readonly property int percent: BatteryData.percent
    readonly property bool charging: BatteryData.charging
    readonly property bool available: BatteryData.available

    readonly property real sz: 20
    readonly property real cx: sz * 0.5
    readonly property real r: sz * 0.5 - 1.75

    function arcColor() {
        if (root.percent == -100) return '#4a4a4a'
        if (root.charging) return "#a6e3a1"
        if (root.percent <= 10) return "#f38ba8"
        if (root.percent <= 30) return "#fab387"
        return "#89b4fa"
    }

    onVisibleChanged: {
        if (visible) BatteryData.addViewer()
        else BatteryData.removeViewer()
    }

    Component.onCompleted: { if (visible) BatteryData.addViewer() }
    Component.onDestruction: { if (visible) BatteryData.removeViewer() }

    property real animatedSweep: percent * 3.6
    Behavior on animatedSweep {
        NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
    }
    onPercentChanged: animatedSweep = percent * 3.6

    Shape {
        id: ring
        x: 0
        y: (root.sz - root.sz) * 0.5
        width:  root.sz
        height: root.sz

        anchors.verticalCenter: parent.verticalCenter

        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        layer.textureSize: Qt.size(root.sz * 2, root.sz * 2)

        vendorExtensionsEnabled: true

        // track
        ShapePath {
            strokeColor: Qt.rgba(1, 1, 1, 0.13)
            strokeWidth: 2.5
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathAngleArc {
                centerX: root.cx
                centerY: root.cx
                radiusX: root.r
                radiusY: root.r
                startAngle: -90
                sweepAngle: 360
            }
        }

        // filled arc
        ShapePath {
            strokeColor: root.arcColor()
            strokeWidth: 2.5
            fillColor:   "transparent"
            capStyle:    ShapePath.RoundCap
            PathAngleArc {
                centerX: root.cx
                centerY: root.cx
                radiusX: root.r
                radiusY: root.r
                startAngle: -90
                sweepAngle: root.animatedSweep
            }
        }
    }

    // charging dot
    Rectangle {
        visible: root.charging && root.available
        width: 6
        height: 6
        radius: 3
        color: root.arcColor()
        antialiasing: true
        x: (root.sz - width)  / 2
        y: (root.sz - height) / 2
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: batteryWindow.shown = !batteryWindow.shown
    }
}
