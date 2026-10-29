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
    implicitHeight: description !== "" ? 58 : 44

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
                color: "#e6e6e6"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.description !== ""
                text: root.description
                font.pixelSize: 12
                color: "#6b6b6b"
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
}
