import QtQuick
import QtQuick.Layouts
import qs.common
import qs.settings.components

// Adds a non-Steam game; a Windows one gets Steam's first Proton unless another is chosen
ColumnLayout {
    id: root

    // { name, label }, Default first
    property var tools: []
    property bool steamRunning: false
    property string tool: ""
    property bool _toolChosen: false
    property string _autoName: ""

    signal addRequested(string name, string exe, string options, string tool)
    signal browseRequested
    signal cancelRequested

    function focusFirst(): void {
        exeField.focusEnd()
    }

    function setExe(path: string): void {
        exeField.text = path
        nameField.focusEnd()
    }

    function exeChanged(): void {
        const file = exeField.text.trim().split("/").pop()
        const name = file.replace(/\.[^.]*$/, "")
        if (nameField.text === root._autoName)
            nameField.text = name
        root._autoName = name
        if (!root._toolChosen)
            root.tool = /\.(exe|msi|bat)$/i.test(file) ? (root.tools[1]?.name ?? "") : ""
    }

    function submit(): void {
        if (exeField.text.trim() !== "" && !root.steamRunning)
            root.addRequested(nameField.text, exeField.text.trim(), optionsField.text, root.tool)
    }

    spacing: 6

    Text {
        text: "Executable"
        font.pixelSize: 12
        color: Theme.textDim
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        TextBox {
            id: exeField

            Layout.fillWidth: true
            placeholder: "/path/to/game.exe"
            onTextChanged: root.exeChanged()
            onAccepted: root.submit()
        }

        PanelButton {
            text: "Browse"
            onClicked: root.browseRequested()
        }
    }

    Text {
        text: "Name"
        font.pixelSize: 12
        color: Theme.textDim
        Layout.topMargin: 6
    }

    TextBox {
        id: nameField

        Layout.fillWidth: true
        onAccepted: root.submit()
    }

    Text {
        text: "Launch Options"
        font.pixelSize: 12
        color: Theme.textDim
        Layout.topMargin: 6
    }

    TextBox {
        id: optionsField

        Layout.fillWidth: true
        placeholder: "gamemoderun %command%"
        onAccepted: root.submit()
    }

    Text {
        text: "Proton or Wine"
        font.pixelSize: 12
        color: Theme.textDim
        Layout.topMargin: 6
    }

    ChipSelector {
        Layout.fillWidth: true
        options: root.tools.map(t => t.label)
        value: root.tools.find(t => t.name === root.tool)?.label ?? ""
        onSelected: label => {
            root._toolChosen = true
            root.tool = root.tools.find(t => t.label === label).name
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 8
        spacing: 6

        Item {
            Layout.fillWidth: true
        }

        PanelButton {
            text: "Cancel"
            onClicked: root.cancelRequested()
        }

        PanelButton {
            text: "Add Game"
            enabled: exeField.text.trim() !== "" && !root.steamRunning
            onClicked: root.submit()
        }
    }
}
