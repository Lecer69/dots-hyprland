pragma Singleton
import QtQuick

QtObject {
    property bool visible: false
    property real volume: 0
    property var _timer: Timer {
        interval: 1800
        onTriggered: VolumePopupState.visible = false
    }
    function show(vol) {
        volume = vol
        visible = true
        _timer.restart()
    }
}