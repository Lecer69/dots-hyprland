pragma Singleton

import QtQuick
import Quickshell

// One state for every bar; kept across hot reloads, which leave Hyprland's settings as they are
Singleton {
    id: root

    readonly property bool active: kept.active

    function toggle(): void {
        kept.active = !kept.active;
        if (kept.active) {
            Quickshell.execDetached(["hyprctl", "eval", `
                hl.config({
                    animations = { enabled = false },
                    decoration = {
                        shadow = { enabled = false },
                        blur = { enabled = false },
                        rounding = 0,
                    },
                    general = {
                        gaps_in = 0,
                        gaps_out = 5,
                        border_size = 1,
                        allow_tearing = true,
                    },
                })
            `]);
        } else {
            Quickshell.execDetached(["hyprctl", "reload"]);
        }
    }

    PersistentProperties {
        id: kept

        reloadableId: "gameMode"

        property bool active: false
    }
}
