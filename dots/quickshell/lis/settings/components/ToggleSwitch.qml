import QtQuick
import qs.settings.data
import qs.settings.pages
import qs.settings

Item {
    id: root

    property bool checked: false

    signal toggled(bool value)

    width: 36
    height: 20

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? "#e6e6e6" : "#2a2a2a"

        Rectangle {
            width: 14; height: 14
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: root.checked ? "#0f0f0f" : "#808080"

            Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
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
