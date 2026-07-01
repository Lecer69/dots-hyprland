import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

QtObject {
    id: root

    readonly property var _palette: ["#89b4fa", "#a6e3a1", "#f9e2af", "#cba6f7", "#f38ba8", "#94e2d5", "#fab387", "#89dceb"]

    property string activeApp: ""
    property string todayKey: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property var sessionTotals: ({})
    property int currentSessionSecs: 0
    property var history: ({})
    property bool _loaded: false
    property int _tickSeconds: 0
    property Connections _hyprConn

    _hyprConn: Connections {
        function onRawEvent(event) {
            if (event.name === "activewindow") {
                var idx = event.data.indexOf(",");
                root.activeApp = idx >= 0 ? event.data.substring(0, idx) : event.data;
            }
        }

        target: Hyprland
    }

    property Timer _ticker

    _ticker: Timer {
        interval: 1000
        repeat: true
        running: root._loaded
        onTriggered: {
            if (root.activeApp !== "") {
                var t = root.sessionTotals;
                t[root.activeApp] = (t[root.activeApp] || 0) + 1;
                root.sessionTotals = t; // reassign to trigger change signal
                root.currentSessionSecs = t[root.activeApp];
            } else {
                root.currentSessionSecs = 0;
            }
            root._tickSeconds++;
            if (root._tickSeconds % 30 === 0)
                root._flush();

        }
    }

    property string _configPath: ""
    property Process _resolveHome

    _resolveHome: Process {
        id: resolveHome

        command: ["bash", "-c", "echo -n $HOME/.config/lis/wellbeing.json"]
        running: true
        onExited: function() {
            mkdirProc.running = true;
        }

        stdout: SplitParser {
            onRead: function(line) {
                root._configPath = line;
            }
        }
    }

    property Process _mkdirProc

    _mkdirProc: Process {
        id: mkdirProc

        running: false
        command: ["bash", "-c", "mkdir -p $HOME/.config/lis"]
        onExited: function() {
            loadProc.running = true;
        }
    }

    property Process _loadProc

    _loadProc: Process {
        id: loadProc

        property string _buf: ""

        running: false
        command: ["bash", "-c", "cat \"$HOME/.config/lis/wellbeing.json\" 2>/dev/null || echo '{}'"]
        onRunningChanged: {
            if (running)
                _buf = "";
        }

        onExited: function() {
            try {
                root.history = JSON.parse(loadProc._buf.trim());
            } catch (e) {
                root.history = {
                };
            }
            root._loaded = true;
        }

        stdout: SplitParser {
            onRead: function(line) {
                loadProc._buf += line + "\n";
            }
        }
    }

    property Process _writeProc

    _writeProc: Process {
        id: writeProc

        running: false
        command: []
    }

    function todayTotals() {
        var base = Object.assign({}, history[todayKey] || {});
        for (var app in sessionTotals) base[app] = (base[app] || 0) + sessionTotals[app]
        return base;
    }

    function weekTotals() {
        var out = {
        };
        var now = new Date();
        for (var i = 0; i < 7; i++) {
            var d = new Date(now);
            d.setDate(d.getDate() - i);
            var key = Qt.formatDate(d, "yyyy-MM-dd");
            var day = (key === todayKey) ? todayTotals() : (history[key] || {
            });
            for (var app in day) out[app] = (out[app] || 0) + day[app]
        }
        return out;
    }

    // Returns totals for one specific calendar day (yyyy-MM-dd key)
    function dayTotals(dayKey) {
        if (dayKey === todayKey)
            return todayTotals();

        return history[dayKey] || {
        };
    }

    // Returns the 7 dates of the current week
    function weekDays() {
        var now = new Date();
        var dow = now.getDay(); // 0 = Sunday .. 6 = Saturday
        var mondayOffset = (dow === 0) ? -6 : (1 - dow);
        var monday = new Date(now);
        monday.setDate(monday.getDate() + mondayOffset);

        var out = [];
        for (var i = 0; i < 7; i++) {
            var d = new Date(monday);
            d.setDate(d.getDate() + i);
            var key = Qt.formatDate(d, "yyyy-MM-dd");
            var isToday = key === todayKey;
            var dayData = isToday ? todayTotals() : (history[key] || {
            });
            var recorded = isToday || Object.keys(dayData).length > 0;
            out.push({
                "key": key,
                "label": Qt.formatDate(d, "ddd"),
                "dayNum": Qt.formatDate(d, "d"),
                "date": d,
                "isToday": isToday,
                "hasData": recorded
            });
        }
        return out;
    }

    function formatTime(secs) {
        if (!secs || secs <= 0)
            return "0s";

        if (secs < 60)
            return secs + "s";

        if (secs < 3600)
            return Math.floor(secs / 60) + "m";

        var h = Math.floor(secs / 3600);
        var m = Math.floor((secs % 3600) / 60);
        return m > 0 ? (h + "h " + m + "m") : (h + "h");
    }

    function sortedApps(totalsObj) {
        var arr = [];
        for (var k in totalsObj) if (totalsObj[k] > 0) {
            arr.push({
            "name": k,
            "secs": totalsObj[k]
        });
        }
        arr.sort(function(a, b) {
            return b.secs - a.secs;
        });
        return arr;
    }

    function appColor(name) {
        if (!name || name.length === 0) return "#89b4fa"
        var hash = 0
        for (var i = 0; i < name.length; i++)
            hash = (hash * 31 + name.charCodeAt(i)) & 0x7fffffff
        return _palette[hash % _palette.length]
    }

    function _flush() {
        if (_configPath === "")
            return ;

        var snap = root.history;
        var day = Object.assign({}, snap[root.todayKey] || {});
        for (var app in root.sessionTotals) day[app] = (day[app] || 0) + root.sessionTotals[app]
        snap = Object.assign({}, snap);
        snap[root.todayKey] = day;

        // prune >35 days
        var cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - 35);
        for (var k in snap) {
            if (new Date(k) < cutoff)
                delete snap[k];

        }
        var json = JSON.stringify(snap);
        var escaped = json.replace(/'/g, "'\\''");
        writeProc.command = ["bash", "-c", "printf '%s' '" + escaped + "' > \"" + root._configPath + "\""];
        writeProc.running = false;
        writeProc.running = true;
        root.history = snap;
        root.sessionTotals = {};
        root.todayKey = Qt.formatDate(new Date(), "yyyy-MM-dd");
    }

    onActiveAppChanged: {
        currentSessionSecs = activeApp !== "" ? (sessionTotals[activeApp] || 0) : 0;
    }

    Component.onDestruction: {
        _flush();
    }
}