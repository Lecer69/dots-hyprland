pragma Singleton
import QtQuick
import Quickshell.Io

QtObject {
    property bool visible: false
    property real brightness: 0
    property var _timer: Timer {
        interval: 1800
        onTriggered: BrightnessPopupState.visible = false
    }

    property var _ipc: IpcHandler {
        target: "brightness"

        function update(): void {
            BrightnessPopupState.showStatic()
        }
    }

    property var _proc: Process {
        command: ["brightnessctl", "-m", "info"]
        stdout: SplitParser {
            onRead: data => {
                const parts = data.split(",")
                if (parts.length >= 4) {
                    const percentStr = parts[3].replace("%", "")
                    const percent = parseInt(percentStr, 10)

                    if (!isNaN(percent)) {
                        BrightnessPopupState.show(percent)
                    }
                }
            }
        }
    }

    function show(val) {
        brightness = val
        visible = true
        _timer.restart()
    }

    function showStatic() {
        _proc.running = true
    }
}