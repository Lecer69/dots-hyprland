import QtQuick
import QtQuick.Shapes
import qs.tools
import qs.settings.data

Item {
    id: root

    property bool vertical: false

    // Vertical bars: icon above a colored usage ring.
    // Top/bottom bars: the classic icon + percentage text.
    implicitWidth: root.vertical ? sz : row.width
    implicitHeight: root.vertical ? iconImg.height + 6 + sz : 16

    readonly property int sz: 20
    readonly property real cx: sz * 0.5
    readonly property real r: sz * 0.5 - 1.75

    readonly property real load: ResourceUsage.memoryUsedPercentage || 0
    readonly property color arcColor: load < 0.55 ? "#89b4fa" : load < 0.8 ? "#f9e2af" : "#f38ba8"

    property real animatedSweep: load * 360
    property bool _snapSweep: false
    Behavior on animatedSweep {
        enabled: root.visible && !root._snapSweep
        NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
    }
    onLoadChanged: {
        const next = load * 360
        // Snap for tiny changes: animating every resource tick would repaint
        // the whole bar at 60fps twice a second, a constant CPU drain.
        root._snapSweep = Math.abs(next - root.animatedSweep) < 5
        root.animatedSweep = next
        root._snapSweep = false
    }

    Image {
        id: iconImg
        visible: root.vertical
        x: (root.sz - width) / 2
        width: 16
        height: 16
        source: "../icons/memory.svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        antialiasing: true
    }

    Item {
        visible: root.vertical
        y: iconImg.height + 6
        width: root.sz
        height: root.sz

        Shape {
            anchors.centerIn: parent
            width: root.sz
            height: root.sz

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

            // usage arc
            ShapePath {
                strokeColor: root.arcColor
                strokeWidth: 2.5
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

        // percentage label
        Text {
            anchors.centerIn: parent
            text: Math.round(root.load * 100)
            font.pixelSize: 7
            font.weight: Font.Medium
            color: '#acacac'
        }
    }

    Row {
        id: row
        visible: !root.vertical
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Image {
            source: "../icons/memory.svg"
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            font.pixelSize: 13
            color: '#acacac'
            anchors.verticalCenter: parent.verticalCenter

            text: Math.round(root.load * 100) + "%"
        }
    }
}