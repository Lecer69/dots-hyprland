import QtQuick
import QtQuick.Layouts

// A label and value on one line
RowLayout {
    id: info

    property string label: ""
    property string value: ""

    Text {
        Layout.fillWidth: true
        text: info.label
        elide: Text.ElideRight
        color: Theme.textDim
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    Text {
        text: info.value
        color: Theme.adapt("#999999")
        font.pixelSize: 12
    }
}
