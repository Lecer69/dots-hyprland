import QtQuick
import qs.common

Rectangle {
    id: searchPill
    
    implicitWidth: contentItem.childrenRect.width + horizontalPadding * 2
    implicitHeight: 28
    
    property real horizontalPadding: 6
    
    radius: 8
    color: Theme.hover
    
    default property alias content: contentItem.data
    
    Item {
        id: contentItem
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}