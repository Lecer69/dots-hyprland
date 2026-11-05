import QtQuick
import qs.common

// A group's name and count, above its tasks
Item {
    id: root

    property string title: ""
    property string count: ""
    property real topPadding: 0

    height: 26 + root.topPadding

    InfoRow {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        label: root.title
        value: root.count
    }
}
