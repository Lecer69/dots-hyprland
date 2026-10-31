import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings
import qs.common

// Lit while its control has keyboard focus
FocusScope {
    id: root

    default property alias content: controlSlot.data
    property string label: ""
    property string description: ""

    Layout.fillWidth: true
    implicitHeight: description !== "" ? 58 : 44

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.activeFocus ? Theme.hover : "transparent"
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
                color: Theme.text
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                visible: root.description !== ""
                text: root.description
                font.pixelSize: 12
                color: Theme.textDim
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
