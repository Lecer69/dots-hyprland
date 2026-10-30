import QtQuick
import Quickshell
import Quickshell.Io

// The system audio's spectrum from cava; flat without cava
Item {
    id: root

    property bool running: false
    readonly property int bars: 36
    // 0..1 per bar, low notes first
    property var levels: []
    property real bass: 0

    onRunningChanged: {
        if (!root.running) {
            root.levels = []
            root.bass = 0
        }
    }

    Process {
        command: ["cava", "-p", Quickshell.shellPath("media/cava.conf")]
        running: root.running

        // "12;40;7;...;" per frame
        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(";")
                const levels = new Array(root.bars)
                for (let i = 0; i < root.bars; i++)
                    levels[i] = Math.min(1, (parseInt(parts[i]) || 0) / 100)
                root.levels = levels
                root.bass = (levels[0] + levels[1] + levels[2] + levels[3]) / 4
            }
        }
    }
}
