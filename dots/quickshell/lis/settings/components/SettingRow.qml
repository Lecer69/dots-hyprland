import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings

Item {
    id: root

    default property alias content: controlSlot.data
    property string label: ""
    property string description: ""

    Layout.fillWidth: true
    implicitHeight: description !== "" ? 62 : 46

    Rectangle {
        anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
        radius: 8
        color: rowHover.hovered ? "#191919" : "transparent"
        Behavior on color { ColorAnimation { duration: 80 } }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 16

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true
            Layout.minimumWidth: 0

            Text {
                text: root.label
                font.pixelSize: 13
                color: "#eeeeee"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.description !== ""
                text: root.description
                font.pixelSize: 11
                color: "#777777"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        Item {
            id: controlSlot
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
            Layout.alignment: Qt.AlignVCenter
        }
    }

    HoverHandler {
        id: rowHover
    }
}
