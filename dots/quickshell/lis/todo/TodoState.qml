import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // { id: real, text: string, done: bool, important: bool }
    property var tasks: []
    property bool _loaded: false

    // Atomic writes (temp file + rename), done before setText returns
    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.config/lis/todo.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[todo] can't read todo.json:", FileViewError.toString(error))
        }
    }

    function _load(text) {
        try {
            var parsed = JSON.parse(text);
            root.tasks = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.tasks = [];
        }
        root._loaded = true;
    }

    function save(): void {
        // Never overwrite a file that hasn't been read
        if (!root._loaded)
            return ;

        root._store.setText(JSON.stringify(root.tasks));
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
