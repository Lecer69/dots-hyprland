import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

// A SettingRow-like row with a checkbox in front and a value (e.g. a size)
// at the end; clicking anywhere on it toggles the box
Item {
    id: root

    property string label: ""
    property string description: ""
    property string value: ""
    property bool checked: false

    signal toggled(bool value)

    Layout.fillWidth: true
    implicitHeight: description !== "" ? 58 : 44
    opacity: enabled ? 1 : 0.4

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 12

        Rectangle {
            width: 16
            height: 16
            radius: 4
            Layout.alignment: Qt.AlignVCenter
            color: root.checked ? "#e6e6e6" : "transparent"
            border.width: root.checked ? 0 : 1
            border.color: area.containsMouse ? "#5a5a5a" : "#3a3a3a"

            Shape {
                anchors.fill: parent
                visible: root.checked
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: "#0f0f0f"
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    joinStyle: ShapePath.RoundJoin

                    PathPolyline {
                        path: [Qt.point(4, 8.5), Qt.point(7, 11.5), Qt.point(12, 5)]
                    }
                }
            }
        }

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

        Text {
            text: root.value
            font.pixelSize: 12
            color: "#999999"
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }
    }
}
