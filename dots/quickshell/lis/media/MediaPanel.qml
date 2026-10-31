import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.settings.data
import qs.common

// Now playing; music players get the cover-coloured shader look, everything else the plain one
Item {
    id: root

    property var player: null
    property bool shown: false
    signal closeRequested()

    readonly property bool hasPlayer: player !== null
    readonly property bool playing: !!(root.player && root.player.isPlaying)
    readonly property string artUrl: root.player ? root.player.trackArtUrl : ""
    readonly property real contentHeight: content.implicitHeight + content.anchors.margins * 2

    // Matched against desktop entry, name and D-Bus name
    readonly property var musicPlayers: ["spotify", "spotube", "ncspot", "rhythmbox", "elisa", "amarok",
        "strawberry", "clementine", "lollypop", "cider", "tidal", "youtube-music", "youtubemusic", "deezer",
        "deadbeef", "audacious", "cmus", "mpd", "quodlibet", "amberol", "tauon", "feishin", "sonixd",
        "nuclear", "harmonoid", "g4music", "gapless", "musikcube", "plexamp", "museeks", "kew"]
    readonly property bool fancy: {
        if (!root.player)
            return false
        const names = [root.player.desktopEntry, root.player.identity, root.player.dbusName]
            .map(n => (n ?? "").toLowerCase())
        return root.musicPlayers.some(m => names.some(n => n.includes(m)))
    }
    // The cover's colour, or plain grey
    readonly property color accent: root.fancy ? palette.accent : Theme.text

    // The bass, smoothed
    property real energy: spectrum.bass
    Behavior on energy { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

    // 0 → 1 on a track change
    property real pop: 1
    readonly property string trackKey: root.player ? (root.player.trackTitle + "|" + root.player.trackArtist) : ""
    onTrackKeyChanged: if (root.shown) trackPop.restart()

    NumberAnimation {
        id: trackPop

        target: root
        property: "pop"
        from: 0
        to: 1
        duration: 520
        easing.type: Easing.OutBack
        easing.overshoot: 1.2
    }

    function cycleLoop(): void {
        if (!root.player || !root.player.canLoop) return
        const s = root.player.loopState
        if (s === MprisLoopState.None) root.player.loopState = MprisLoopState.Playlist
        else if (s === MprisLoopState.Playlist) root.player.loopState = MprisLoopState.Track
        else root.player.loopState = MprisLoopState.None
    }

    // The cover backdrop stays dark in light mode
    function tone(c): color {
        return root.fancy ? c : Theme.adapt(c)
    }

    // A focused button takes Space for itself
    Keys.onSpacePressed: if (root.player && root.player.canTogglePlaying) root.player.togglePlaying()
    Keys.onLeftPressed: if (root.player && root.player.canGoPrevious) root.player.previous()
    Keys.onRightPressed: if (root.player && root.player.canGoNext) root.player.next()

    opacity: shown ? 1 : 0
    scale: shown ? 1 : 0.96
    transformOrigin: Item.Top
    Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    ArtPalette {
        id: palette

        source: cover
        active: root.shown && root.fancy
        fallback: SettingsData.s.general.accentColor
    }

    AudioSpectrum {
        id: spectrum

        running: root.shown && root.playing && root.fancy
    }

    onShownChanged: {
        if (root.shown) {
            // Once the window exists
            Qt.callLater(palette.refresh)
            if (root.player) {
                root.player.positionChanged()
                root.currentPos = root.player.position
            }
        }
    }

    ClippingRectangle {
        id: card

        anchors.fill: parent
        radius: root.fancy ? 14 : 12
        color: root.fancy ? "#0c0c0c" : Theme.panel
        border.width: 1
        border.color: root.fancy ? "#1affffff" : Theme.border

        // Click shield
        MouseArea {
            anchors.fill: parent
            onClicked: mouse => mouse.accepted = true
        }

        Image {
            id: backdropArt

            anchors.fill: parent
            anchors.margins: -48
            source: root.artUrl
            sourceSize: Qt.size(160, 160)
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: backdropArt
            source: backdropArt
            blurEnabled: true
            blur: 1
            blurMax: 64
            saturation: 0.2
            brightness: -0.38
            visible: root.fancy
            opacity: backdropArt.status === Image.Ready ? 0.9 : 0

            Behavior on opacity { NumberAnimation { duration: 500 } }
        }

        // Slower while paused
        ShaderEffect {
            id: flow

            anchors.fill: parent
            visible: root.fancy
            opacity: root.playing ? 0.95 : 0.55
            fragmentShader: "shaders/aurora.frag.qsb"

            property real time: 0
            property real energy: root.energy
            property point resolution: Qt.point(width, height)
            property color color1: palette.deep
            property color color2: palette.mid
            property color color3: palette.light

            Behavior on opacity { NumberAnimation { duration: 600 } }

            FrameAnimation {
                running: root.shown && root.fancy
                onTriggered: flow.time += frameTime * (root.playing ? 1 : 0.3)
            }
        }

        // Darker at the bottom, so the controls read on any cover
        Rectangle {
            anchors.fill: parent
            visible: root.fancy
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#260c0c0c" }
                GradientStop { position: 0.5; color: "#400c0c0c" }
                GradientStop { position: 1.0; color: "#e60c0c0c" }
            }
        }

        ColumnLayout {
            id: content

            anchors.fill: parent
            anchors.margins: 18
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                spacing: 8

                Rectangle {
                    id: liveDot

                    Layout.alignment: Qt.AlignVCenter
                    width: 5
                    height: 5
                    radius: 2.5
                    color: root.playing ? root.accent : root.tone("#80ffffff")

                    SequentialAnimation on opacity {
                        running: root.playing && root.shown
                        loops: Animation.Infinite
                        onRunningChanged: if (!running) liveDot.opacity = 1
                        NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.hasPlayer ? (root.player.identity || "Media") : "Now Playing"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.4
                    color: root.tone("#b3ffffff")
                }

                Text {
                    text: "✕"
                    font.pixelSize: 11
                    color: closeArea.containsMouse ? root.tone("#ffffff") : root.tone("#80ffffff")

                    MouseArea {
                        id: closeArea

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.closeRequested()
                    }
                }
            }

            RowLayout {
                visible: root.hasPlayer
                Layout.fillWidth: true
                spacing: 15

                Item {
                    id: coverBox

                    // The plain panel leaves out an empty cover
                    visible: root.fancy || root.artUrl !== ""
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: 108
                    Layout.preferredHeight: 108

                    scale: !root.fancy ? 1 : (0.88 + 0.12 * root.pop) * (root.playing ? 1 + 0.035 * root.energy : 0.97)
                    opacity: root.fancy ? Math.min(1, root.pop) : 1

                    Behavior on scale {
                        enabled: !trackPop.running
                        NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
                    }

                    Rectangle {
                        id: coverGlowSource

                        anchors.fill: parent
                        anchors.margins: 5
                        radius: 12
                        color: palette.accent
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: coverGlowSource
                        source: coverGlowSource
                        autoPaddingEnabled: true
                        blurEnabled: true
                        blur: 1
                        blurMax: 32
                        visible: root.fancy
                        opacity: cover.status === Image.Ready ? 0.35 + 0.35 * root.energy : 0
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: 10
                        color: root.tone("#1affffff")

                        Image {
                            id: cover

                            anchors.fill: parent
                            source: root.artUrl
                            sourceSize: Qt.size(512, 512)
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            opacity: status === Image.Ready ? 1 : 0
                            onStatusChanged: if (status === Image.Ready) palette.refresh()

                            Behavior on opacity { NumberAnimation { duration: 300 } }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: cover.status !== Image.Ready
                            text: "♪"
                            font.pixelSize: 28
                            color: root.tone("#4dffffff")
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: !!(root.player && root.player.canRaise)
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: root.player.raise()
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: coverBox.visible ? 108 : -1
                    spacing: 0

                    Item {
                        visible: !root.fancy
                        Layout.fillHeight: true
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        opacity: root.fancy ? Math.min(1, root.pop) : 1

                        transform: Translate { y: root.fancy ? (1 - root.pop) * 10 : 0 }

                        Text {
                            Layout.fillWidth: true
                                                elide: Text.ElideRight
                            text: root.player ? (root.player.trackTitle || "Unknown Title") : ""
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: root.tone("#ffffff")
                        }

                        Text {
                            Layout.fillWidth: true
                                                elide: Text.ElideRight
                            visible: text !== ""
                            text: root.player ? (root.player.trackArtist || "") : ""
                            font.pixelSize: 12
                            font.weight: Font.Medium
                            color: root.fancy ? Qt.lighter(palette.accent, 1.25) : root.tone("#999999")
                        }

                        Text {
                            Layout.fillWidth: true
                                                elide: Text.ElideRight
                            visible: text !== ""
                            text: root.player ? (root.player.trackAlbum || "") : ""
                            font.pixelSize: 11
                            color: root.tone("#80ffffff")
                        }
                    }

                    Item {
                        id: spectrumView

                        visible: root.fancy
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 6
                        Layout.minimumHeight: 26

                        readonly property real gap: 2.5
                        readonly property real barWidth: (width - gap * (spectrum.bars - 1)) / spectrum.bars

                        Row {
                            anchors.fill: parent
                            spacing: spectrumView.gap

                            Repeater {
                                model: spectrum.bars

                                Rectangle {
                                    required property int index
                                    readonly property real level: spectrum.levels[index] ?? 0

                                    anchors.verticalCenter: parent.verticalCenter
                                    width: spectrumView.barWidth
                                    height: Math.max(width, level * spectrumView.height)
                                    radius: width / 2
                                    color: root.accent
                                    opacity: 0.3 + 0.7 * level

                                    Behavior on height { NumberAnimation { duration: 70 } }
                                }
                            }
                        }
                    }

                    Item {
                        visible: !root.fancy
                        Layout.fillHeight: true
                    }
                }
            }

            Item {
                id: seekBlock

                visible: root.hasPlayer
                Layout.fillWidth: true
                Layout.topMargin: 15
                Layout.preferredHeight: 28

                property bool scrubbing: false
                property real scrubPos: 0
                readonly property real displayPos: scrubbing ? scrubPos : root.currentPos
                readonly property real length: root.player && root.player.lengthSupported ? root.player.length : 0
                readonly property bool seekable: !!(root.player && root.player.canSeek && seekBlock.length > 0)
                readonly property bool hot: seekMouse.containsMouse || seekBlock.scrubbing

                Item {
                    id: barArea

                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 10

                    Rectangle {
                        id: track

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: seekBlock.hot ? 5 : 3.5
                        radius: height / 2
                        color: root.tone("#26ffffff")
                        opacity: seekBlock.seekable ? 1 : 0.4

                        Behavior on height { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                        Rectangle {
                            id: fill

                            height: parent.height
                            radius: height / 2
                            width: seekBlock.length > 0 ? parent.width * Math.min(1, seekBlock.displayPos / seekBlock.length) : 0
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.fancy ? Qt.darker(root.accent, 1.3) : root.tone("#bbbbbb") }
                                GradientStop { position: 1.0; color: root.fancy ? Qt.lighter(root.accent, 1.15) : root.tone("#bbbbbb") }
                            }

                            Behavior on width {
                                enabled: !seekBlock.scrubbing
                                NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                            }
                        }

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: root.tone("#ffffff")
                            border.width: 2.5
                            border.color: root.accent
                            anchors.verticalCenter: parent.verticalCenter
                            x: fill.width - width / 2
                            visible: seekBlock.seekable
                            opacity: seekBlock.hot ? 1 : 0
                            scale: seekBlock.scrubbing ? 1.15 : 1

                            Behavior on opacity { NumberAnimation { duration: 120 } }
                            Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }

                    MouseArea {
                        id: seekMouse

                        anchors.fill: parent
                        anchors.topMargin: -6
                        anchors.bottomMargin: -6
                        enabled: seekBlock.seekable
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                        function posFromX(x: real): real {
                            return Math.max(0, Math.min(seekBlock.length, (x / width) * seekBlock.length))
                        }

                        onPressed: mouse => {
                            seekBlock.scrubbing = true
                            seekBlock.scrubPos = posFromX(mouse.x)
                        }
                        onPositionChanged: mouse => {
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
                    anchors.topMargin: 5
                    text: root.formatTime(seekBlock.displayPos)
                    font.pixelSize: 10
                    font.features: ({ "tnum": 1 })
                    color: root.tone("#b3ffffff")
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: barArea.bottom
                    anchors.topMargin: 5
                    text: seekBlock.length > 0 ? root.formatTime(seekBlock.length) : "--:--"
                    font.pixelSize: 10
                    font.features: ({ "tnum": 1 })
                    color: root.tone("#80ffffff")
                }
            }

            RowLayout {
                visible: root.hasPlayer
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 3
                spacing: 12

                TransportButton {
                    size: 29
                    iconSize: 13
                    icon: "shuffle"
                    active: !!(root.player && root.player.shuffle)
                    enabled: !!(root.player && root.player.canShuffle)
                    activeColor: root.tone("#1fffffff")
                    hoverColor: root.tone("#1affffff")
                    iconColor: root.tone("#b3ffffff")
                    activeIconColor: root.fancy ? root.accent : root.tone("#ffffff")
                    onClicked: root.player.shuffle = !root.player.shuffle
                }

                TransportButton {
                    size: 36
                    iconSize: 15
                    icon: "prev"
                    enabled: !!(root.player && root.player.canGoPrevious)
                    hoverColor: root.tone("#1affffff")
                    iconColor: root.tone("#e6ffffff")
                    onClicked: root.player.previous()
                }

                TransportButton {
                    size: 49
                    iconSize: 19
                    accent: true
                    icon: "play"
                    iconAlt: "pause"
                    useAlt: root.playing
                    enabled: !!(root.player && root.player.canTogglePlaying)
                    accentColor: root.accent
                    accentIconColor: root.tone("#0c0c0c")
                    transform: Scale {
                        origin.x: 24.5
                        origin.y: 24.5
                        xScale: 1 + 0.06 * root.energy
                        yScale: 1 + 0.06 * root.energy
                    }
                    onClicked: root.player.togglePlaying()
                }

                TransportButton {
                    size: 36
                    iconSize: 15
                    icon: "next"
                    enabled: !!(root.player && root.player.canGoNext)
                    hoverColor: root.tone("#1affffff")
                    iconColor: root.tone("#e6ffffff")
                    onClicked: root.player.next()
                }

                TransportButton {
                    size: 29
                    iconSize: 13
                    icon: "repeat"
                    iconAlt: "repeat-one"
                    useAlt: !!(root.player && root.player.loopState === MprisLoopState.Track)
                    active: !!(root.player && root.player.loopState !== MprisLoopState.None)
                    enabled: !!(root.player && root.player.canLoop)
                    activeColor: root.tone("#1fffffff")
                    hoverColor: root.tone("#1affffff")
                    iconColor: root.tone("#b3ffffff")
                    activeIconColor: root.fancy ? root.accent : root.tone("#ffffff")
                    onClicked: root.cycleLoop()
                }
            }

            Text {
                visible: !root.hasPlayer
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "Nothing playing"
                font.pixelSize: 12
                color: root.tone("#80ffffff")
            }
        }
    }

    property real currentPos: root.player ? root.player.position : 0

    onPlayerChanged: root.currentPos = root.player ? root.player.position : 0

    Timer {
        interval: 500
        repeat: true
        running: root.shown && root.playing
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
