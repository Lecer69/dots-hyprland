import QtQuick
import QtQuick.Layouts

// A label and value over a bar filled to `value` (0-1)
ColumnLayout {
    id: meter

    property string label: ""
    property real value: 0
    property string valueText: ""

    spacing: 6

    RowLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: meter.label
            elide: Text.ElideRight
            color: "#6b6b6b"
            font.pixelSize: 12
            font.weight: Font.Medium
        }

        Text {
            text: meter.valueText
            color: "#999999"
            font.pixelSize: 12
        }
    }

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 3
        radius: 1.5
        color: "#2a2a2a"

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, meter.value))
            height: parent.height
            radius: parent.radius
            color: "#bbbbbb"

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }
    }
}
