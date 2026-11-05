pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.settings.data

// The one wl-gammactl-rust that holds the screens' gamma: Color Settings' values, scaled by the night light
Singleton {
    id: root

    property real gamma: 1.0
    property real brightness: 1.0
    property real contrast: 1.0
    property real saturation: 1.0

    // { id, name, gamma, brightness, contrast, saturation }
    property var presets: []
    property bool _loaded: false

    readonly property bool nightLight: SettingsData.s.nightLight.enabled

    function toggleNightLight(): void {
        SettingsData.s.nightLight.enabled = !SettingsData.s.nightLight.enabled;
    }

    function apply(): void {
        const night = root.nightLight ? SettingsData.s.nightLight : { gamma: 1, brightness: 1, contrast: 1, saturation: 1 };
        const values = {
            "-g": root.gamma * night.gamma,
            "-b": root.brightness * night.brightness,
            "-c": root.contrast * night.contrast,
            "-s": root.saturation * night.saturation
        };
        const flags = Object.keys(values);
        applyProc.running = false;
        // Neutral needs no process, and stopping it restores the screens
        if (flags.every(f => values[f] === 1))
            return;

        applyProc.command = ["wl-gammactl-rust"].concat(...flags.map(f => [f, values[f].toFixed(2)]));
        applyProc.running = true;
    }

    function reset(): void {
        root.gamma = 1.0;
        root.brightness = 1.0;
        root.contrast = 1.0;
        root.saturation = 1.0;
        root.apply();
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
        root.savePresets();
    }

    function removePreset(id: real): void {
        root.presets = root.presets.filter(p => p.id !== id);
        root.savePresets();
    }

    function applyPreset(id: real): void {
        const preset = root.presets.find(p => p.id === id);
        if (!preset)
            return;

        root.gamma = preset.gamma;
        root.brightness = preset.brightness;
        root.contrast = preset.contrast;
        root.saturation = preset.saturation;
        root.apply();
    }

    function savePresets(): void {
        // Never overwrite a file that hasn't been read
        if (!root._loaded)
            return;

        store.setText(JSON.stringify(root.presets));
    }

    function _load(text: string): void {
        try {
            const parsed = JSON.parse(text);
            root.presets = Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            root.presets = [];
        }
        root._loaded = true;
    }

    // Every value the night light uses; a slider writes each step, so it applies once they settle
    readonly property string _nightValues: {
        const n = SettingsData.s.nightLight;
        return [n.enabled, n.gamma, n.brightness, n.contrast, n.saturation].join();
    }

    on_NightValuesChanged: applyTimer.restart()
    // Not at once: on a reload the old process still holds the screens
    Component.onCompleted: if (root.nightLight) applyTimer.restart()

    Timer {
        id: applyTimer

        interval: 120
        onTriggered: root.apply()
    }

    Process {
        id: applyProc
    }

    // Atomic writes, done before setText returns
    FileView {
        id: store

        path: Quickshell.env("HOME") + "/.config/lis/gamma-presets.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]");
            else console.warn("[gamma] can't read gamma-presets.json:", FileViewError.toString(error));
        }
    }

    IpcHandler {
        target: "nightlight"

        function toggle(): void {
            root.toggleNightLight();
        }

        function enable(): void {
            SettingsData.s.nightLight.enabled = true;
        }

        function disable(): void {
            SettingsData.s.nightLight.enabled = false;
        }
    }

    GlobalShortcut {
        name: "nightlight"
        description: "Toggles the night light"
        onPressed: root.toggleNightLight()
    }
}
