import QtQuick
import Quickshell
import Quickshell.Io

// The notes panel's notes, kept in ~/.config/lis/notes.json. An edit is
// saved once the typing pauses, and right away when the panel switches notes
// or closes, or the shell quits or reloads.
QtObject {
    id: root

    // { id: real, title: string, body: string, created: real, updated: real,
    // private: bool (missing on older notes) }, most recently edited first
    property var notes: []
    property bool _loaded: false
    // An edit waiting to be saved: { id, title, body }
    property var _pending: null

    // Atomic writes (temp file + rename), done before setText returns, so
    // the save on shutdown or reload completes too
    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.config/lis/notes.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[notes] can't read notes.json:", FileViewError.toString(error))
        }
    }

    property Timer _saveTimer: Timer {
        interval: 400
        onTriggered: root.flush()
    }

    function _load(text: string): void {
        try {
            const parsed = JSON.parse(text);
            root.notes = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.notes = [];
        }
        root._loaded = true;
    }

    function _save(): void {
        // Never overwrite a file that hasn't been read
        if (!root._loaded)
            return;

        root._store.setText(JSON.stringify(root.notes));
    }

    function find(id: real): var {
        return root.notes.find(n => n.id === id) ?? null;
    }

    // Returns the new note's id
    function add(): real {
        root.flush();
        const now = Date.now();
        const note = { id: now + Math.floor(Math.random() * 1000), title: "", body: "", created: now, updated: now };
        root.notes = [note].concat(root.notes);
        root._save();
        return note.id;
    }

    // For every keystroke: only the last one is saved, after a pause
    function edit(id: real, title: string, body: string): void {
        root._pending = { id: id, title: title, body: body };
        root._saveTimer.restart();
    }

    function flush(): void {
        root._saveTimer.stop();
        const edit = root._pending;
        root._pending = null;
        const note = edit ? root.find(edit.id) : null;
        if (!note || (note.title === edit.title && note.body === edit.body))
            return;

        const updated = Object.assign({}, note, { title: edit.title, body: edit.body, updated: Date.now() });
        root.notes = [updated].concat(root.notes.filter(n => n.id !== edit.id));
        root._save();
    }

    // Not an edit: the note keeps its place and date
    function setPrivate(id: real, value: bool): void {
        root.flush();
        root.notes = root.notes.map(n => n.id === id ? Object.assign({}, n, { private: value }) : n);
        root._save();
    }

    function remove(id: real): void {
        if (root._pending?.id === id) {
            root._saveTimer.stop();
            root._pending = null;
        }
        root.notes = root.notes.filter(n => n.id !== id);
        root._save();
    }

    Component.onDestruction: flush()
}
