import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings

Flow {
    id: root

    property var options: []
    property string value: ""

    signal selected(string val)

    spacing: 4

    Repeater {
        model: root.options
        delegate: Rectangle {
            required property string modelData
            property bool active: root.value === modelData

            height: 28
            width: label.implicitWidth + 20
            radius: 6
            color: active ? "#262626" : "transparent"

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData
                font.pixelSize: 12
                color: active ? "#ffffff"
                     : area.containsMouse ? "#cccccc"
                     : "#808080"
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.value = modelData
                    root.selected(modelData)
                }
            }
        }
    }
}
