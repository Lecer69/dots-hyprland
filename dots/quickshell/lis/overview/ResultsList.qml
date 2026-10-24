pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var results: []
    property bool isClipboard: false
    property bool isEmoji: false

    signal activated()

    function activateCurrentItem() {
        const idx = listView.currentIndex
        if (idx < 0 || idx >= root.results.length) return
        _doActivate(root.results[idx])
    }

    function moveUp() { if (listView.currentIndex > 0) listView.currentIndex-- }
    function moveDown() { if (listView.currentIndex < root.results.length - 1) listView.currentIndex++ }

    // On a new query. Not on every results change: a history update while
    // open keeps the selection (the view shifts it along with its row).
    function resetSelection() {
        listView.currentIndex = 0
        listView.positionViewAtBeginning()
    }

    // wl-copy forks and keeps serving the clipboard, so copies outlive the
    // launcher (and shell reloads)
    function _doActivate(entry) {
        if (entry?.isMath) {
            Quickshell.execDetached(["wl-copy", "--", entry.result])
        } else if (root.isEmoji) {
            const emoji = (entry ?? "").split(" ")[0]
            Quickshell.execDetached(["wl-copy", "--", emoji])
        } else if (root.isClipboard) {
            ClipboardHistory.copy(entry ?? "")
        } else {
            entry?.execute()
        }
        root.activated()
    }

    readonly property int maxHeight: 480

    implicitHeight: Math.min(listView.contentHeight, maxHeight)
    visible: results.length > 0

    ListView {
        id: listView
        anchors.fill: parent
        // Diffs each new result list against the current one, so rows that
        // stay (filtering, history updates) are kept instead of rebuilt
        model: ScriptModel {
            values: root.results
        }
        spacing: 2
        clip: true
        currentIndex: 0
        highlightMoveDuration: 60
        // Rows are recycled while scrolling, and a few past the edges are
        // made ahead of time
        reuseItems: true
        cacheBuffer: 200

        flickDeceleration: 3000
        maximumFlickVelocity: 2000

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOff
            width: 0
        }

        highlightFollowsCurrentItem: true

        delegate: ClipboardRow {
            required property var modelData
            required property int index

            width: listView.width
            isClipboard: root.isClipboard
            isEmoji: root.isEmoji
            isMath: modelData?.isMath ?? false
            entry: modelData
            highlighted: listView.currentIndex === index

            onEntered: listView.currentIndex = index
            onChosen: root._doActivate(modelData)
        }
    }
}
