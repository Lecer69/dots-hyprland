import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property string label: "Balanced"
    property string description: ""
    property color accent: "#89b4fa"
    property bool selected: false

    signal clicked()

    Layout.fillWidth: true
    height: 52
    radius: 10
    color: selected ? Qt.rgba(accentR(), accentG(), accentB(), 0.12) : (hover.containsMouse ? "#1a1a1a" : "transparent")
    border.color: selected ? root.accent : "#2a2a2a"
    border.width: selected ? 1.5 : 1

    function accentR() { return root.accent.r }
    function accentG() { return root.accent.g }
    function accentB() { return root.accent.b }

    Behavior on color {
        ColorAnimation { duration: 100 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        spacing: 12

        Rectangle {
            width: 9
            height: 9
            radius: 4.5
            color: root.selected ? root.accent : "#3a3a3a"
            Layout.alignment: Qt.AlignVCenter

            Behavior on color {
                ColorAnimation { duration: 100 }
            }
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: root.label
                color: root.selected ? "#eeeeee" : "#bbbbbb"
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                visible: root.description.length > 0
                text: root.description
                color: "#777777"
                font.pixelSize: 11
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Text {
            visible: root.selected
            text: "✓"
            color: root.accent
            font.pixelSize: 13
            font.bold: true
        }
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}