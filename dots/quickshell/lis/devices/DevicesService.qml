pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.settings.data

// Hyprland's input options: only what was changed in Settings is saved and applied; the rest follows Hyprland's config
Singleton {
    id: root

    // "input.sensitivity" -> Hyprland's current value
    property var live: ({})
    property var overrides: ({})
    property bool ready: false
    property bool hasTouchpad: false
    // { layout, variant, name } of every XKB layout and variant
    property var catalog: []
    readonly property int maxLayouts: 4

    // { layout, variant, key, name }, the first being the default
    readonly property var layouts: {
        const names = String(root.value("input.kb_layout") ?? "").split(",");
        const variants = String(root.value("input.kb_variant") ?? "").split(",");
        return names.map((name, i) => ({ layout: name.trim(), variant: (variants[i] ?? "").trim() }))
            .filter(l => l.layout !== "")
            .map(l => Object.assign(l, { key: l.layout + "(" + l.variant + ")", name: root._layoutName(l) }));
    }
    readonly property var kbOptions: String(root.value("input.kb_options") ?? "").split(",")
        .map(o => o.trim()).filter(o => o !== "")

    property var _pending: ({})
    property bool _reverting: false

    signal reverted()

    function value(option: string): var {
        const v = root.overrides[option];
        return v !== undefined ? v : root.live[option];
    }

    function set(option: string, value: var): void {
        root.setAll({ [option]: value });
    }

    function setAll(changes: var): void {
        root.overrides = Object.assign({}, root.overrides, changes);
        root._pending = Object.assign({}, root._pending, changes);
        saveTimer.restart();
        root._apply();
    }

    // Back to what Hyprland's config sets
    function revert(): void {
        root.overrides = {};
        root._pending = {};
        root._save();
        reloader.running = true;
    }

    function _setLayouts(list: var): void {
        root.setAll({
            "input.kb_layout": list.map(l => l.layout).join(","),
            "input.kb_variant": list.map(l => l.variant).join(",")
        });
    }

    // A second language needs a way to switch to it
    function addLayout(entry: var): void {
        if (root.layouts.length >= root.maxLayouts)
            return;

        root._setLayouts(root.layouts.concat([entry]));
        if (!root.kbOptions.some(o => o.startsWith("grp:")))
            root.setKbOption(["grp:"], "grp:win_space_toggle");
    }

    function removeLayout(key: string): void {
        root._setLayouts(root.layouts.filter(l => l.key !== key));
    }

    function moveLayoutUp(key: string): void {
        const list = root.layouts.slice();
        const i = list.findIndex(l => l.key === key);
        if (i < 1)
            return;

        list.splice(i - 1, 0, list.splice(i, 1)[0]);
        root._setLayouts(list);
    }

    // The current option starting with any of `prefixes`, "" for none
    function kbOption(prefixes: var): string {
        return root.kbOptions.find(o => prefixes.some(p => o.startsWith(p))) ?? "";
    }

    // Replaces it, "" removing it
    function setKbOption(prefixes: var, option: string): void {
        const rest = root.kbOptions.filter(o => !prefixes.some(p => o.startsWith(p)));
        root.set("input.kb_options", (option !== "" ? rest.concat([option]) : rest).join(","));
    }

    function _layoutName(l: var): string {
        const entry = root.catalog.find(e => e.layout === l.layout && e.variant === l.variant);
        return entry?.name ?? (l.variant !== "" ? l.layout + " (" + l.variant + ")" : l.layout);
    }

    // { input: { touchpad: { natural_scroll: true } } } from "input.touchpad.natural_scroll"
    function _code(options: var): string {
        const table = {};
        for (const key of Object.keys(options)) {
            const path = key.split(".");
            let t = table;
            for (let i = 0; i < path.length - 1; i++)
                t = t[path[i]] = t[path[i]] ?? {};
            t[path[path.length - 1]] = options[key];
        }
        return "hl.config(" + root._lua(table) + ")";
    }

    function _lua(v: var): string {
        if (typeof v === "object")
            return "{ " + Object.keys(v).map(k => k + " = " + root._lua(v[k])).join(", ") + " }";
        return typeof v === "string" ? JSON.stringify(v) : String(v);
    }

    // One hyprctl at a time, so a dragged slider sends only its latest value
    function _apply(): void {
        if (applier.running || Object.keys(root._pending).length === 0)
            return;

        applier.command = ["hyprctl", "eval", root._code(root._pending)];
        root._pending = {};
        applier.running = true;
    }

    function _applyAll(): void {
        root._pending = Object.assign({}, root.overrides);
        root._apply();
    }

    function _refresh(): void {
        if (!options.running)
            options.running = true;
        if (!devices.running)
            devices.running = true;
    }

    function _save(): void {
        saveTimer.stop();
        if (SettingsData.s.devices)
            SettingsData.s.devices.overrides = root.overrides;
    }

    function _readOptions(text: string): void {
        let parsed;
        try {
            parsed = JSON.parse(text);
        } catch (e) {
            // hyprctl prints an error instead of JSON mid-reload; keep the last good values
            console.warn("[devices] unreadable hyprctl descriptions:", e);
            return;
        }

        const live = {};
        for (const o of parsed) {
            if (o.name.startsWith("input:"))
                live[o.name.replace(/:/g, ".").replace(/-/g, "_")] = o.current === "[[EMPTY]]" ? "" : o.current;
        }
        root.live = live;
        root.ready = true;
        if (root._reverting) {
            root._reverting = false;
            root.reverted();
        }
    }

    function _readCatalog(text: string): void {
        const entries = [];
        let section = "";
        for (const line of text.split("\n")) {
            if (line.startsWith("! ")) {
                section = line.slice(2).trim();
                continue;
            }
            const m = line.match(/^\s+(\S+)\s+(.+)$/);
            if (!m)
                continue;
            if (section === "layout") {
                entries.push({ layout: m[1], variant: "", name: m[2] });
            } else if (section === "variant") {
                const v = m[2].match(/^(\S+): (.+)$/);
                if (v)
                    entries.push({ layout: v[1], variant: m[1], name: v[2] });
            }
        }
        root.catalog = entries;
    }

    Timer {
        id: saveTimer

        interval: 400
        onTriggered: root._save()
    }

    Process {
        id: applier

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() !== "ok")
                    console.warn("[devices] hyprctl eval:", text.trim());
            }
        }
        onExited: root._apply()
    }

    Process {
        id: reloader

        command: ["hyprctl", "reload", "config-only"]
        onExited: {
            root._reverting = true;
            root._refresh();
        }
    }

    Process {
        id: options

        command: ["hyprctl", "descriptions", "-j"]
        stdout: StdioCollector {
            onStreamFinished: root._readOptions(text)
        }
    }

    Process {
        id: devices

        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.hasTouchpad = JSON.parse(text).mice.some(m => /touchpad|trackpad/i.test(m.name));
                } catch (e) {
                    console.warn("[devices] unreadable hyprctl devices:", e);
                }
            }
        }
    }

    FileView {
        path: "/usr/share/X11/xkb/rules/base.lst"
        printErrors: false
        onLoaded: root._readCatalog(text())
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded") {
                root._applyAll();
                root._refresh();
            }
        }
    }

    Component.onCompleted: {
        root.overrides = SettingsData.s.devices?.overrides ?? {};
        root._applyAll();
        root._refresh();
    }

    Component.onDestruction: {
        if (saveTimer.running)
            root._save();
    }
}
