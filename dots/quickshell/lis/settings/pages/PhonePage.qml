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

        Item { implicitHeight: 16 }
    }
}
