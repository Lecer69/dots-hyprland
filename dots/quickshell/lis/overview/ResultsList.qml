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
    // Set when an entry is picked, so the highlight flashes while the
    // launcher closes; the card clears it
    property bool chosen: false

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
        root.chosen = true
        listView.currentItem?.launch()
        root.activated()
    }

    // What the view shows. When the results empty out it keeps the last
    // rows a moment longer while they fade: an emptied view drops its rows
    // at once instead of animating them out.
    property var shownResults: []

    onResultsChanged: {
        if (results.length > 0) {
            emptying.stop()
            shownResults = results
        } else if (shownResults.length > 0) {
            emptying.restart()
        }
    }

    Timer {
        id: emptying
        interval: 200
        onTriggered: root.shownResults = []
    }

    readonly property int maxHeight: 480
    // The height the list is headed for; the visible height eases toward it
    readonly property real targetHeight: results.length > 0 ? Math.min(listView.contentHeight, maxHeight) : 0

    implicitHeight: targetHeight
    visible: implicitHeight > 0
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    ListView {
        id: listView
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        // Always the full height, with this item clipping it to the eased
        // height: every visible row gets its arrive and leave animation, and
        // the view never resizes while it applies a model change (with
        // recycled rows, that left removed rows stranded on screen)
        height: root.maxHeight
        opacity: root.results.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Diffs each new result list against the current one, so rows that
        // stay (filtering, history updates) are kept instead of rebuilt
        model: ScriptModel {
            values: root.shownResults
        }
        spacing: 2
        clip: true
        currentIndex: 0
        // A few rows past the edges are made ahead of time. Rows aren't
        // recycled (reuseItems): with the remove transition, a row still
        // leaving when the next keystroke's results came in could be left
        // half faded over the new results, taking clicks for its old entry
        cacheBuffer: 200

        flickDeceleration: 3000
        maximumFlickVelocity: 2000

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOff
            width: 0
        }

        // One highlight that slides from row to row
        highlight: Rectangle {
            radius: 8
            color: root.chosen ? "#333333" : "#1f1f1f"
            // Fades in with the row under it
            opacity: listView.currentItem ? listView.currentItem.opacity * listView.currentItem.appear : 0
            Behavior on color { ColorAnimation { duration: 100 } }
        }
        highlightFollowsCurrentItem: true
        highlightMoveDuration: 140
        highlightMoveVelocity: -1
        highlightResizeDuration: 140
        highlightResizeVelocity: -1

        // Leaving rows fade out drifting left. A math result only fades, so
        // it doesn't jump on every keystroke.
        remove: Transition {
            id: removeTransition
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: 140; easing.type: Easing.OutCubic }
                NumberAnimation {
                    property: "x"
                    to: removeTransition.ViewTransition.item.isMath ? 0 : -16
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }
        }

        // Rows that stay glide to their new places
        displaced: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
        }

        move: Transition {
            NumberAnimation { property: "y"; duration: 220; easing.type: Easing.OutCubic }
        }

        delegate: ClipboardRow {
            required property var modelData
            required property int index

            width: listView.width
            // From the row's own entry rather than the current mode, so rows
            // still leaving after a mode switch keep their look. Clipboard
            // lines are "<id>\t<preview>"; emoji lines have no tab.
            isClipboard: typeof modelData === "string" && modelData.includes("\t")
            isEmoji: typeof modelData === "string" && !modelData.includes("\t")
            isMath: modelData?.isMath ?? false
            entry: modelData
            highlighted: listView.currentIndex === index

            // A row fading out (index -1) is no longer a result
            onEntered: if (index >= 0) listView.currentIndex = index
            onChosen: if (index >= 0) root._doActivate(modelData)

            // Arriving rows come in one after another down the list. Done
            // here, not with an add transition: the view skips that for rows
            // added to an empty list and for rows the model reports as
            // inserted then moved.
            ListView.onAdd: enter(Math.min(index, 10) * 18)
        }
    }
}
