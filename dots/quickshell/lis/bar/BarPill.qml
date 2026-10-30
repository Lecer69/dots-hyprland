import QtQuick
import qs.settings.data

Rectangle {
    id: barPill

    implicitWidth: vertical ? 28 : contentItem.width + horizontalPadding * 2
    implicitHeight: vertical ? contentItem.height + horizontalPadding * 2 : 28

    property real horizontalPadding: 6
    property bool vertical: false

    radius: 14
    color: SettingsData.s.bar.pillColor

    default property alias content: contentItem.data

    // Over the fill, not as the border, so a see-through border doesn't show the desktop
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.width: SettingsData.s.bar.pillBorderWidth
        border.color: SettingsData.s.bar.pillBorderColor
        visible: border.width > 0
    }

    Item {
        id: contentItem
        anchors.centerIn: parent
        width: children.length > 0 ? children[0].implicitWidth : 0
        height: children.length > 0 ? children[0].implicitHeight : 0
    }
}