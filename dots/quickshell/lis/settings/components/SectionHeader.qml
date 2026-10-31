import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings
import qs.common

Item {
    property string title: ""

    Layout.fillWidth: true
    height: 36

    Text {
        anchors { left: parent.left; leftMargin: 16; bottom: parent.bottom; bottomMargin: 6 }
        text: title
        font { pixelSize: 12; weight: Font.Medium }
        color: Theme.textDim
    }
}
