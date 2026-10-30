import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.tools

// The desktop overview's content
Item {
    id: root

    required property SystemStats stats
    property bool shown: false
    // Space the bar keeps, [left, top, right, bottom]
    property var reserved: [0, 0, 0, 0]

    readonly property real cardWidth: Math.min(360, Math.floor((area.width - 64 - 2 * 16) / 3))

    signal todoRequested()
    signal calendarRequested()

    property bool _ready: false

    Component.onCompleted: _ready = true

    opacity: root.shown && root._ready ? 1 : 0

    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    SystemClock {
        id: clock

        precision: SystemClock.Minutes
    }

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.65
    }

    Item {
        id: area

        anchors.fill: parent
        anchors.leftMargin: root.reserved[0] ?? 0
        anchors.topMargin: root.reserved[1] ?? 0
        anchors.rightMargin: root.reserved[2] ?? 0
        anchors.bottomMargin: root.reserved[3] ?? 0

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0

            transform: Translate {
                y: (1 - root.opacity) * 12
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: "#e6e6e6"
                font.pixelSize: 108
                font.weight: Font.Light
                font.letterSpacing: -2
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(clock.date, "dddd, MMMM d").toUpperCase()
                color: dateArea.containsMouse ? "#e6e6e6" : "#b3b3b3"
                font.pixelSize: 16
                font.letterSpacing: 2

                MouseArea {
                    id: dateArea

                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.calendarRequested()
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 48
                Layout.preferredHeight: Math.max(400, system.implicitHeight, today.implicitHeight)
                spacing: 16

                TasksCard {
                    Layout.preferredWidth: root.cardWidth
                    Layout.fillHeight: true
                    onOpenRequested: root.todoRequested()
                }

                SystemCard {
                    id: system

                    Layout.preferredWidth: root.cardWidth
                    Layout.fillHeight: true
                    stats: root.stats
                }

                TodayCard {
                    id: today

                    Layout.preferredWidth: root.cardWidth
                    Layout.fillHeight: true
                    now: clock.date
                }
            }

            NowPlaying {
                id: nowPlaying

                Layout.fillWidth: true
                Layout.topMargin: 16
                visible: nowPlaying.player !== null
            }
        }
    }
}
