import QtQuick
import qs.settings.data
import qs.settings.pages
import qs.settings

Rectangle {
    id: root
    property string label: ""
    property bool active: false
    signal clicked

    implicitHeight: 32
    radius: 6
    color: active ? "#1f1f1f"
         : hoverArea.containsMouse ? "#161616"
         : "transparent"

    Text {
        anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
        text: root.label
        font.pixelSize: 13
        color: root.active ? "#ffffff"
             : hoverArea.containsMouse ? "#cccccc"
             : "#808080"
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
