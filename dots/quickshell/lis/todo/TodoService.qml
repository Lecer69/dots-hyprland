pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Tasks and lists in ~/.config/lis/todo.json; brought over once from the todo CLI's file
Singleton {
    id: root

    // { id, text, done, important, list (-1 for none) }, in the user's order
    property var tasks: []
    // { id, name }, in creation order
    property var lists: []

    property bool _loaded: false
    property bool _dirty: false
    property real _lastId: 0

    // Atomic writes, done before setText returns, so a save on quit completes
    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.config/lis/todo.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("")
            else console.warn("[todo] can't read todo.json:", FileViewError.toString(error))
        }
    }

    // The todo CLI's file, only read to bring its tasks over
    FileView {
        id: cliFile

        preload: false
        blockLoading: true
        printErrors: false
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: root.flush()
    }

    function _load(text: string): void {
        let parsed = null;
        if (text !== "") {
            try {
                parsed = JSON.parse(text);
            } catch (e) {
                // Nothing is saved over a file that didn't parse
                console.warn("[todo] todo.json isn't valid JSON, so nothing will be saved:", e);
                return;
            }
        }
        if (!Array.isArray(parsed?.tasks)) {
            root._bringOver(parsed);
            return;
        }

        root.lists = root._validLists(parsed.lists);
        root._lastId = Math.max(0, ...root.lists.map(l => l.id), ...parsed.tasks.map(t => Number(t?.id) || 0));
        root.tasks = parsed.tasks.filter(t => typeof t?.text === "string").map(t =>
            root._task(Number(t.id) > 0 ? Number(t.id) : root._newId(), t.text, !!t.done, !!t.important, Number(t.list)));
        root._loaded = true;
    }

    // From the older formats: the CLI's file plus stars and lists by text, or a plain array
    function _bringOver(old: var): void {
        const important = Array.isArray(old?.important) ? old.important : [];
        const assigned = old?.assigned && typeof old.assigned === "object" && !Array.isArray(old.assigned) ? old.assigned : {};
        root.lists = root._validLists(old?.lists);
        root._lastId = Math.max(0, ...root.lists.map(l => l.id));

        const fromPanel = (Array.isArray(old) ? old : []).filter(t => typeof t?.text === "string" && root._clean(t.text) !== "")
            .map(t => root._task(root._newId(), root._clean(t.text), !!t.done, !!t.important, -1));
        const fromCli = [];
        for (const line of root._cliText().split(/\r?\n/)) {
            // Like the CLI: other lines, and ones of 5 characters or fewer, are skipped
            const mark = line.slice(0, 4);
            const text = line.slice(4);
            if (line.length > 5 && (mark === "[ ] " || mark === "[*] ") && !fromPanel.some(t => t.text === text))
                fromCli.push(root._task(root._newId(), text, mark === "[*] ", important.includes(text), Number(assigned[text])));
        }
        root.tasks = fromPanel.concat(fromCli);
        root._loaded = true;
        root._dirty = true;
        root.flush();
        console.log("[todo] brought", root.tasks.length, "tasks over into todo.json");
    }

    // $TODO_PATH, else ~/TODO if it exists, else ~/.todo
    function _cliText(): string {
        const home = Quickshell.env("HOME");
        const paths = Quickshell.env("TODO_PATH") ? [Quickshell.env("TODO_PATH")] : [home + "/TODO", home + "/.todo"];
        for (const path of paths) {
            cliFile.path = path;
            const text = cliFile.text();
            if (cliFile.loaded)
                return text;
        }
        return "";
    }

    function _validLists(lists: var): var {
        return (Array.isArray(lists) ? lists : []).filter(l => typeof l?.name === "string" && Number(l.id) > 0)
            .map(l => ({ id: Number(l.id), name: l.name }));
    }

    function _task(id: real, text: string, done: bool, important: bool, list: real): var {
        return {
            id: id,
            text: text,
            done: done,
            important: important,
            list: root.lists.some(l => l.id === list) ? list : -1
        };
    }

    // Unique even within a millisecond
    function _newId(): real {
        root._lastId = Math.max(Date.now(), root._lastId + 1);
        return root._lastId;
    }

    // A task is one line
    function _clean(text: string): string {
        return text.replace(/[\r\n]+/g, " ").trim();
    }

    function _set(tasks: var): void {
        root.tasks = tasks;
        root._dirty = true;
        root.flush();
    }

    function _update(id: real, change: var): void {
        root._set(root.tasks.map(t => t.id === id ? Object.assign({}, t, change(t)) : t));
    }

    function flush(): void {
        saveTimer.stop();
        // Never overwrite a file that hasn't been read
        if (!root._loaded || !root._dirty)
            return;

        root._dirty = false;
        store.setText(JSON.stringify({ tasks: root.tasks, lists: root.lists }));
    }

    function sorted(): var {
        return root.listed(-1);
    }

    // A list's tasks, or every task for -1, starred first
    function listed(list: real): var {
        const tasks = list === -1 ? root.tasks : root.tasks.filter(t => t.list === list);
        return tasks.filter(t => t.important).concat(tasks.filter(t => !t.important));
    }

    // Last, into the list (-1 for none); returns whether one was added
    function addTask(text: string, list: real): bool {
        const clean = root._clean(text);
        if (clean === "" || !root._loaded)
            return false;

        root._set(root.tasks.concat([root._task(root._newId(), clean, false, false, list)]));
        return true;
    }

    function toggleDone(id: real): void {
        root._update(id, t => ({ done: !t.done }));
    }

    function toggleImportant(id: real): void {
        root._update(id, t => ({ important: !t.important }));
    }

    // -1 for none
    function setList(id: real, list: real): void {
        root._update(id, () => ({ list: root.lists.some(l => l.id === list) ? list : -1 }));
    }

    function removeTask(id: real): void {
        root._set(root.tasks.filter(t => t.id !== id));
    }

    // A list's done tasks, or every list's for -1
    function clearDone(list: real): void {
        root._set(root.tasks.filter(t => !t.done || (list !== -1 && t.list !== list)));
    }

    // ids take the places they had between them, so one list reorders without moving others
    function applyOrder(ids: var): void {
        const moved = ids.map(id => root.tasks.find(t => t.id === id)).filter(t => t !== undefined);
        let i = 0;
        root._set(root.tasks.map(t => ids.includes(t.id) ? moved[i++] : t));
    }

    // Returns the id, -1 for none
    function addList(name: string): real {
        if (!root._loaded)
            return -1;

        const id = root._newId();
        root.lists = root.lists.concat([{ id: id, name: name }]);
        root._dirty = true;
        root.flush();
        return id;
    }

    // Saved once the typing pauses
    function renameList(id: real, name: string): void {
        root.lists = root.lists.map(l => l.id === id ? { id: id, name: name } : l);
        root._dirty = true;
        saveTimer.restart();
    }

    // Its tasks go with it
    function removeList(id: real): void {
        if (!root._loaded)
            return;

        root.lists = root.lists.filter(l => l.id !== id);
        root._set(root.tasks.filter(t => t.list !== id));
    }

    Component.onDestruction: flush()
}
