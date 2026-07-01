import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings

Item {
    property string title: ""

    Layout.fillWidth: true
    height: 36

    Text {
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
        text: title
        font { pixelSize: 11; weight: Font.Medium; letterSpacing: 0.8 }
        color: "#66ffffff"
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16; bottom: parent.bottom }
        height: 1
        color: "#10ffffff"
    }
}
