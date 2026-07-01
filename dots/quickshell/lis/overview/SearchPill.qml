import QtQuick

Rectangle {
    id: searchPill
    
    implicitWidth: contentItem.childrenRect.width + horizontalPadding * 2
    implicitHeight: 28
    
    property real horizontalPadding: 6
    
    radius: implicitHeight / 2
    color: '#de0f0f0f'
    
    default property alias content: contentItem.data
    
    Item {
        id: contentItem
        anchors.centerIn: parent
        width: childrenRect.width
        height: childrenRect.height
    }
}