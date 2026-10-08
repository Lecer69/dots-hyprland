import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property real gamma:      1.0
    property real brightness: 1.0
    property real contrast:   1.0
    property real saturation: 1.0

    // { id: real, name: string, gamma: real, brightness: real, contrast: real, saturation: real }
    property var presets: []
    property bool _loaded: false

    property string _configPath: ""

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
        if (_configPath === "" || !_loaded)
            return;

        const json = JSON.stringify(root.presets);
        const escaped = json.replace(/'/g, "'\\''");
        writeProc.command = ["bash", "-c", "printf '%s' '" + escaped + "' > \"" + root._configPath + "\""];
        writeProc.running = false;
        writeProc.running = true;
    }

    property Process applyProc: Process {
        running: false
        command: []
    }

    property Process _resolveHome: Process {
        id: resolveHome

        command: ["bash", "-c", "echo -n $HOME/.config/lis/gamma-presets.json"]
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

    property Process _mkdirProc: Process {
        id: mkdirProc

        running: false
        command: ["bash", "-c", "mkdir -p $HOME/.config/lis"]
        onExited: function() {
            loadProc.running = true;
        }
    }

    property Process _loadProc: Process {
        id: loadProc

        property string _buf: ""

        running: false
        command: ["bash", "-c", "cat \"$HOME/.config/lis/gamma-presets.json\" 2>/dev/null || echo '[]'"]
        onRunningChanged: {
            if (running)
                _buf = "";
        }

        onExited: function() {
            try {
                var parsed = JSON.parse(loadProc._buf.trim());
                root.presets = Array.isArray(parsed) ? parsed : [];
            } catch (e) {
                root.presets = [];
            }
            root._loaded = true;
        }

        stdout: SplitParser {
            onRead: function(line) {
                loadProc._buf += line + "\n";
            }
        }
    }

    property Process _writeProc: Process {
        id: writeProc

        running: false
        command: []
    }
}
