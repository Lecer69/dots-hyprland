import QtQuick
import QtQuick.Layouts
import qs.common

// Mute toggle (the icon), volume slider and percentage for a PipeWire node
RowLayout {
    id: root

    required property var node
    property bool input: false

    readonly property real volume: node && node.audio ? node.audio.volume : 0
    readonly property bool muted: node && node.audio ? node.audio.muted : false

    spacing: 12

    Image {
        Layout.preferredWidth: 16
        Layout.preferredHeight: 16
        sourceSize: Qt.size(16, 16)
        fillMode: Image.PreserveAspectFit
        opacity: muteArea.containsMouse ? 1 : 0.7
        source: {
            if (root.input) return "../icons/" + (root.muted ? "mic-off" : "mic-on") + ".svg"
            if (root.muted) return "../icons/PiSpeakerSimpleSlashFill.svg"
            if (root.volume <= 0) return "../icons/speaker-empty.svg"
            return "../icons/" + (root.volume < 0.5 ? "speaker-low" : "speaker-high") + ".svg"
        }

        MouseArea {
            id: muteArea

            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.node && root.node.audio) root.node.audio.muted = !root.muted
        }
    }

    PanelSlider {
        Layout.fillWidth: true
        value: root.volume
        opacity: root.muted ? 0.4 : 1
        onMoved: v => {
            if (!root.node || !root.node.audio) return
            root.node.audio.volume = v
            if (root.muted && v > 0) root.node.audio.muted = false
        }
    }

    Text {
        Layout.preferredWidth: 36
        horizontalAlignment: Text.AlignRight
        text: Math.round(root.volume * 100) + "%"
        color: "#999999"
        font.pixelSize: 12
    }
}
