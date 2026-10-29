import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.settings.data

// "Pill Blur". A Hyprland layer rule (hyprland/rules.lua) blurs behind the
// bar's namespace, but only while Hyprland's blur is on, and the config
// keeps it off. This turns it on at runtime while the setting is on, and
// back to what it was after; windows stay sharp, since a window rule opts
// them all out of blur. A config reload resets it, so it's applied again.
Scope {
    id: root

    readonly property bool enabled: SettingsData.s.bar.pillBlur

    // Lua run in Hyprland's config state, which keeps the value blur had
    // before in a global
    readonly property string enableCode: 'if lis_blur_was == nil then lis_blur_was = hl.get_config("decoration.blur.enabled") end '
        + 'hl.config({ decoration = { blur = { enabled = true } } })'
    readonly property string disableCode: 'if lis_blur_was ~= nil then hl.config({ decoration = { blur = { enabled = lis_blur_was } } }) end '
        + 'lis_blur_was = nil'

    property bool _again: false

    // One hyprctl at a time, so quick toggles can't land out of order
    function apply(): void {
        if (runner.running) {
            root._again = true
            return
        }
        runner.command = ["hyprctl", "eval", root.enabled ? root.enableCode : root.disableCode]
        runner.running = true
    }

    onEnabledChanged: apply()
    // Also when off: undoes blur a crashed shell may have left on
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
