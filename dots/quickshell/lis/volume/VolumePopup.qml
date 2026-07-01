import QtQuick
import qs.volume
import qs.hover

ScreenPopup {
    showing: VolumePopupState.visible
    icon: VolumePopupState.volume > 0.5 ? "../icons/speaker-high.svg" : VolumePopupState.volume > 0 ? "../icons/speaker-low.svg" : "../icons/speaker-empty.svg"
    label: Math.round(VolumePopupState.volume * 100) + "%"
}