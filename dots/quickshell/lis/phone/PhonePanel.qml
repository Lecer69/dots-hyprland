pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common

// The paired phone's figures, and sending it files
PanelFrame {
    id: root

    property bool shown: false
    readonly property bool picking: picker.running
    readonly property Item initialFocus: root
    readonly property real wantedHeight: root.headerHeight + (PhoneService.phone ? details.implicitHeight : empty.implicitHeight) + 24

    signal settingsRequested()

    title: "Phone"
    subtitle: {
        if (!PhoneService.phone)
            return "";
        return PhoneService.phone.name + (PhoneService.connected ? " · Connected" : " · Not connected");
    }

    onShownChanged: {
        if (root.shown)
            PhoneService.refresh();
        else
            picker.running = false;
    }

    // Closes the chooser when the panel closes
    Process {
        id: picker

        command: ["python3", Quickshell.shellPath("scripts/pick-image.py"), "Send to phone", "any"]
        stdout: StdioCollector {
            id: picked
        }
        onExited: code => {
            if (code === 0)
                PhoneService.sendFile(picked.text.trim());
            else if (code !== 1)
                PhoneService.transfer = "Couldn't open the file chooser";
        }
    }

    ColumnLayout {
        id: empty

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        visible: !PhoneService.phone
        spacing: 12

        Text {
            text: PhoneService.enabled ? "No phone paired" : "Phone Sync is off"
            color: Theme.text
            font.pixelSize: 13
        }

        Text {
            text: "Set it up in Settings, under Phone Sync"
            color: Theme.textDim
            font.pixelSize: 12
        }

        PanelButton {
            text: "Open Settings"
            onClicked: root.settingsRequested()
        }
    }

    ColumnLayout {
        id: details

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        visible: !!PhoneService.phone
        spacing: 16

        PhoneMeters {
            Layout.fillWidth: true
            visible: PhoneService.connected && PhoneService.stats !== null
            stats: PhoneService.stats
        }

        InfoRow {
            Layout.fillWidth: true
            visible: PhoneService.camera !== null
            label: "Camera"
            value: {
                const camera = PhoneService.camera;
                if (!camera)
                    return "";
                return camera.camera + " · " + camera.height + "p · " + Math.round(camera.measured_fps) + " fps · "
                    + camera.mbps.toFixed(1) + " Mbps · " + (camera.viewers > 0 ? "In OBS" : "Not in OBS");
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PanelButton {
                enabled: PhoneService.connected
                text: "Send File"
                onClicked: picker.running = true
            }

            Text {
                Layout.fillWidth: true
                text: PhoneService.transfer
                textFormat: Text.PlainText
                elide: Text.ElideMiddle
                color: Theme.textDim
                font.pixelSize: 12
            }
        }
    }
}
