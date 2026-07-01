import QtQuick
import QtQuick.Controls
import qs.settings.data
import qs.settings.pages
import qs.settings

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    width: 44
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#5c8aff" : "#40ffffff"

        Behavior on color { ColorAnimation { duration: 150 } }

        Rectangle {
            id: thumb
            width: 18; height: 18
            radius: height / 2
            color: "white"
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3

            Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

            layer.enabled: true
            layer.effect: null
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
