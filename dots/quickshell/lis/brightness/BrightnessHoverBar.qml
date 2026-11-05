import QtQuick
import Quickshell
import qs.hover

HoverBar {
    id: brightnessBar

    bottomEnd: true

    readonly property var device: BrightnessService.device(brightnessBar.screen?.name ?? "")

    value: device?.brightness ?? 0

    onScrolled: delta => {
        if (!device?.ready) return
        device.setBrightness(device.brightness + delta)
        BrightnessPopupState.show(device.brightness)
    }
}
