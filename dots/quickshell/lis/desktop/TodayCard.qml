import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.calendar
import qs.common
import qs.settings.data
import qs.tools

// This week's calendar notes, and today's screen time and data use
OverviewCard {
    id: root

    required property date now

    readonly property string todayKey: Qt.formatDate(root.now, "yyyy-MM-dd")

    // ISO 8601 week: a week belongs to the year of its Thursday
    readonly property int week: {
        const d = new Date(Date.UTC(root.now.getFullYear(), root.now.getMonth(), root.now.getDate()));
        d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
        const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
        return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
    }

    // { label, text } for today and the next 6 days
    readonly property var upcoming: {
        const list = [];
        for (let i = 0; i < 7; i++) {
            const day = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate() + i);
            const label = i === 0 ? "Today" : i === 1 ? "Tomorrow" : Qt.formatDate(day, "ddd d");
            for (const note of calendar.notesFor(day))
                list.push({ label: label, text: note.text });
        }
        return list;
    }

    // -1 until read
    property real screenTime: -1
    property real dataUsed: -1
    readonly property bool showScreenTime: SettingsData.s.tracking.wellbeingEnabled && root.screenTime >= 0
    readonly property bool showDataUsed: SettingsData.s.tracking.internetUsageEnabled && root.dataUsed >= 0

    function _sumToday(text: string): real {
        try {
            const day = JSON.parse(text)[root.todayKey] ?? {};
            return Object.values(day).reduce((sum, v) => sum + Number(v), 0);
        } catch (e) {
            return -1;
        }
    }

    title: "Today"
    subtitle: "Week " + root.week
    implicitHeight: root.headerHeight + column.implicitHeight + 24

    // Its own copy, read each time the overview opens
    CalendarState {
        id: calendar
    }

    // The trackers save every 30 s
    FileView {
        path: Quickshell.env("HOME") + "/.config/lis/wellbeing.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.screenTime = root._sumToday(text())
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/lis/internetusage.json"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.dataUsed = root._sumToday(text())
    }

    ColumnLayout {
        id: column

        width: parent.width
        spacing: 10

        Repeater {
            model: root.upcoming

            RowLayout {
                required property var modelData

                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.preferredWidth: 64
                    text: modelData.label
                    color: "#6b6b6b"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    text: modelData.text
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: "#e6e6e6"
                    font.pixelSize: 13
                }
            }
        }

        Text {
            visible: root.upcoming.length === 0
            text: "No notes this week"
            color: "#6b6b6b"
            font.pixelSize: 12
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            visible: root.showScreenTime || root.showDataUsed
            spacing: 10

            InfoRow {
                Layout.fillWidth: true
                visible: root.showScreenTime
                label: "Screen time"
                value: Format.duration(root.screenTime)
            }

            InfoRow {
                Layout.fillWidth: true
                visible: root.showDataUsed
                label: "Data used"
                value: Format.bytes(root.dataUsed * 1048576)
            }
        }
    }
}
