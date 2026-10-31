import QtQuick
import QtQuick.Shapes
import qs.common

Item {
    id: root

    property int percent: 0
    property bool charging: false
    property bool available: false

    implicitWidth: sz
    implicitHeight: sz

    readonly property real sz: 96
    readonly property real cx: sz * 0.5
    readonly property real r: sz * 0.5 - 6

    // Only a critical level gets a colour
    function arcColor() {
        if (root.charging) return Theme.text
        if (root.percent <= 10) return Theme.adapt("#e06c6c")
        return Theme.adapt("#bbbbbb")
    }

    property real animatedSweep: percent * 3.6

    Behavior on animatedSweep {
        NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
    }

    onPercentChanged: animatedSweep = percent * 3.6

    Shape {
        id: ring
        width: root.sz
        height: root.sz
        anchors.centerIn: parent

        layer.enabled: true
        layer.samples: 8
        layer.smooth: true
        layer.textureSize: Qt.size(root.sz * 2, root.sz * 2)

        vendorExtensionsEnabled: true

        ShapePath {
            strokeColor: Theme.adapt("#2a2a2a")
            strokeWidth: 4
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

        ShapePath {
            strokeColor: root.arcColor()
            strokeWidth: 4
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
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

    Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.available ? root.percent + "%" : "--"
            font.pixelSize: 20
            font.weight: Font.DemiBold
            color: Theme.text
        }

        Rectangle {
            visible: root.charging && root.available
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: 6
            radius: 3
            color: root.arcColor()
            antialiasing: true
        }
    }
}