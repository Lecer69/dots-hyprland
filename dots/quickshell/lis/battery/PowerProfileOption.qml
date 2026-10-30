import QtQuick
import QtQuick.Layouts
import qs.common

Rectangle {
    id: root

    property string label: "Balanced"
    property string description: ""
    property bool selected: false

    signal clicked()

    Layout.fillWidth: true
    height: 52
    radius: 8
    color: selected ? (root.activeFocus ? "#262626" : "#1f1f1f")
        : (hover.containsMouse || root.activeFocus ? "#161616" : "transparent")

    readonly property bool listRow: true
    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: root.clicked()
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: root.selected ? "#e6e6e6" : "#3a3a3a"
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            spacing: 2
            Layout.fillWidth: true

            Text {
                text: root.label
                color: root.selected ? "#ffffff" : "#e6e6e6"
                font.pixelSize: 13
            }

            Text {
                visible: root.description.length > 0
                text: root.description
                color: "#6b6b6b"
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
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