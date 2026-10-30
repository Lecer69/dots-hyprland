pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Battery state from UPower
Singleton {
    id: root

    readonly property UPowerDevice _device: UPower.displayDevice

    readonly property bool available: root._device?.isLaptopBattery ?? false
    // -100 without a battery
    readonly property int percent: root.available ? Math.max(0, Math.min(100, Math.round(root._device.percentage * 100))) : -100
    readonly property bool charging: root.available
        && (root._device.state === UPowerDeviceState.Charging || root._device.state === UPowerDeviceState.FullyCharged)
}
