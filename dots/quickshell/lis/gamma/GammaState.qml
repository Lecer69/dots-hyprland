import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property real gamma:      1.0
    property real brightness: 1.0
    property real contrast:   1.0
    property real saturation: 1.0

    // { id, name, gamma, brightness, contrast, saturation }
    property var presets: []
    property bool _loaded: false

    function apply(): void {
        applyProc.command = [
            "wl-gammactl-rust",
            "-g", root.gamma.toFixed(2),
            "-b", root.brightness.toFixed(2),
            "-c", root.contrast.toFixed(2),
            "-s", root.saturation.toFixed(2)
        ]
        applyProc.running = false
        applyProc.running = true
    }

    function reset(): void {
        root.gamma      = 1.0
        root.brightness = 1.0
        root.contrast   = 1.0
        root.saturation = 1.0
        applyProc.running = false
    }

    function addPreset(name: string): void {
        const trimmed = name.trim();
        if (trimmed.length === 0)
            return;
        const preset = {
            id: Date.now() + Math.floor(Math.random() * 1000),
            name: trimmed,
            gamma: root.gamma,
            brightness: root.brightness,
            contrast: root.contrast,
            saturation: root.saturation
        };
        root.presets = [preset].concat(root.presets);
        savePresets();
    }

    function removePreset(id: real): void {
        root.presets = root.presets.filter(p => p.id !== id);
        savePresets();
    }

    function applyPreset(id: real): void {
        const preset = root.presets.find(p => p.id === id);
        if (!preset)
            return;
        root.gamma      = preset.gamma;
        root.brightness = preset.brightness;
        root.contrast   = preset.contrast;
        root.saturation = preset.saturation;
        apply();
    }

    function savePresets(): void {
        // Never overwrite a file that hasn't been read
        if (!_loaded)
            return;

        root._store.setText(JSON.stringify(root.presets));
    }

    property Process applyProc: Process {
        running: false
        command: []
    }

    // Atomic writes, done before setText returns
    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.config/lis/gamma-presets.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[gamma] can't read gamma-presets.json:", FileViewError.toString(error))
        }
    }

    function _load(text) {
        try {
            var parsed = JSON.parse(text);
            root.presets = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.presets = [];
        }
        root._loaded = true;
    }
}
