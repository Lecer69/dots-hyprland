import QtQuick
import qs.hover

ScreenPopup {
    showing: BrightnessPopupState.visible
    icon: BrightnessPopupState.brightness > 0.5 ? "../icons/brightness-high.svg" : "../icons/brightness-low.svg"
    label: Math.round(BrightnessPopupState.brightness * 100) + "%"
}