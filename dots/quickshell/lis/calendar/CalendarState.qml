import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // { id, date: "YYYY-MM-DD", text, yearly }
    property var notes: []
    property bool _loaded: false

    // Atomic writes, done before setText returns
    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.config/lis/calendar.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[calendar] can't read calendar.json:", FileViewError.toString(error))
        }
    }

    function _load(text) {
        try {
            var parsed = JSON.parse(text);
            root.notes = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.notes = [];
        }
        root._loaded = true;
    }

    function save(): void {
        // Never overwrite a file that hasn't been read
        if (!root._loaded)
            return ;

        root._store.setText(JSON.stringify(root.notes));
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
        // Yearly Feb 29 notes show on Feb 28 in other years
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
