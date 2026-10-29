import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property string label: "Label"
    property real value: 1
    readonly property real from: 0.1
    readonly property real to: 2

    signal moved(real value)
    signal released(real value)

    spacing: 6
    Layout.fillWidth: true

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: root.label
            color: "#e6e6e6"
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        Text {
            text: root.value.toFixed(2)
            color: "#999999"
            font.pixelSize: 12
        }

    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3
            radius: 1.5
            color: "#2a2a2a"
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: handle.x + handle.width / 2
            height: 3
            radius: 1.5
            color: "#bbbbbb"
        }

        Rectangle {
            id: handle

            readonly property real position: (root.value - root.from) / (root.to - root.from)

            anchors.verticalCenter: parent.verticalCenter
            x: position * (parent.width - width)
            width: 12
            height: 12
            radius: 6
            color: "#ffffff"
        }

        MouseArea {
            id: trackArea

            function valueFromX(mx) : real {
                var ratio = Math.max(0, Math.min(mx, width)) / width;
                return Math.round((root.from + ratio * (root.to - root.from)) * 100) / 100;
            }

            anchors.fill: parent
            hoverEnabled: true
            onPressed: root.moved(valueFromX(mouseX))
            onPositionChanged: {
                if (pressed) {
                    root.moved(valueFromX(mouseX));
                }
            }
            onReleased: root.released(valueFromX(mouseX))
        }

    }

}
