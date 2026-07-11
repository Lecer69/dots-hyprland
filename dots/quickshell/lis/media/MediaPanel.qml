import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.settings.data

Rectangle {
    id: root

    property var player: null
    property bool shown: false
    signal closeRequested()

    radius: 12
    color: "#151515"
    border.color: "#3e3e3e"
    border.width: 1
    clip: true

    opacity: 0

    states: State {
        name: "shown"
        when: root.shown

        PropertyChanges { target: root; opacity: 1 }
    }

    transitions: Transition {
        NumberAnimation { property: "opacity"; duration: 160; easing.type: Easing.OutCubic }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {}
        hoverEnabled: false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.preferredWidth: 52
                Layout.preferredHeight: 52

                Rectangle {
                    id: artBase
                    anchors.fill: parent
                    radius: 10
                    color: "#272727"
                }

                Image {
                    id: art
                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    opacity: 0
                    layer.enabled: true
                }

                Rectangle {
                    id: artMask
                    anchors.fill: parent
                    radius: 10
                    layer.enabled: true
                    opacity: 0
                }

                MultiEffect {
                    anchors.fill: art
                    source: art
                    visible: art.status === Image.Ready
                    maskEnabled: true
                    maskSource: artMask
                }

                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "♪"
                    font.pixelSize: 20
                    color: "#838383"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackTitle || "Unknown Title") : "Nothing playing"
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    color: "#cdd6f4"
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.pixelSize: 12
                    color: "#c8c8c8"
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: formatTime(root.currentPos)
                font.pixelSize: 10
                color: "#9f9f9f"
            }

            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: 1.5
                color: "#434343"

                Rectangle {
                    height: parent.height
                    radius: 1.5
                    color: SettingsData.s.general.accentColor
                    width: {
                        if (!root.player || !root.player.lengthSupported || root.player.length <= 0) return 0
                        return parent.width * Math.min(1, root.currentPos / root.player.length)
                    }
                    Behavior on width { NumberAnimation { duration: 200 } }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: root.player && root.player.canSeek
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: (mouse) => {
                        if (!root.player || !root.player.lengthSupported) return
                        const frac = mouse.x / width
                        root.player.position = frac * root.player.length
                    }
                }
            }

            Text {
                text: root.player && root.player.lengthSupported ? formatTime(root.player.length) : "--:--"
                font.pixelSize: 10
                color: "#9c9c9c"
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18

            TransportButton {
                icon: "prev"
                enabled: root.player && root.player.canGoPrevious
                onClicked: root.player && root.player.previous()
            }

            TransportButton {
                big: true
                icon: root.player && root.player.isPlaying ? "pause" : "play"
                enabled: root.player && root.player.canTogglePlaying
                onClicked: root.player && root.player.togglePlaying()
            }

            TransportButton {
                icon: "next"
                enabled: root.player && root.player.canGoNext
                onClicked: root.player && root.player.next()
            }
        }
    }

    property real currentPos: root.player ? root.player.position : 0

    Timer {
        interval: 500
        repeat: true
        running: root.shown && root.player && root.player.isPlaying
        onTriggered: {
            if (root.player) {
                root.player.positionChanged()
                root.currentPos = root.player.position
            }
        }
    }

    Connections {
        target: root.player
        function onPositionChanged() {
            if (root.player) root.currentPos = root.player.position
        }
    }

    function formatTime(seconds) {
        if (!seconds || seconds < 0 || isNaN(seconds)) return "0:00"
        const s = Math.floor(seconds)
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }
}
