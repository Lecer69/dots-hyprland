pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Goals in ~/.config/lis/goals.json; titles save when typing pauses, the rest right away
Singleton {
    id: root

    // { id, title, done, created, subgoals: [{ id, title, done }] }, in the user's order
    property var goals: []
    readonly property var sorted: root.goals.filter(g => !g.done).concat(root.goals.filter(g => g.done))
    readonly property int doneCount: root.goals.filter(g => g.done).length

    property bool _loaded: false
    property bool _dirty: false
    property real _lastId: 0

    // Atomic writes, done before setText returns, so a save on quit completes
    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.config/lis/goals.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[goals] can't read goals.json:", FileViewError.toString(error))
        }
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: root.flush()
    }

    function _load(text: string): void {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            // Nothing is saved over a file that didn't parse
            console.warn("[goals] goals.json isn't valid JSON, so nothing will be saved:", e);
            return;
        }
        const ids = [0];
        // Entries written by hand may have no id
        let missing = 0;
        const idOf = item => Number(item.id) || -(++missing);
        const valid = item => typeof item?.title === "string";
        root.goals = (Array.isArray(parsed) ? parsed : []).filter(valid).map(g => {
            const subgoals = (Array.isArray(g.subgoals) ? g.subgoals : []).filter(valid)
                .map(s => ({ id: idOf(s), title: s.title, done: !!s.done }));
            const id = idOf(g);
            ids.push(id, ...subgoals.map(s => s.id));
            return { id: id, title: g.title, done: !!g.done, created: Number(g.created) || 0, subgoals: subgoals };
        });
        root._lastId = Math.max(...ids);
        root._loaded = true;
    }

    // Unique even within a millisecond
    function _newId(): real {
        root._lastId = Math.max(Date.now(), root._lastId + 1);
        return root._lastId;
    }

    function _clean(text: string): string {
        return text.replace(/[\r\n]+/g, " ").trim();
    }

    function _set(list: var, typing: bool): void {
        root.goals = list;
        root._dirty = true;
        if (typing)
            saveTimer.restart();
        else
            root.flush();
    }

    function _update(id: real, change: var): void {
        root._set(root.goals.map(g => g.id === id ? Object.assign({}, g, change(g)) : g), false);
    }

    function flush(): void {
        saveTimer.stop();
        // Never overwrite a file that hasn't been read
        if (!root._loaded || !root._dirty)
            return;

        root._dirty = false;
        store.setText(JSON.stringify(root.goals));
    }

    // After the open goals; returns the id, -1 for none
    function add(title: string): real {
        const clean = root._clean(title);
        if (clean === "" || !root._loaded)
            return -1;

        const id = root._newId();
        root._set(root.goals.concat([{ id: id, title: clean, done: false, created: Date.now(), subgoals: [] }]), false);
        return id;
    }

    // Saved once the typing pauses
    function edit(id: real, title: string): void {
        root._set(root.goals.map(g => g.id === id ? Object.assign({}, g, { title: root._clean(title) }) : g), true);
    }

    function toggle(id: real): void {
        root._update(id, g => ({ done: !g.done }));
    }

    function remove(id: real): void {
        root._set(root.goals.filter(g => g.id !== id), false);
    }

    function order(ids: var): void {
        const list = ids.map(id => root.goals.find(g => g.id === id)).filter(g => g !== undefined);
        root._set(list.concat(root.goals.filter(g => !ids.includes(g.id))), false);
    }

    // Returns the id, -1 for none
    function addSubgoal(goalId: real, title: string): real {
        const clean = root._clean(title);
        if (clean === "" || !root.goals.some(g => g.id === goalId))
            return -1;

        const id = root._newId();
        root._update(goalId, g => ({ subgoals: g.subgoals.concat([{ id: id, title: clean, done: false }]) }));
        return id;
    }

    function editSubgoal(goalId: real, id: real, title: string): void {
        root._set(root.goals.map(g => g.id !== goalId ? g : Object.assign({}, g, {
            subgoals: g.subgoals.map(s => s.id === id ? Object.assign({}, s, { title: root._clean(title) }) : s)
        })), true);
    }

    function toggleSubgoal(goalId: real, id: real): void {
        root._update(goalId, g => ({ subgoals: g.subgoals.map(s => s.id === id ? Object.assign({}, s, { done: !s.done }) : s) }));
    }

    function removeSubgoal(goalId: real, id: real): void {
        root._update(goalId, g => ({ subgoals: g.subgoals.filter(s => s.id !== id) }));
    }

    function orderSubgoals(goalId: real, ids: var): void {
        root._update(goalId, g => {
            const list = ids.map(id => g.subgoals.find(s => s.id === id)).filter(s => s !== undefined);
            return { subgoals: list.concat(g.subgoals.filter(s => !ids.includes(s.id))) };
        });
    }

    Component.onDestruction: flush()
}
