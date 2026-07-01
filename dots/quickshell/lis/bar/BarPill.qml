import QtQuick

Rectangle {
    id: barPill

    implicitWidth: contentItem.width + horizontalPadding * 2
    implicitHeight: 28

    property real horizontalPadding: 6

    radius: 14
    color: '#c30f0f0f'

    default property alias content: contentItem.data

    Item {
        id: contentItem
        anchors.centerIn: parent
        width: children.length > 0 ? children[0].implicitWidth : 0
        height: children.length > 0 ? children[0].implicitHeight : 0
    }
}