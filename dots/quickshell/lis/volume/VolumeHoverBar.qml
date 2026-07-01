import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import qs.hover

HoverBar {
    id: volumeBar
    anchors.right: true

    PwObjectTracker { objects: [Pipewire.defaultAudioSink] }

    property bool ready: false
    property real pwVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0

    value: pwVolume

    onPwVolumeChanged: {
        if (ready) VolumePopupState.show(pwVolume)
        else ready = true
    }

    onScrolled: delta => {
        const newVol = Math.max(0, Math.min(1, pwVolume + delta))
        Pipewire.defaultAudioSink.audio.volume = newVol
    }
}