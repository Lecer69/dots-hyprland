pragma ComponentBehavior: Bound

import QtQuick
import qs.common

// Finds settings among the rows the pages have now, so a new row needs no listing
Item {
    id: root

    required property Item pager
    required property var pageNames
    property string query: ""

    readonly property bool searching: root.query.trim() !== ""
    // { label, description, section, page, row, name, text }, in page order
    property var _index: []
    readonly property var results: {
        const words = root.query.trim().toLowerCase().split(/\s+/).filter(w => w !== "");
        if (words.length === 0)
            return [];

        const hits = root._index.filter(e => words.every(w => e.text.includes(w)));
        return hits.filter(e => e.name.startsWith(words[0]))
            .concat(hits.filter(e => !e.name.startsWith(words[0]) && e.name.includes(words[0])))
            .concat(hits.filter(e => !e.name.includes(words[0])));
    }

    signal chosen(int page, Item row)
    signal cancelled()

    function focusFirst(): void {
        KeyNav.stepView(view, -1, true);
    }

    function chooseFirst(): void {
        if (root.results.length > 0)
            root.chosen(root.results[0].page, root.results[0].row);
    }

    function _collect(item: Item, page: int, context: var, entries: var): void {
        for (const child of item.children) {
            if (typeof child.label === "string" && typeof child.description === "string") {
                if (child.label !== "" && child.available !== false) {
                    const name = child.label.toLowerCase();
                    entries.push({
                        label: child.label,
                        description: child.description,
                        section: context.section,
                        page: page,
                        row: child,
                        name: name,
                        text: [name, child.description, context.section, root.pageNames[page]].join(" ").toLowerCase()
                    });
                }
            } else if (typeof child.title === "string") {
                context.section = child.title;
            } else {
                root._collect(child, page, context, entries);
            }
        }
    }

    // Rows come and go, so read them each time a search starts
    onSearchingChanged: {
        if (!root.searching)
            return;

        const entries = [];
        for (let i = 0; i < root.pager.children.length; i++)
            root._collect(root.pager.children[i], i, { section: "" }, entries);
        root._index = entries;
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
