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
        anchors.rightMargin: 10
        spacing: 8

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.name
                color: "#e6e6e6"
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.summary()
                color: "#6b6b6b"
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        // Delete
        Text {
            text: "✕"
            font.pixelSize: 11
            color: delHover.containsMouse ? "#dddddd" : "#666666"

            MouseArea {
                id: delHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.removeRequested()
            }
        }
    }
}
