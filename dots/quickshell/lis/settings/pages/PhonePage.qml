pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import qs.common
import qs.phone
import qs.settings.components
import qs.settings.data
import qs.settings

ScrollView {
    id: root

    clip: true
    contentWidth: availableWidth

    readonly property bool usable: PhoneService.enabled && PhoneService.running

    function phoneText(phone: var): string {
        if (!phone.connected)
            return "Not connected";
        return phone.stats ? "Connected · " + phone.stats.battery_percent + "%" : "Connected";
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Item { implicitHeight: 16 }
        SectionHeader { title: "Phone Sync" }

        SettingRow {
            label: "Enable Phone Sync"
            description: "Connect to your phone over this network with Lis App"
            ToggleSwitch {
                checked: PhoneService.enabled
                onToggled: v => SettingsData.s.phone.enabled = v
            }
        }
        SettingRow {
            available: PhoneService.enabled && !PhoneService.installed
            label: "lis-daemon isn't installed"
            description: "Build it from the Lis App project into ~/.local/bin"
        }
        SettingRow {
            available: PhoneService.enabled && PhoneService.installed && !PhoneService.running
            label: "Starting…"
            description: "Waiting for lis-daemon"
        }

        Item {
            implicitHeight: 16
            visible: root.usable
        }
        SectionHeader {
            visible: root.usable
            title: "Pairing"
        }

        SettingRow {
            available: root.usable && !PhoneService.pairing && PhoneService.pairCode === null
            label: "Pair a Phone"
            description: PhoneService.pairMessage !== "" ? PhoneService.pairMessage : "Lets a phone ask to pair for the next 2 minutes"
            PanelButton {
                text: "Pair"
                onClicked: PhoneService.openPairing()
            }
        }
        SettingRow {
            available: root.usable && PhoneService.pairing && PhoneService.pairCode === null
            label: "Waiting for your phone"
            description: "In Lis App, choose " + (PhoneService.status?.name ?? "this PC")
            PanelButton {
                text: "Cancel"
                onClicked: PhoneService.closePairing()
            }
        }
        SettingRow {
            available: root.usable && PhoneService.pairCode !== null
            label: "Code " + (PhoneService.pairCode?.code ?? "").replace(/(...)(...)/, "$1 $2")
            description: "Pair only if " + (PhoneService.pairCode?.name ?? "the phone") + " shows the same code"

            Row {
                spacing: 6

                PanelButton {
                    text: "Same, Pair"
                    onClicked: PhoneService.answerCode(true)
                }

                PanelButton {
                    text: "Decline"
                    onClicked: PhoneService.answerCode(false)
                }
            }
        }

        Item {
            implicitHeight: 16
            visible: root.usable && PhoneService.phones.length > 0
        }
        SectionHeader {
            visible: root.usable && PhoneService.phones.length > 0
            title: "Paired Phones"
        }

        Repeater {
            // Keyed, as status updates arrive often and a row holds the keyboard
            model: ScriptModel {
                values: root.usable ? PhoneService.phones : []
                objectProp: "fingerprint"
            }

            delegate: SettingRow {
                id: phoneRow

                required property var modelData
                property bool armed: false

                label: phoneRow.modelData.name
                description: phoneRow.armed ? "You'd need to pair it again" : root.phoneText(phoneRow.modelData)

                Timer {
                    interval: 3000
                    running: phoneRow.armed
                    onTriggered: phoneRow.armed = false
                }

                PanelButton {
                    text: phoneRow.armed ? "Confirm" : "Unpair"
                    onClicked: {
                        if (phoneRow.armed)
                            PhoneService.unpair(phoneRow.modelData.fingerprint)
                        else
                            phoneRow.armed = true
                    }
                }
            }
        }

        Item {
            implicitHeight: 16
            visible: root.usable && PhoneService.phones.length > 0
        }
        SectionHeader {
            visible: root.usable && PhoneService.phones.length > 0
            title: "Phone Unlock"
        }

        Repeater {
            model: ScriptModel {
                values: root.usable ? PhoneService.phones : []
                objectProp: "fingerprint"
            }

            delegate: SettingRow {
                id: unlockRow

                required property var modelData
                readonly property string state: unlockRow.modelData.unlock ?? "off"

                label: unlockRow.state === "pending" ? unlockRow.modelData.name + " asks to unlock this PC" : unlockRow.modelData.name
                description: {
                    if (unlockRow.state === "pending")
                        return "Allow only if you just asked for this on the phone";
                    if (unlockRow.state === "on")
                        return "Unlocks with its fingerprint. The first unlock after a boot still takes the password";
                    return "Off. Turn it on in Lis App, under Setup";
                }

                Row {
                    spacing: 6

                    PanelButton {
                        visible: unlockRow.state === "pending"
                        text: "Allow"
                        onClicked: PhoneService.answerUnlock(unlockRow.modelData.fingerprint, true)
                    }

                    PanelButton {
                        visible: unlockRow.state === "pending"
                        text: "Decline"
                        onClicked: PhoneService.answerUnlock(unlockRow.modelData.fingerprint, false)
                    }

                    PanelButton {
                        visible: unlockRow.state === "on"
                        text: "Turn Off"
                        onClicked: PhoneService.disableUnlock(unlockRow.modelData.fingerprint)
                    }
                }
            }
        }

        Item {
            implicitHeight: 16
            visible: root.usable
        }
        SectionHeader {
            visible: root.usable
            title: "USB Connection"
        }

        SettingRow {
            available: root.usable
            label: "Use the USB cable"
            description: {
                if (!PhoneService.usb)
                    return "Steadier for the camera. Needs adb, and USB debugging on the phone";
                return PhoneService.usbForwarding ? "Ready: turn on Use the USB cable in Lis App" : "No phone found over USB";
            }
            ToggleSwitch {
                checked: PhoneService.usb
                onToggled: v => SettingsData.s.phone.usb = v
            }
        }

        Item {
            implicitHeight: 16
            visible: root.usable
        }
        SectionHeader {
            visible: root.usable
            title: "Phone Actions"
        }

        Repeater {
            model: ScriptModel {
                values: root.usable ? PhoneService.actions : []
                objectProp: "id"
            }

            delegate: SettingRow {
                id: actionRow

                required property var modelData
                property bool armed: false

                label: actionRow.modelData.name
                description: actionRow.modelData.command

                Timer {
                    interval: 3000
                    running: actionRow.armed
                    onTriggered: actionRow.armed = false
                }

                PanelButton {
                    text: actionRow.armed ? "Confirm" : "Remove"
                    onClicked: {
                        if (actionRow.armed)
                            PhoneService.setActions(PhoneService.actions.filter(a => a.id !== actionRow.modelData.id));
                        else
                            actionRow.armed = true;
                    }
                }
            }
        }

        SettingRow {
            available: root.usable
            label: "Add an action"
            description: PhoneService.actionError !== "" ? PhoneService.actionError : "A button in Lis App that runs a command here, even while locked"

            PanelButton {
                enabled: newName.text.trim() !== "" && newCommand.text.trim() !== ""
                text: "Add"
                onClicked: {
                    const action = { id: String(Date.now()), name: newName.text.trim(), command: newCommand.text.trim() };
                    PhoneService.setActions(PhoneService.actions.concat([action]));
                    newName.text = "";
                    newCommand.text = "";
                }
            }
        }

        RowLayout {
            visible: root.usable
            Layout.fillWidth: true
            Layout.leftMargin: 16
            Layout.rightMargin: 16
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 160
                implicitHeight: 32
                radius: 6
                color: Theme.hover

                TextInput {
                    id: newName

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.adapt("#333333")
                    selectedTextColor: Theme.adapt("#ffffff")
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: newName.text === ""
                        text: "Name"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 32
                radius: 6
                color: Theme.hover

                TextInput {
                    id: newCommand

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.adapt("#333333")
                    selectedTextColor: Theme.adapt("#ffffff")
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: newCommand.text === ""
                        text: "~/.local/bin/lis-daemon obs scene Main"
                        color: Theme.textDim
                        font.pixelSize: 12
                    }
                }
            }
        }

        Item { implicitHeight: 16 }
    }
}
