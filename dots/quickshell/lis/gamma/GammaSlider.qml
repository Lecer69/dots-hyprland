import QtQuick
import QtQuick.Layouts
import qs.common

ColumnLayout {
    id: root

    property string label: "Label"
    property real value: 1
    readonly property real from: 0.1
    readonly property real to: 2

    signal moved(real value)
    signal released(real value)

    spacing: 6
    Layout.fillWidth: true

    // Like a drag; releasing the key is the release
    function stepped(direction: int): real {
        return Math.round(Math.max(root.from, Math.min(root.to, root.value + direction * 0.02)) * 100) / 100
    }

    activeFocusOnTab: true
    Keys.onLeftPressed: root.moved(root.stepped(-1))
    Keys.onRightPressed: root.moved(root.stepped(1))
    Keys.onReleased: event => {
        if ((event.key === Qt.Key_Left || event.key === Qt.Key_Right) && !event.isAutoRepeat)
            root.released(root.value)
    }

    RowLayout {
        Layout.fillWidth: true

        Text {
            text: root.label
            color: Theme.text
            font.pixelSize: 13
            Layout.fillWidth: true
        }

        Text {
            text: root.value.toFixed(2)
            color: Theme.adapt("#999999")
            font.pixelSize: 12
        }

    }

    Item {
        Layout.fillWidth: true
        implicitHeight: 20

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            height: 3
            radius: 1.5
            color: Theme.adapt("#2a2a2a")
        }

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: handle.x + handle.width / 2
            height: 3
            radius: 1.5
            color: root.activeFocus ? Theme.adapt("#ffffff") : Theme.adapt("#bbbbbb")
        }

        Rectangle {
            id: handle

            readonly property real position: (root.value - root.from) / (root.to - root.from)

            anchors.verticalCenter: parent.verticalCenter
            x: position * (parent.width - width)
            width: root.activeFocus ? 14 : 12
            height: width
            radius: width / 2
            color: Theme.adapt("#ffffff")
        }

        MouseArea {
            id: trackArea

            function valueFromX(mx) : real {
                var ratio = Math.max(0, Math.min(mx, width)) / width;
                return Math.round((root.from + ratio * (root.to - root.from)) * 100) / 100;
            }

            anchors.fill: parent
            hoverEnabled: true
            onPressed: root.moved(valueFromX(mouseX))
            onPositionChanged: {
                if (pressed) {
                    root.moved(valueFromX(mouseX));
                }
            }
            onReleased: root.released(valueFromX(mouseX))
        }

    }

}
