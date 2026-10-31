import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// An app playing or recording audio
ColumnLayout {
    id: root

    required property var node
    property bool input: false

    readonly property var props: node.properties ?? {}
    readonly property string appName: props["application.name"] || node.description || node.name
    // What it's playing, when that says more than the app's name
    readonly property string mediaName: {
        const name = props["media.name"] ?? ""
        return name === root.appName ? "" : name
    }
    readonly property real volume: node.audio ? node.audio.volume : 0
    readonly property bool muted: node.audio ? node.audio.muted : false

    Keys.onPressed: event => {
        if (event.key !== Qt.Key_M || !root.node.audio)
            return
        root.node.audio.muted = !root.muted
        event.accepted = true
    }
    readonly property string iconPath: {
        const names = [props["application.icon-name"], props["application.process.binary"], (props["application.name"] ?? "").toLowerCase()]
        for (const name of names) {
            const path = name ? Quickshell.iconPath(name, true) : ""
            if (path !== "") return path
        }
        return ""
    }

    spacing: 4

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Icon {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            sourceSize: Qt.size(32, 32)
            mipmap: true
            fillMode: Image.PreserveAspectFit
            source: root.iconPath !== "" ? root.iconPath : "../icons/" + (root.input ? "mic-on" : "speaker-high") + ".svg"
            tint: root.iconPath === ""
            opacity: root.muted ? 0.3 : muteArea.containsMouse ? 1 : root.iconPath !== "" ? 0.9 : 0.6

            MouseArea {
                id: muteArea

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.node.audio) root.node.audio.muted = !root.muted
            }
        }

        Text {
            Layout.preferredWidth: Math.min(implicitWidth, 200)
            elide: Text.ElideRight
            text: root.appName
            color: root.muted ? Theme.textDim : Theme.text
            font.pixelSize: 13
        }

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: root.mediaName
            color: Theme.textDim
            font.pixelSize: 12
        }

        Text {
            text: root.muted ? "Muted" : Math.round(root.volume * 100) + "%"
            color: Theme.adapt("#999999")
            font.pixelSize: 12
        }
    }

    PanelSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 28
        value: root.volume
        opacity: root.muted ? 0.4 : 1
        onMoved: v => {
            if (!root.node.audio) return
            root.node.audio.volume = v
            if (root.muted && v > 0) root.node.audio.muted = false
        }
    }
}
