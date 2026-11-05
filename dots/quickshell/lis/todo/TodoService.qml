pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Tasks and lists in ~/.config/lis/todo.json; brought over once from the todo CLI's file
Singleton {
    id: root

    // { id, text, description, done, important, list (-1 for none) }, in the user's order
    property var tasks: []
    // { id, name }: Daily, then the rest in creation order
    property var lists: []
    // Always there; its tasks go back to undone each day
    readonly property real dailyList: 1
    property string _dailyDate: ""
    // Deleted tasks, oldest first: a task plus { listName, deletedAt }
    property var trash: []
    readonly property int trashDays: 30

    readonly property real _day: 86400000
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

    // Polled, so a day that passes during suspend still counts
    Timer {
        interval: 60000
        running: root._loaded
        repeat: true
        onTriggered: {
            root._purgeTrash();
            root._checkDay();
        }
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
        root._dailyDate = typeof parsed.dailyDate === "string" ? parsed.dailyDate : "";
        root.trash = (Array.isArray(parsed.trash) ? parsed.trash : [])
            .filter(t => typeof t?.text === "string" && Number(t.id) > 0 && Number(t.deletedAt) > 0);
        root._lastId = Math.max(0, ...root.lists.map(l => l.id), ...parsed.tasks.map(t => Number(t?.id) || 0),
            ...root.trash.map(t => Number(t.id)));
        root.tasks = parsed.tasks.filter(t => typeof t?.text === "string").map(t =>
            root._task(Number(t.id) > 0 ? Number(t.id) : root._newId(), t.text,
                typeof t.description === "string" ? t.description : "", !!t.done, !!t.important, Number(t.list)));
        root._loaded = true;
        root._purgeTrash();
        root._checkDay();
    }

    // From the older formats: the CLI's file plus stars and lists by text, or a plain array
    function _bringOver(old: var): void {
        const important = Array.isArray(old?.important) ? old.important : [];
        const assigned = old?.assigned && typeof old.assigned === "object" && !Array.isArray(old.assigned) ? old.assigned : {};
        root.lists = root._validLists(old?.lists);
        root._lastId = Math.max(0, ...root.lists.map(l => l.id));

        const fromPanel = (Array.isArray(old) ? old : []).filter(t => typeof t?.text === "string" && root._clean(t.text) !== "")
            .map(t => root._task(root._newId(), root._clean(t.text), "", !!t.done, !!t.important, -1));
        const fromCli = [];
        for (const line of root._cliText().split(/\r?\n/)) {
            // Like the CLI: other lines, and ones of 5 characters or fewer, are skipped
            const mark = line.slice(0, 4);
            const text = line.slice(4);
            if (line.length > 5 && (mark === "[ ] " || mark === "[*] ") && !fromPanel.some(t => t.text === text))
                fromCli.push(root._task(root._newId(), text, "", mark === "[*] ", important.includes(text), Number(assigned[text])));
        }
        root.tasks = fromPanel.concat(fromCli);
        root._loaded = true;
        root._dirty = true;
        root.flush();
        root._checkDay();
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
        return [{ id: root.dailyList, name: "Daily" }].concat((Array.isArray(lists) ? lists : [])
            .filter(l => typeof l?.name === "string" && Number(l.id) > 0 && Number(l.id) !== root.dailyList)
            .map(l => ({ id: Number(l.id), name: l.name })));
    }

    function _checkDay(): void {
        const now = new Date();
        const today = now.getFullYear() + "-" + (now.getMonth() + 1) + "-" + now.getDate();
        if (today === root._dailyDate)
            return;

        root._dailyDate = today;
        root._set(root.tasks.map(t => t.list === root.dailyList && t.done ? Object.assign({}, t, { done: false }) : t));
    }

    function _task(id: real, text: string, description: string, done: bool, important: bool, list: real): var {
        return {
            id: id,
            text: text,
            description: description,
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
        store.setText(JSON.stringify({ tasks: root.tasks, lists: root.lists, trash: root.trash, dailyDate: root._dailyDate }));
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

        root._set(root.tasks.concat([root._task(root._newId(), clean, "", false, false, list)]));
        return true;
    }

    // Saved once the typing pauses
    function setDescription(id: real, description: string): void {
        root.tasks = root.tasks.map(t => t.id === id ? Object.assign({}, t, { description: description }) : t);
        root._dirty = true;
        saveTimer.restart();
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

    // Trashes the matching tasks and returns the rest
    function _discard(matches: var): var {
        const now = Date.now();
        const name = list => root.lists.find(l => l.id === list)?.name.trim() ?? "";
        root.trash = root.trash.concat(root.tasks.filter(matches)
            .map(t => Object.assign({}, t, { listName: name(t.list), deletedAt: now })));
        return root.tasks.filter(t => !matches(t));
    }

    function removeTask(id: real): void {
        root._set(root._discard(t => t.id === id));
    }

    // A list's done tasks, or every list's for -1; daily tasks stay, as they reset
    function clearDone(list: real): void {
        root._set(root._discard(t => t.done && t.list !== root.dailyList && (list === -1 || t.list === list)));
    }

    // Back to its list, or to no list if that's gone
    function restoreTask(id: real): void {
        const t = root.trash.find(t => t.id === id);
        if (!t)
            return;

        root.trash = root.trash.filter(t => t.id !== id);
        root._set(root.tasks.concat([root._task(t.id, t.text, t.description ?? "", !!t.done, !!t.important, Number(t.list))]));
    }

    function _setTrash(trash: var): void {
        root.trash = trash;
        root._dirty = true;
        root.flush();
    }

    function deleteForever(id: real): void {
        root._setTrash(root.trash.filter(t => t.id !== id));
    }

    function emptyTrash(): void {
        root._setTrash([]);
    }

    function trashDaysLeft(task: var): int {
        return Math.max(1, Math.ceil((task.deletedAt + root.trashDays * root._day - Date.now()) / root._day));
    }

    function _purgeTrash(): void {
        const cutoff = Date.now() - root.trashDays * root._day;
        if (root.trash.some(t => t.deletedAt < cutoff))
            root._setTrash(root.trash.filter(t => t.deletedAt >= cutoff));
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
        if (id === root.dailyList)
            return;

        root.lists = root.lists.map(l => l.id === id ? { id: id, name: name } : l);
        root._dirty = true;
        saveTimer.restart();
    }

    // Its tasks go to the trash
    function removeList(id: real): void {
        if (!root._loaded || id === root.dailyList)
            return;

        const rest = root._discard(t => t.list === id);
        root.lists = root.lists.filter(l => l.id !== id);
        root._set(rest);
    }

    Component.onDestruction: flush()
}
