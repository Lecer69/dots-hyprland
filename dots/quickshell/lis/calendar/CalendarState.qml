import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // { id: real, date: "YYYY-MM-DD", text: string, yearly: bool }
    property var notes: []
    property bool _loaded: false

    property string _configPath: ""
    property Process _resolveHome

    _resolveHome: Process {
        id: resolveHome

        command: ["bash", "-c", "echo -n $HOME/.config/lis/calendar.json"]
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
        command: ["bash", "-c", "cat \"$HOME/.config/lis/calendar.json\" 2>/dev/null || echo '[]'"]
        onRunningChanged: {
            if (running)
                _buf = "";
        }

        onExited: function() {
            try {
                var parsed = JSON.parse(loadProc._buf.trim());
                root.notes = Array.isArray(parsed) ? parsed : [];
            } catch (e) {
                root.notes = [];
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

    function save(): void {
        if (_configPath === "" || !_loaded)
            return ;

        var json = JSON.stringify(root.notes);
        var escaped = json.replace(/'/g, "'\\''");
        writeProc.command = ["bash", "-c", "printf '%s' '" + escaped + "' > \"" + root._configPath + "\""];
        writeProc.running = false;
        writeProc.running = true;
    }

    function _pad(n: int): string {
        return n < 10 ? "0" + n : "" + n;
    }

    function dateKey(d: date): string {
        return d.getFullYear() + "-" + _pad(d.getMonth() + 1) + "-" + _pad(d.getDate());
    }

    function _isLeap(y: int): bool {
        return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0;
    }

    function _matches(note: var, d: date): bool {
        const key = dateKey(d);
        if (note.date === key)
            return true;
        if (!note.yearly)
            return false;
        const md = note.date.slice(5);
        if (md === key.slice(5))
            return true;
        // Yearly Feb 29 notes show on Feb 28 in non-leap years
        return md === "02-29" && key.slice(5) === "02-28" && !_isLeap(d.getFullYear());
    }

    function notesFor(d: date): var {
        return root.notes.filter(n => _matches(n, d));
    }

    function hasNotes(d: date): bool {
        return root.notes.some(n => _matches(n, d));
    }

    function addNote(d: date, text: string, yearly: bool): void {
        const trimmed = text.trim();
        if (trimmed.length === 0) {
            return;
        }
        const newNote = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            date: dateKey(d),
            text: trimmed,
            yearly: yearly
        };
        root.notes = root.notes.concat([newNote]);
        save();
    }

    function toggleYearly(id: real): void {
        root.notes = root.notes.map(n => {
            if (n.id === id) {
                return { id: n.id, date: n.date, text: n.text, yearly: !n.yearly };
            }
            return n;
        });
        save();
    }

    function removeNote(id: real): void {
        root.notes = root.notes.filter(n => n.id !== id);
        save();
    }
}
