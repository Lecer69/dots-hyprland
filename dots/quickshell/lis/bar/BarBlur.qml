import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.settings.data

// Pill Blur: Hyprland only blurs layers while its blur is on, so this turns it on at runtime
Scope {
    id: root

    readonly property bool enabled: SettingsData.s.bar.pillBlur

    // Keeps blur's earlier value in a Hyprland global
    readonly property string enableCode: 'if lis_blur_was == nil then lis_blur_was = hl.get_config("decoration.blur.enabled") end '
        + 'hl.config({ decoration = { blur = { enabled = true } } })'
    readonly property string disableCode: 'if lis_blur_was ~= nil then hl.config({ decoration = { blur = { enabled = lis_blur_was } } }) end '
        + 'lis_blur_was = nil'

    property bool _again: false

    // One hyprctl at a time, so toggles stay in order
    function apply(): void {
        if (runner.running) {
            root._again = true
            return
        }
        runner.command = ["hyprctl", "eval", root.enabled ? root.enableCode : root.disableCode]
        runner.running = true
    }

    onEnabledChanged: apply()
    // Also when off: undoes blur left on by a crash
    Component.onCompleted: apply()

    Process {
        id: runner

        onExited: {
            if (!root._again) return
            root._again = false
            root.apply()
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded") root.apply()
        }
    }
}
