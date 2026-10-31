import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.common

// A row with a checkbox and a value; clicking anywhere toggles it
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

    function flip(): void {
        root.checked = !root.checked
        root.toggled(root.checked)
    }

    activeFocusOnTab: true
    Keys.onSpacePressed: root.flip()
    Keys.onReturnPressed: root.flip()
    Keys.onEnterPressed: root.flip()

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: root.activeFocus ? Theme.hover : "transparent"
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 16; rightMargin: 16 }
        spacing: 12

        Rectangle {
            width: 16
            height: 16
            radius: 4
            Layout.alignment: Qt.AlignVCenter
            color: root.checked ? Theme.text : "transparent"
            border.width: root.checked ? 0 : 1
            border.color: area.containsMouse || root.activeFocus ? Theme.adapt("#5a5a5a") : Theme.adapt("#3a3a3a")

            Shape {
                anchors.fill: parent
                visible: root.checked
                preferredRendererType: Shape.CurveRenderer

                ShapePath {
                    strokeColor: Theme.panel
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

        Text {
            text: root.value
            font.pixelSize: 12
            color: Theme.adapt("#999999")
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.flip()
    }
}
