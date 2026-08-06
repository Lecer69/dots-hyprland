import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings.data

QtObject {
    id: root

    readonly property var _palette: ["#89b4fa", "#a6e3a1", "#f9e2af", "#cba6f7", "#f38ba8", "#94e2d5", "#fab387", "#89dceb"]

    readonly property bool enabled: SettingsData.s.tracking.internetUsageEnabled
    property string activeApp: ""
    property string todayKey: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property var sessionTotals: ({})
    property real currentSessionMB: 0
    property var history: ({})
    property bool _loaded: false
    property int _tickSeconds: 0
    property var _lastCumulative: ({})

    property bool debugLogging: false

    function _looksLikeRawConnection(name) {
        var dashIdx = name.lastIndexOf("-");
        if (dashIdx <= 0 || dashIdx >= name.length - 1)
            return false;

        var left = name.substring(0, dashIdx);
        var right = name.substring(dashIdx + 1);
        var portPattern = /:[0-9]+$/;

        return portPattern.test(left) && portPattern.test(right);
    }

    property Process _netHogs
    property var _currentIfaces: [] // last interface list nethogs was launched with
    property bool _netHogsStarting: false

    function _netHogsCommand(ifaceList) {
        var ifacesArg = ifaceList.join(" ");
        return ["bash", "-c", "if [ \"$(id -u)\" -ne 0 ] && ! getcap \"$(command -v nethogs)\" 2>/dev/null | grep -q cap_net_admin; then echo '[InternetUsage] WARNING: nethogs lacks CAP_NET_ADMIN/CAP_NET_RAW and is not running as root -- PID resolution will likely fail and connections will show as raw ip:port tuples. Run: sudo setcap cap_net_raw,cap_net_admin+ep $(command -v nethogs)' >&2; fi; exec nethogs -t -d 1 " + ifacesArg];
    }

    function _restartNetHogs(ifaceList) {
        if (!root.enabled) {
            _netHogs.running = false;
            return ;
        }
        if (ifaceList.length === 0) {
            if (root.debugLogging)
                console.log("[InternetUsage] no interfaces found, skipping nethogs (will retry)");

            return ;
        }
        root._currentIfaces = ifaceList;
        root._netHogsStarting = true;
        _netHogs.running = false;
        _netHogs.command = root._netHogsCommand(ifaceList);
        _netHogs.running = true;
        if (root.debugLogging)
            console.log("[InternetUsage] (re)starting nethogs on interfaces:", ifaceList.join(", "));

    }

    _netHogs: Process {
        id: netHogs

        property string _buf: ""

        command: []
        running: false

        stderr: SplitParser {
            onRead: function(line) {
                // console.log("[InternetUsage][nethogs-stderr]", line);
            }
        }

        onExited: function(exitCode, exitStatus) {
            root._netHogsStarting = false;
            if (exitCode !== 0)
                console.log("[InternetUsage] nethogs exited unexpectedly, code:", exitCode);
        }

        stdout: SplitParser {
            onRead: function(line) {
                if (line.indexOf("/") === -1)
                    return ;

                var parts = line.split("\t");
                if (parts.length < 3)
                    return ;

                var ident = parts[0];
                var segments = ident.split("/");
                if (segments.length < 3)
                    return ;

                var identity = segments.slice(0, segments.length - 2).join("/");
                if (identity.length === 0)
                    return ;

                if (identity.indexOf("unknown") === 0)
                    return ;

                if (root._looksLikeRawConnection(identity)) {
                    if (root.debugLogging)
                        console.log("[InternetUsage] dropping unresolved connection:", identity);

                    return ;
                }

                var firstToken = identity.split(" ")[0];
                var baseSlash = firstToken.lastIndexOf("/");
                var appName = baseSlash >= 0 ? firstToken.substring(baseSlash + 1) : firstToken;
                if (appName.length === 0)
                    return ;

                var sentKBps = parseFloat(parts[1]) || 0;
                var recvKBps = parseFloat(parts[2]) || 0;
                if (root.debugLogging)
                    console.log("[InternetUsage] sample:", appName, "sent=" + sentKBps + "KB/s", "recv=" + recvKBps + "KB/s");

                root._applySample(appName, sentKBps, recvKBps);
            }
        }
    }

    property Process _interfaceWatcher

    _interfaceWatcher: Process {
        id: interfaceWatcher

        property string _buf: ""

        command: ["bash", "-c", "ip -o link show | awk -F': ' '{print $2}' | grep -vE '^(lo|docker|veth|br-)' | sort"]
        running: false
        onRunningChanged: {
            if (running)
                _buf = "";
        }

        stdout: SplitParser {
            onRead: function(line) {
                if (line.length > 0)
                    interfaceWatcher._buf += line + "\n";
            }
        }

        onExited: function() {
            var ifaces = interfaceWatcher._buf.split("\n").filter(function(s) {
                return s.length > 0;
            });
            var prev = root._currentIfaces.slice().sort();
            var changed = ifaces.length !== prev.length || ifaces.some(function(iface, i) {
                return iface !== prev[i];
            });
            if (changed) {
                if (root.debugLogging)
                    console.log("[InternetUsage] interface change detected:", prev.join(",") || "(none)", "->", ifaces.join(",") || "(none)");

                root._restartNetHogs(ifaces);
            }
        }
    }

    property Timer _interfacePoller

    _interfacePoller: Timer {
        interval: 15000
        repeat: true
        running: root._loaded && root.enabled
        triggeredOnStart: true
        onTriggered: {
            if (!interfaceWatcher.running)
                interfaceWatcher.running = true;

        }
    }

    onEnabledChanged: {
        if (!enabled) {
            _netHogs.running = false;
            activeApp = "";
            currentSessionMB = 0;
            _flush();
        } else if (_loaded) {
            interfaceWatcher.running = true;
        }
    }

    function _applySample(appName, sentKBps, recvKBps) {
        if (!root.enabled)
            return ;

        var mb = (sentKBps + recvKBps) / 1024;
        if (mb <= 0)
            return ;

        var t = root.sessionTotals;
        t[appName] = (t[appName] || 0) + mb;
        root.sessionTotals = t;
        root.activeApp = appName;
        root.currentSessionMB = t[appName];
    }

    property Timer _ticker

    _ticker: Timer {
        interval: 1000
        repeat: true
        running: root._loaded
        onTriggered: {
            root._tickSeconds++;
            if (root._tickSeconds % 30 === 0)
                root._flush();

        }
    }

    property string _configPath: ""
    property Process _resolveHome

    _resolveHome: Process {
        id: resolveHome

        command: ["bash", "-c", "echo -n $HOME/.config/lis/internetusage.json"]
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
        command: ["bash", "-c", "cat \"$HOME/.config/lis/internetusage.json\" 2>/dev/null || echo '{}'"]
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
            if (root.enabled)
                interfaceWatcher.running = true;
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

    function formatData(mb) {
        if (!mb || mb <= 0)
            return "0 MB";

        if (mb < 1024)
            return mb.toFixed(mb < 10 ? 1 : 0) + " MB";

        var gb = mb / 1024;
        return gb.toFixed(gb < 10 ? 2 : 1) + " GB";
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

    Component.onDestruction: {
        _flush();
    }
}
