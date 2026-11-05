pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.common
import qs.devices

// Searches XKB's layouts and variants
ColumnLayout {
    id: root

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const taken = DevicesService.layouts;
        return DevicesService.catalog.filter(e => (q === "" || e.name.toLowerCase().includes(q) || e.layout === q)
            && !taken.some(l => l.layout === e.layout && l.variant === e.variant)).slice(0, 60);
    }

    signal picked(var entry)
    signal closed()

    function open(): void {
        input.text = "";
        view.contentY = 0;
        input.forceActiveFocus();
    }

    spacing: 6

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        implicitHeight: 36
        radius: 8
        color: Theme.hover

        TextInput {
            id: input

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.adapt("#333333")
            selectedTextColor: Theme.adapt("#ffffff")
            font.pixelSize: 13
            clip: true
            selectByMouse: true
            activeFocusOnTab: true

            // Escape would close the whole panel
            Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
            Keys.onEscapePressed: root.closed()
            Keys.onDownPressed: KeyNav.stepView(view, -1, true)
            Keys.onReturnPressed: {
                if (root.results.length > 0)
                    root.picked(root.results[0]);
            }
            Keys.onEnterPressed: {
                if (root.results.length > 0)
                    root.picked(root.results[0]);
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text.length === 0
                text: "Search languages…"
                color: Theme.textDim
                font.pixelSize: 13
            }
        }
    }

    ListView {
        id: view

        Layout.fillWidth: true
        Layout.leftMargin: 16
        Layout.rightMargin: 16
        Layout.preferredHeight: 192
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            width: ListView.view.width
            height: 32
            radius: 6
            color: rowArea.containsMouse || row.activeFocus ? Theme.hover : "transparent"

            Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
            Keys.onEscapePressed: root.closed()
            Keys.onUpPressed: {
                if (!KeyNav.stepView(view, row.index, false))
                    input.forceActiveFocus();
            }
            Keys.onDownPressed: KeyNav.stepView(view, row.index, true)
            Keys.onSpacePressed: root.picked(row.modelData)
            Keys.onReturnPressed: root.picked(row.modelData)
            Keys.onEnterPressed: root.picked(row.modelData)

            Text {
                x: 12
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 24
                text: row.modelData.name
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: Theme.text
                font.pixelSize: 13
            }

            MouseArea {
                id: rowArea

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(row.modelData)
            }
        }
    }
}
