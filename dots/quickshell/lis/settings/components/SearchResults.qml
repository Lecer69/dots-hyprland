pragma ComponentBehavior: Bound

import QtQuick
import qs.common
import qs.settings.data

Item {
    id: root

    required property Item pager
    required property var pageNames
    property string query: ""

    readonly property bool searching: root.query.trim() !== ""
    property var _index: []
    readonly property var results: SettingsIndex.search(root._index, root.query)

    signal chosen(int page, Item row)
    signal cancelled()

    function focusFirst(): void {
        KeyNav.stepView(view, -1, true);
    }

    function chooseFirst(): void {
        if (root.results.length > 0)
            root.chosen(root.results[0].page, root.results[0].row);
    }

    // Rows come and go, so read them each time a search starts
    onSearchingChanged: {
        if (root.searching)
            root._index = SettingsIndex.rows(root.pager, root.pageNames);
    }

    ListView {
        id: view

        anchors.fill: parent
        anchors.topMargin: 16
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.results

        delegate: Rectangle {
            id: result

            required property var modelData
            required property int index

            width: ListView.view.width
            height: result.modelData.description !== "" ? 58 : 44
            radius: 8
            color: area.containsMouse || result.activeFocus ? Theme.hover : "transparent"

            Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape
            Keys.onEscapePressed: root.cancelled()
            Keys.onUpPressed: {
                if (!KeyNav.stepView(view, result.index, false))
                    root.cancelled();
            }
            Keys.onDownPressed: KeyNav.stepView(view, result.index, true)
            Keys.onSpacePressed: root.chosen(result.modelData.page, result.modelData.row)
            Keys.onReturnPressed: root.chosen(result.modelData.page, result.modelData.row)
            Keys.onEnterPressed: root.chosen(result.modelData.page, result.modelData.row)

            Column {
                anchors.left: parent.left
                anchors.right: place.left
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: result.modelData.label
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.text
                    font.pixelSize: 13
                }

                Text {
                    width: parent.width
                    visible: text !== ""
                    text: result.modelData.description
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: Theme.textDim
                    font.pixelSize: 12
                }
            }

            Text {
                id: place

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, 150)
                text: root.pageNames[result.modelData.page]
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: 12
            }

            MouseArea {
                id: area

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.chosen(result.modelData.page, result.modelData.row)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: root.searching && root.results.length === 0
        text: "No settings found"
        color: Theme.textDim
        font.pixelSize: 13
    }
}
