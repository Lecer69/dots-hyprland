import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import qs.settings.data

Item {
    id: root

    property var screen: null

    readonly property var rawActivePlayer: {
        const players = Mpris.players.values
        let playing = null
        let any = null
        for (let i = 0; i < players.length; i++) {
            const p = players[i]
            if (!p) continue
            if (p.trackTitle === "" && p.trackArtist === "") continue
            if (any === null) any = p
            if (p.isPlaying) { playing = p; break }
        }
        return playing ?? any
    }

    readonly property int idleTimeoutMs: 300000

    property var activePlayer: null
    property string idleKey: ""
    property real lastPosition: -1
    property real idleElapsedMs: 0

    function playerKey(p) {
        if (!p) return ""
        return (p.trackTitle || "") + "|" + (p.trackArtist || "") + "|" + (p.identity || "")
    }

    function syncPlayer() {
        const p = root.rawActivePlayer
        const key = playerKey(p)

        // Track (or player) changed — reset idle tracking.
        if (key !== root.idleKey) {
            root.idleKey = key
            root.idleElapsedMs = 0
            root.lastPosition = p ? p.position : -1
            root.activePlayer = p
            return
        }

        if (!p) {
            root.activePlayer = null
            return
        }

        if (p.isPlaying) {
            root.idleElapsedMs = 0
        } else if (p.position === root.lastPosition) {
            root.idleElapsedMs += idleCheckTimer.interval
        } else {
            root.idleElapsedMs = 0
        }

        root.lastPosition = p.position

        root.activePlayer = (root.idleElapsedMs >= root.idleTimeoutMs) ? null : p
    }

    Timer {
        id: idleCheckTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.syncPlayer()
    }

    Connections {
        target: Mpris
        function onPlayersChanged() { root.syncPlayer() }
    }

    Component.onCompleted: root.syncPlayer()

    readonly property bool hasMedia: activePlayer !== null
    property bool panelOpen: false

    visible: hasMedia
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 7

        Item {
            id: spinner
            Layout.preferredWidth: 15
            Layout.preferredHeight: 15
            Layout.alignment: Qt.AlignVCenter

            property bool playing: root.activePlayer ? root.activePlayer.isPlaying : false

            opacity: playing ? 1.0 : 0.4
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: "#3c3c3c"
            }

            Item {
                id: orbit
                anchors.fill: parent

                Rectangle {
                    width: 4
                    height: 4
                    radius: 2
                    color: SettingsData.s.general.accentColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: -0.5
                }

                RotationAnimation {
                    target: orbit
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 1300
                    loops: Animation.Infinite
                    running: spinner.playing
                }
            }
        }

        Text {
            Layout.maximumWidth: 220
            elide: Text.ElideRight
            text: {
                if (!root.activePlayer) return ""
                const t = root.activePlayer.trackTitle || "Unknown Title"
                const a = root.activePlayer.trackArtist
                return a ? (a + " – " + t) : t
            }
            font.pixelSize: 11
            font.weight: Font.Medium
            color: "#cdd6f4"
            verticalAlignment: Text.AlignVCenter
        }
    }

    MouseArea {
        anchors.fill: row
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 10
        onClicked: root.panelOpen = !root.panelOpen
    }

    Loader {
        active: root.screen !== null
        sourceComponent: MediaWindow {
            player: root.activePlayer
            shown: root.panelOpen
            anchorItem: root
            screen: root.screen
            onCloseRequested: root.panelOpen = false
        }
    }
}
