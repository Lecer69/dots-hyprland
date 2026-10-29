import QtQuick
import QtQuick.Layouts

// A label and its value on one line, styled like a UsageMeter without a bar
RowLayout {
    id: info

    property string label: ""
    property string value: ""

    Text {
        Layout.fillWidth: true
        text: info.label
        elide: Text.ElideRight
        color: "#6b6b6b"
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Text {
        text: info.value
        color: "#999999"
        font.pixelSize: 12
    }
}
