import QtQuick

Item {
    id: root

    property string label: ""
    property string icon: ""
    property int iconSize: 14

    signal triggered()

    width:  parent ? parent.width : 110
    height: 26

    Rectangle {
        anchors.fill: parent
        radius: 6
        color: area.containsMouse ? "#33ffffff" : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 10
        spacing: 8

        Image {
            visible: root.icon !== ""
            width: root.iconSize
            height: root.iconSize
            source: root.icon
            anchors.verticalCenter: parent.verticalCenter
            fillMode: Image.PreserveAspectFit
            smooth: true
        }

        Text {
            text: root.label
            color: "#e8e8e8"
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.triggered()
    }
}