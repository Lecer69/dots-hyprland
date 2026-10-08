import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    property real presetId: -1
    property string name: ""
    property real gamma: 1.0
    property real brightness: 1.0
    property real contrast: 1.0
    property real saturation: 1.0

    signal applyRequested()
    signal removeRequested()

    function summary(): string {
        const parts = [];
        if (Math.abs(root.brightness - 1.0) > 0.001)
            parts.push("B " + root.brightness.toFixed(1));
        if (Math.abs(root.contrast - 1.0) > 0.001)
            parts.push("C " + root.contrast.toFixed(1));
        if (Math.abs(root.gamma - 1.0) > 0.001)
            parts.push("G " + root.gamma.toFixed(1));
        if (Math.abs(root.saturation - 1.0) > 0.001)
            parts.push("S " + root.saturation.toFixed(1));
        return parts.length > 0 ? parts.join("  ·  ") : "default";
    }

    width: parent ? parent.width : 0
    height: 56
    radius: 8
    color: rowHover.hovered ? "#161616" : "transparent"

    Behavior on color {
        ColorAnimation {
            duration: 100
        }
    }

    HoverHandler {
        id: rowHover
    }

    // Declared before the content so the delete button's MouseArea stays on top
    MouseArea {
        id: applyArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.applyRequested()
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 8
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                Layout.fillWidth: true
                text: root.name
                color: "#dddddd"
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.summary()
                color: "#555555"
                font.pixelSize: 10
                font.family: "monospace"
                elide: Text.ElideRight
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
                onClicked: root.removeRequested()
            }
        }
    }
}
