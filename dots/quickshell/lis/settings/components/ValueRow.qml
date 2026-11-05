import QtQuick
import qs.common

// A setting row showing a value instead of a control; hidden while it has none
SettingRow {
    id: root

    property string value: ""

    available: root.value !== ""

    Text {
        text: root.value
        textFormat: Text.PlainText
        font.pixelSize: 12
        color: Theme.adapt("#999999")
    }
}
