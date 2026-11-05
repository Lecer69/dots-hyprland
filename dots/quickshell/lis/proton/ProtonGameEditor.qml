import QtQuick
import QtQuick.Layouts
import qs.common
import qs.settings.components

// A game's launch options and compatibility tool, for Steam to read when it next starts
ColumnLayout {
    id: root

    property string launch: ""
    property string tool: ""
    // { name, label }
    property var tools: []
    property bool steamRunning: false
    property bool steam: false
    property bool hasPrefix: false

    // A tool that's gone stays selected, under its own name
    readonly property var choices: root.tools.some(t => t.name === root.tool)
        ? root.tools : root.tools.concat([{ name: root.tool, label: root.tool }])

    signal launchEdited(string options)
    signal toolChosen(string name)
    signal deletePrefixRequested
    signal removeRequested

    function commit(): void {
        if (field.text !== root.launch)
            root.launchEdited(field.text)
    }

    function focusFirst(): void {
        field.focusEnd()
    }

    spacing: 6

    Text {
        text: "Launch Options"
        font.pixelSize: 12
        color: Theme.textDim
    }

    TextBox {
        id: field

        Layout.fillWidth: true
        enabled: !root.steamRunning
        text: root.launch
        original: root.launch
        placeholder: "gamemoderun %command%"
        onEditingFinished: root.commit()
    }

    Text {
        text: "Proton or Wine"
        font.pixelSize: 12
        color: Theme.textDim
        Layout.topMargin: 6
    }

    ChipSelector {
        Layout.fillWidth: true
        enabled: !root.steamRunning
        opacity: enabled ? 1 : 0.4
        options: root.choices.map(t => t.label)
        value: root.choices.find(t => t.name === root.tool)?.label ?? ""
        onSelected: label => root.toolChosen(root.choices.find(t => t.label === label).name)
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 6

        Item {
            Layout.fillWidth: true
        }

        ConfirmButton {
            visible: root.hasPrefix
            enabled: !root.steamRunning
            idleText: "Delete Prefix"
            confirmText: "Click again, saves in it are lost"
            onConfirmed: root.deletePrefixRequested()
        }

        ConfirmButton {
            visible: !root.steam
            enabled: !root.steamRunning
            idleText: "Remove Game"
            confirmText: root.hasPrefix ? "Click again, the prefix stays" : "Click again to remove"
            onConfirmed: root.removeRequested()
        }

        // Steam asks first
        PanelButton {
            visible: root.steam
            text: "Uninstall"
            onClicked: root.removeRequested()
        }
    }
}
