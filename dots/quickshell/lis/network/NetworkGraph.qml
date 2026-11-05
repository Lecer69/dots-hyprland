import QtQuick
import QtQuick.Shapes
import Quickshell.Widgets
import qs.common
import qs.tools

// Download as a filled line and upload as a dim one, newest on the right, scaled to the minute's peak
ClippingRectangle {
    id: root

    // Off while the panel is closed
    property bool active: false

    readonly property var down: root.active ? NetworkUsage.down : []
    readonly property var up: root.active ? NetworkUsage.up : []
    readonly property real peak: Math.max(1024, ...root.down, ...root.up)

    function line(values: var): var {
        const step = root.width / (NetworkUsage.samples - 1)
        const end = values.length - 1
        return values.map((value, i) => Qt.point(root.width - (end - i) * step, root.height - 1 - value / root.peak * (root.height - 14)))
    }

    readonly property var downLine: root.line(root.down)
    readonly property var upLine: root.line(root.up)

    radius: 8
    color: Theme.adapt("#131313")

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: Theme.adapt("#1fffffff")

            PathPolyline {
                path: root.downLine.length < 2 ? [] : root.downLine.concat([
                    Qt.point(root.width, root.height),
                    Qt.point(root.downLine[0].x, root.height)
                ])
            }
        }

        ShapePath {
            strokeColor: Theme.text
            strokeWidth: 1.2
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.downLine
            }
        }

        ShapePath {
            strokeColor: Theme.textDim
            strokeWidth: 1.2
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin

            PathPolyline {
                path: root.upLine
            }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 6
        text: Format.rate(root.peak)
        color: Theme.textDim
        font.pixelSize: 10
    }
}
