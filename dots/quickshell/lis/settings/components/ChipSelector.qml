import QtQuick
import QtQuick.Layouts
import qs.settings.data
import qs.settings.pages
import qs.settings

Row {
    id: root

    property var options: []
    property string value: ""

    signal selected(string val)

    spacing: 6

    Repeater {
        model: root.options
        delegate: Rectangle {
            required property string modelData
            property bool active: root.value === modelData

            height: 30
            width: label.implicitWidth + 22
            radius: 8
            color: active ? "#30ffffff" : "#14ffffff"
            border.color: active ? "#44ffffff" : "#18ffffff"
            border.width: 1

            Behavior on color { ColorAnimation { duration: 100 } }

            Text {
                id: label
                anchors.centerIn: parent
                text: modelData
                font { pixelSize: 12; weight: active ? Font.Medium : Font.Normal }
                color: active ? "#ffffff" : "#99ffffff"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.value = modelData
                    root.selected(modelData)
                }
            }
        }
    }
}
