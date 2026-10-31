import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import qs.media
import qs.common

// The playing track, else the last one paused
Rectangle {
    id: root

    readonly property var player: {
        const players = Mpris.players.values.filter(p => p && (p.trackTitle || p.trackArtist));
        return players.find(p => p.isPlaying) ?? players[0] ?? null;
    }

    implicitHeight: 56
    radius: 12
    color: Theme.panel
    border.color: Theme.border
    border.width: 1

    // Keeps clicks from the desktop behind
    MouseArea {
        anchors.fill: parent
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 24
        spacing: 16

        Row {
            spacing: 2

            TransportButton {
                size: 32
                iconSize: 14
                icon: "prev"
                enabled: !!root.player?.canGoPrevious
                onClicked: root.player?.previous()
            }

            TransportButton {
                size: 32
                iconSize: 14
                icon: "play"
                iconAlt: "pause"
                useAlt: !!root.player?.isPlaying
                enabled: !!root.player?.canTogglePlaying
                onClicked: root.player?.togglePlaying()
            }

            TransportButton {
                size: 32
                iconSize: 14
                icon: "next"
                enabled: !!root.player?.canGoNext
                onClicked: root.player?.next()
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.player?.trackTitle || "Unknown title"
            elide: Text.ElideRight
            color: Theme.text
            font.pixelSize: 13
        }

        Text {
            Layout.maximumWidth: root.width / 3
            text: root.player?.trackArtist ?? ""
            elide: Text.ElideRight
            color: Theme.adapt("#999999")
            font.pixelSize: 12
        }
    }
}
