pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.common
import qs.devices
import qs.settings.components
import qs.settings.data
import qs.settings

ScrollView {
    id: root

    clip: true
    contentWidth: availableWidth

    // Chip -> Hyprland's value
    readonly property var accelChoices: ({ "Default": "", "Flat": "flat", "Adaptive": "adaptive" })
    readonly property var switchChoices: ({
        "Win+Space": "grp:win_space_toggle",
        "Alt+Shift": "grp:alt_shift_toggle",
        "Ctrl+Shift": "grp:ctrl_shift_toggle",
        "Caps Lock": "grp:caps_toggle"
    })
    readonly property var capsChoices: ({ "Caps Lock": "", "Ctrl": "ctrl:nocaps", "Escape": "caps:escape", "Off": "caps:none" })
    readonly property var capsPrefixes: ["ctrl:nocaps", "caps:"]

    property bool picking: false

    function chip(choices: var, value: string): string {
        return Object.keys(choices).find(k => choices[k] === value) ?? "";
    }

    function closePicker(): void {
        root.picking = false;
        body.item?.focusAdd();
    }

    // Sliders and toggles lose their bindings once used, so a reset rebuilds them
    Connections {
        target: DevicesService

        function onReverted(): void {
            body.fresh = false;
            body.fresh = true;
            root.picking = false;
            root.forceActiveFocus();
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Loader {
            id: body

            property bool fresh: true

            Layout.fillWidth: true
            active: DevicesService.ready && body.fresh

            sourceComponent: ColumnLayout {
                id: content

                function focusAdd(): void {
                    addButton.forceActiveFocus();
                }

                width: body.width
                spacing: 0

                Item { implicitHeight: 16 }
                SectionHeader { title: "Mouse" }

                SettingRow {
                    label: "Sensitivity"
                    description: "Pointer speed, from -1 to 1"
                    FloatSlider {
                        from: -1; to: 1; stepSize: 0.01; decimals: 2
                        value: DevicesService.value("input.sensitivity") ?? 0
                        onChanged: v => DevicesService.set("input.sensitivity", Math.round(v * 100) / 100)
                    }
                }
                SettingRow {
                    label: "Acceleration"
                    description: "Flat turns pointer acceleration off"
                    ChipSelector {
                        options: Object.keys(root.accelChoices)
                        value: root.chip(root.accelChoices, DevicesService.value("input.accel_profile") ?? "")
                        onSelected: v => DevicesService.set("input.accel_profile", root.accelChoices[v])
                    }
                }
                SettingRow {
                    label: "Scroll Speed"
                    description: "Scroll distance multiplier"
                    FloatSlider {
                        from: 0.1; to: 3; stepSize: 0.05; decimals: 2
                        value: DevicesService.value("input.scroll_factor") ?? 1
                        onChanged: v => DevicesService.set("input.scroll_factor", Math.round(v * 100) / 100)
                    }
                }
                SettingRow {
                    label: "Natural Scroll"
                    description: "Scroll the content instead of the view"
                    ToggleSwitch {
                        checked: DevicesService.value("input.natural_scroll") ?? false
                        onToggled: v => DevicesService.set("input.natural_scroll", v)
                    }
                }
                SettingRow {
                    label: "Left-Handed"
                    description: "Swap the left and right buttons"
                    ToggleSwitch {
                        checked: DevicesService.value("input.left_handed") ?? false
                        onToggled: v => DevicesService.set("input.left_handed", v)
                    }
                }

                Item {
                    implicitHeight: 16
                    visible: DevicesService.hasTouchpad
                }
                SectionHeader {
                    visible: DevicesService.hasTouchpad
                    title: "Touchpad"
                }

                SettingRow {
                    available: DevicesService.hasTouchpad
                    label: "Scroll Speed"
                    description: "Scroll distance multiplier"
                    FloatSlider {
                        from: 0.1; to: 3; stepSize: 0.05; decimals: 2
                        value: DevicesService.value("input.touchpad.scroll_factor") ?? 1
                        onChanged: v => DevicesService.set("input.touchpad.scroll_factor", Math.round(v * 100) / 100)
                    }
                }
                SettingRow {
                    available: DevicesService.hasTouchpad
                    label: "Natural Scroll"
                    description: "Scroll the content instead of the view"
                    ToggleSwitch {
                        checked: DevicesService.value("input.touchpad.natural_scroll") ?? false
                        onToggled: v => DevicesService.set("input.touchpad.natural_scroll", v)
                    }
                }
                SettingRow {
                    available: DevicesService.hasTouchpad
                    label: "Tap to Click"
                    description: "Tap with 1, 2 or 3 fingers for left, right or middle click"
                    ToggleSwitch {
                        checked: DevicesService.value("input.touchpad.tap_to_click") ?? false
                        onToggled: v => DevicesService.set("input.touchpad.tap_to_click", v)
                    }
                }
                SettingRow {
                    available: DevicesService.hasTouchpad
                    label: "Disable While Typing"
                    description: "Ignore the touchpad while keys are pressed"
                    ToggleSwitch {
                        checked: DevicesService.value("input.touchpad.disable_while_typing") ?? false
                        onToggled: v => DevicesService.set("input.touchpad.disable_while_typing", v)
                    }
                }
                SettingRow {
                    available: DevicesService.hasTouchpad
                    label: "Click With Fingers"
                    description: "Press with 1, 2 or 3 fingers for left, right or middle click"
                    ToggleSwitch {
                        checked: DevicesService.value("input.touchpad.clickfinger_behavior") ?? false
                        onToggled: v => DevicesService.set("input.touchpad.clickfinger_behavior", v)
                    }
                }

                Item { implicitHeight: 16 }
                SectionHeader { title: "Keyboard" }

                SettingRow {
                    label: "Repeat Rate"
                    description: "Repeats per second while a key is held"
                    IntSlider {
                        from: 1; to: 100; stepSize: 1; suffix: " /s"
                        value: DevicesService.value("input.repeat_rate") ?? 25
                        onChanged: v => DevicesService.set("input.repeat_rate", v)
                    }
                }
                SettingRow {
                    label: "Repeat Delay"
                    description: "How long a key is held before it repeats"
                    IntSlider {
                        from: 100; to: 1000; stepSize: 10; suffix: " ms"
                        value: DevicesService.value("input.repeat_delay") ?? 600
                        onChanged: v => DevicesService.set("input.repeat_delay", v)
                    }
                }
                SettingRow {
                    label: "Num Lock at Start"
                    description: "Turn Num Lock on when a keyboard connects"
                    ToggleSwitch {
                        checked: DevicesService.value("input.numlock_by_default") ?? false
                        onToggled: v => DevicesService.set("input.numlock_by_default", v)
                    }
                }
                SettingRow {
                    label: "Caps Lock Key"
                    description: "What the Caps Lock key does"
                    ChipSelector {
                        options: Object.keys(root.capsChoices)
                        value: root.chip(root.capsChoices, DevicesService.kbOption(root.capsPrefixes))
                        onSelected: v => DevicesService.setKbOption(root.capsPrefixes, root.capsChoices[v])
                    }
                }

                Item { implicitHeight: 16 }
                SectionHeader { title: "Languages" }

                Repeater {
                    // Keyed, so a moved row keeps the keyboard
                    model: ScriptModel {
                        values: DevicesService.layouts
                        objectProp: "key"
                    }

                    delegate: SettingRow {
                        id: language

                        required property var modelData
                        required property int index

                        label: language.modelData.name
                        description: language.index === 0 && DevicesService.layouts.length > 1 ? "Used first" : ""

                        Row {
                            spacing: 6

                            PanelButton {
                                id: upButton

                                visible: language.index > 0
                                text: "↑"
                                onClicked: {
                                    // The button goes away at the top
                                    if (language.index === 1)
                                        removeButton.forceActiveFocus();
                                    DevicesService.moveLayoutUp(language.modelData.key);
                                }
                            }

                            PanelButton {
                                id: removeButton

                                visible: DevicesService.layouts.length > 1
                                text: "✕"
                                onClicked: {
                                    addButton.forceActiveFocus();
                                    DevicesService.removeLayout(language.modelData.key);
                                }
                            }
                        }
                    }
                }

                SettingRow {
                    label: "Add a Language"
                    description: "Up to " + DevicesService.maxLayouts
                    PanelButton {
                        id: addButton

                        enabled: DevicesService.layouts.length < DevicesService.maxLayouts
                        text: root.picking ? "Cancel" : "Add"
                        onClicked: {
                            root.picking = !root.picking;
                            if (root.picking)
                                picker.open();
                        }
                    }
                }

                LayoutPicker {
                    id: picker

                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    visible: root.picking
                    onClosed: root.closePicker()
                    onPicked: entry => {
                        DevicesService.addLayout(entry);
                        root.closePicker();
                    }
                }

                SettingRow {
                    available: DevicesService.layouts.length > 1
                    label: "Switch Languages With"
                    description: "Press to go to the next language"
                    ChipSelector {
                        options: Object.keys(root.switchChoices)
                        value: root.chip(root.switchChoices, DevicesService.kbOption(["grp:"]))
                        onSelected: v => DevicesService.setKbOption(["grp:"], root.switchChoices[v])
                    }
                }

                Item {
                    implicitHeight: 16
                    visible: Object.keys(DevicesService.overrides).length > 0
                }
                SettingRow {
                    available: Object.keys(DevicesService.overrides).length > 0
                    label: "Reset"
                    description: "Go back to what Hyprland's config sets"
                    PanelButton {
                        text: "Reset"
                        onClicked: DevicesService.revert()
                    }
                }

                Item { implicitHeight: 16 }
            }
        }
    }
}
