import QtQuick
import Quickshell.Io

QtObject {
    id: root

    // { id: real, text: string, done: bool, important: bool }
    property var tasks: []
    property bool _loaded: false

    property string _configPath: ""
    property Process _resolveHome

    _resolveHome: Process {
        id: resolveHome

        command: ["bash", "-c", "echo -n $HOME/.config/lis/todo.json"]
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
        command: ["bash", "-c", "cat \"$HOME/.config/lis/todo.json\" 2>/dev/null || echo '[]'"]
        onRunningChanged: {
            if (running)
                _buf = "";
        }

        onExited: function() {
            try {
                var parsed = JSON.parse(loadProc._buf.trim());
                root.tasks = Array.isArray(parsed) ? parsed : [];
            } catch (e) {
                root.tasks = [];
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

        onExited: function() {
        }
    }

    function save(): void {
        if (_configPath === "")
            return ;

        var json = JSON.stringify(root.tasks);
        var escaped = json.replace(/'/g, "'\\''");
        writeProc.command = ["bash", "-c", "printf '%s' '" + escaped + "' > \"" + root._configPath + "\""];
        writeProc.running = false;
        writeProc.running = true;
    }

    function sorted(): var {
        const list = root.tasks.slice();
        list.sort((a, b) => {
            if (a.important !== b.important) {
                return a.important ? -1 : 1;
            }
            return 0;
        });
        return list;
    }

    function addTask(text: string): void {
        const trimmed = text.trim();
        if (trimmed.length === 0) {
            return;
        }
        const newTask = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            text: trimmed,
            done: false,
            important: false
        };
        root.tasks = [newTask].concat(root.tasks);
        save();
    }

    function toggleDone(id: real): void {
        root.tasks = root.tasks.map(t => {
            if (t.id === id) {
                return { id: t.id, text: t.text, done: !t.done, important: t.important };
            }
            return t;
        });
        save();
    }

    function toggleImportant(id: real): void {
        root.tasks = root.tasks.map(t => {
            if (t.id === id) {
                return { id: t.id, text: t.text, done: t.done, important: !t.important };
            }
            return t;
        });
        save();
    }

    function removeTask(id: real): void {
        root.tasks = root.tasks.filter(t => t.id !== id);
        save();
    }

    function clearDone(): void {
        root.tasks = root.tasks.filter(t => !t.done);
        save();
    }

    function applyOrder(orderedIds: var): void {
        const byId = new Map();
        for (const t of root.tasks) {
            byId.set(t.id, t);
        }
        const newList = [];
        for (const id of orderedIds) {
            if (byId.has(id)) {
                newList.push(byId.get(id));
                byId.delete(id);
            }
        }
        for (const leftover of byId.values()) {
            newList.push(leftover);
        }
        root.tasks = newList;
        save();
    }
}
