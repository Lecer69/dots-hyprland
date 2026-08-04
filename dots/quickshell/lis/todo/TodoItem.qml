import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property real taskId: -1
    property string text: ""
    property bool done: false
    property bool important: false
    property real dragY: 0

    signal toggleDone()
    signal toggleImportant()
    signal removeRequested()
    signal dragStarted()
    signal dragMoved(real y)
    signal dragEnded()

    property bool dragging: false

    width: parent ? parent.width : 0
    height: 44
    radius: 8
    color: dragging ? "#1c1c1c" : (rowHover.hovered ? "#161616" : "transparent")
    border.color: dragging ? "#333333" : "transparent"
    border.width: 1
    z: dragging ? 10 : 0

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }

    HoverHandler {
        id: rowHover
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 8
        anchors.rightMargin: 8
        spacing: 10

        // Drag handle
        Item {
            Layout.preferredWidth: 18
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 3

                Repeater {
                    model: 3
                    Row {
                        spacing: 3
                        Rectangle { width: 3; height: 3; radius: 1.5; color: "#555555" }
                        Rectangle { width: 3; height: 3; radius: 1.5; color: "#555555" }
                    }
                }
            }

            MouseArea {
                id: dragArea

                anchors.fill: parent
                cursorShape: Qt.SizeVerCursor
                hoverEnabled: true
                onPressed: {
                    root.dragging = true;
                    root.dragStarted();
                }
                onPositionChanged: (mouse) => {
                    if (pressed) {
                        const globalPos = mapToItem(root.parent, mouse.x, mouse.y);
                        root.dragMoved(globalPos.y);
                    }
                }
                onReleased: {
                    root.dragging = false;
                    root.dragEnded();
                }
            }
        }

        // Checkbox
        Rectangle {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: width / 2
            color: root.done ? "#60ff54" : "transparent"
            border.color: root.done ? "#60ff54" : "#444444"
            border.width: 1.5

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.toggleDone();
                }
            }
        }

        // Task text
        Text {
            Layout.fillWidth: true
            text: root.text
            color: root.done ? "#555555" : "#dddddd"
            font.pixelSize: 13
            font.strikeout: root.done
            elide: Text.ElideRight
        }

        // Star / important
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: starHover.containsMouse ? "#252525" : "transparent"

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: width / 2
                color: root.important ? "#ffc900" : "transparent"
                border.color: root.important ? "#ffc900" : "#666666"
                border.width: 1.5
            }

            MouseArea {
                id: starHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.toggleImportant();
                }
            }
        }

        // Delete
        Rectangle {
            Layout.preferredWidth: 26
            Layout.preferredHeight: 26
            radius: 13
            color: delHover.containsMouse ? "#4e1919" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 11
                color: delHover.containsMouse ? "#f38ba8" : "#666666"
            }

            MouseArea {
                id: delHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.removeRequested();
                }
            }
        }
    }
}
