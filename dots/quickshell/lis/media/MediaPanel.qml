import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property var player: null
    property bool shown: false
    signal closeRequested()

    readonly property bool hasPlayer: player !== null
    readonly property real contentHeight: header.height + 8 + content.implicitHeight + 24

    function cycleLoop(): void {
        if (!root.player || !root.player.canLoop) return
        const s = root.player.loopState
        if (s === MprisLoopState.None) root.player.loopState = MprisLoopState.Playlist
        else if (s === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track
        else root.player.loopState = MprisLoopState.None
    }

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    // Subtle open/close animation: fade + unfold from the bar
    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.96
    transformOrigin: Item.Top

    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Click shield: absorb clicks on the panel so the backdrop doesn't close
    MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true
    }

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            id: title

            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Now Playing"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.left: title.right
            anchors.leftMargin: 8
            anchors.baseline: title.baseline
            width: Math.min(implicitWidth, 150)
            elide: Text.ElideRight
            visible: root.hasPlayer
            text: root.player && root.player.identity ? root.player.identity : "Media"
            font.pixelSize: 12
            color: "#6b6b6b"
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            font.pixelSize: 12
            color: closeHover.containsMouse ? "#dddddd" : "#666666"

            MouseArea {
                id: closeHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

    ColumnLayout {
        id: content

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 18

        // Track row: album art + info
        RowLayout {
            visible: root.hasPlayer
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 64 : 0
            spacing: 14

            Item {
                Layout.preferredWidth: 64
                Layout.preferredHeight: 64

                Rectangle {
                    id: artBase

                    anchors.fill: parent
                    radius: 8
                    color: "#161616"
                }

                Image {
                    id: art

                    anchors.fill: parent
                    source: root.player ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    visible: false
                    layer.enabled: true
                }

                Rectangle {
                    id: artMask

                    anchors.fill: parent
                    radius: 8
                    color: "white"
                    visible: false
                    layer.enabled: true
                }

                MultiEffect {
                    anchors.fill: art
                    source: art
                    maskEnabled: true
                    maskSource: artMask
                    opacity: art.status === Image.Ready ? 1 : 0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                }

                Text {
                    anchors.centerIn: parent
                    visible: art.status !== Image.Ready
                    text: "♪"
                    font.pixelSize: 20
                    color: "#4a4a4a"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: !!(root.player && root.player.canRaise)
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (root.player && root.player.canRaise) root.player.raise()
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    color: "#e6e6e6"
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.pixelSize: 12
                    color: "#999999"
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    visible: text !== ""
                    text: root.player ? (root.player.trackAlbum || "") : ""
                    font.pixelSize: 12
                    color: "#6b6b6b"
                }
            }
        }

        // Seek bar
        Item {
            id: seekBlock

            visible: root.hasPlayer
            Layout.fillWidth: true
            Layout.preferredHeight: visible ? 30 : 0

            property bool scrubbing: false
            property real scrubPos: 0
            readonly property real displayPos: scrubbing ? scrubPos : root.currentPos
            readonly property bool seekable: !!(root.player && root.player.canSeek
                && root.player.lengthSupported && root.player.length > 0)

            Item {
                id: barArea

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 10

                Rectangle {
                    id: track

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: (seekMouse.containsMouse || seekBlock.scrubbing) ? 5 : 3
                    radius: height / 2
                    color: "#2a2a2a"
                    opacity: seekBlock.seekable ? 1 : 0.4

                    Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    Rectangle {
                        id: fill

                        height: parent.height
                        radius: height / 2
                        color: "#bbbbbb"
                        width: {
                            const len = root.player && root.player.lengthSupported ? root.player.length : 0
                            if (len <= 0) return 0
                            return parent.width * Math.min(1, seekBlock.displayPos / len)
                        }

                        Behavior on width {
                            enabled: !seekBlock.scrubbing
                            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                        }
                    }

                    Rectangle {
                        id: handle

                        width: 12
                        height: 12
                        radius: 6
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                        x: fill.width - width / 2
                        visible: seekBlock.seekable
                        opacity: seekMouse.containsMouse || seekBlock.scrubbing ? 1 : 0
                        scale: seekBlock.scrubbing ? 1.15 : 1

                        Behavior on opacity { NumberAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                    }
                }

                MouseArea {
                    id: seekMouse

                    anchors.fill: parent
                    enabled: seekBlock.seekable
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    function posFromX(x: real): real {
                        const len = root.player ? root.player.length : 0
                        return Math.max(0, Math.min(len, (x / width) * len))
                    }

                    onPressed: (mouse) => {
                        seekBlock.scrubbing = true
                        seekBlock.scrubPos = posFromX(mouse.x)
                    }
                    onPositionChanged: (mouse) => {
                        if (seekBlock.scrubbing) seekBlock.scrubPos = posFromX(mouse.x)
                    }
                    onReleased: {
                        if (seekBlock.scrubbing) {
                            seekBlock.scrubbing = false
                            if (root.player) root.player.position = seekBlock.scrubPos
                        }
                    }
                }
            }

            Text {
                anchors.left: parent.left
                anchors.top: barArea.bottom
                anchors.topMargin: 6
                text: formatTime(seekBlock.displayPos)
                font.pixelSize: 11
                color: "#999999"
            }

            Text {
                anchors.right: parent.right
                anchors.top: barArea.bottom
                anchors.topMargin: 6
                text: root.player && root.player.lengthSupported ? formatTime(root.player.length) : "--:--"
                font.pixelSize: 11
                color: "#6b6b6b"
            }
        }

        // Transport controls
        RowLayout {
            visible: root.hasPlayer
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredHeight: visible ? 46 : 0
            spacing: 12

            TransportButton {
                size: 32
                iconSize: 14
                icon: "shuffle"
                active: !!(root.player && root.player.shuffle)
                enabled: !!(root.player && root.player.canShuffle)
                onClicked: if (root.player) root.player.shuffle = !root.player.shuffle
            }

            TransportButton {
                size: 38
                iconSize: 16
                icon: "prev"
                enabled: !!(root.player && root.player.canGoPrevious)
                onClicked: if (root.player) root.player.previous()
            }

            TransportButton {
                size: 46
                iconSize: 18
                accent: true
                icon: "play"
                iconAlt: "pause"
                useAlt: !!(root.player && root.player.isPlaying)
                enabled: !!(root.player && root.player.canTogglePlaying)
                onClicked: if (root.player) root.player.togglePlaying()
            }

            TransportButton {
                size: 38
                iconSize: 16
                icon: "next"
                enabled: !!(root.player && root.player.canGoNext)
                onClicked: if (root.player) root.player.next()
            }

            TransportButton {
                size: 32
                iconSize: 14
                icon: "repeat"
                iconAlt: "repeat-one"
                useAlt: !!(root.player && root.player.loopState === MprisLoopState.Track)
                active: !!(root.player && root.player.loopState !== MprisLoopState.None)
                enabled: !!(root.player && root.player.canLoop)
                onClicked: root.cycleLoop()
            }
        }

        // Empty state
        Item {
            visible: !root.hasPlayer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: visible ? 120 : 0

            Text {
                anchors.centerIn: parent
                text: "Nothing playing"
                font.pixelSize: 13
                color: "#6b6b6b"
            }
        }
    }

    property real currentPos: root.player ? root.player.position : 0

    onPlayerChanged: root.currentPos = root.player ? root.player.position : 0
    onShownChanged: {
        if (root.shown && root.player) {
            root.player.positionChanged()
            root.currentPos = root.player.position
        }
    }

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
        const h = Math.floor(s / 3600)
        const m = Math.floor((s % 3600) / 60)
        const r = s % 60
        if (h > 0) return h + ":" + (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r
        return m + ":" + (r < 10 ? "0" : "") + r
    }
}