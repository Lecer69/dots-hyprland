import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.settings.data
import qs.settings.pages
import qs.settings

Rectangle {
    id: root
    property string label: ""
    property string icon: ""
    property bool active: false
    signal clicked

    height: 40
    radius: 10
    color: active ? "#222222"
         : hoverArea.containsMouse ? "#1a1a1a"
         : "transparent"

    Behavior on color { ColorAnimation { duration: 100 } }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16

            Image {
                id: iconImage
                anchors.fill: parent
                source: root.icon
                sourceSize: Qt.size(16, 16)
                fillMode: Image.PreserveAspectFit
                smooth: true
                antialiasing: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: iconImage
                source: iconImage
                color: root.active ? "#ffffff" : "#888888"

                Behavior on color { ColorAnimation { duration: 100 } }
            }
        }
        Text {
            text: root.label
            font { pixelSize: 13; weight: root.active ? Font.Medium : Font.Normal }
            color: root.active ? "#ffffff" : "#888888"
        }
        Item { Layout.fillWidth: true }

        Rectangle {
            width: 5; height: 5; radius: 3
            color: "#ffffff"
            opacity: root.active ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
