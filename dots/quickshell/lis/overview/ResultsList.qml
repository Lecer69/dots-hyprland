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
    // The highlight flashes while the launcher closes; the card clears it
    property bool chosen: false

    signal activated()

    function activateCurrentItem() {
        const idx = listView.currentIndex
        if (idx < 0 || idx >= root.results.length) return
        _doActivate(root.results[idx])
    }

    function moveUp() { if (listView.currentIndex > 0) listView.currentIndex-- }
    function moveDown() { if (listView.currentIndex < root.results.length - 1) listView.currentIndex++ }

    // Only on a new query; history updates keep the selection
    function resetSelection() {
        listView.currentIndex = 0
        listView.positionViewAtBeginning()
    }

    // wl-copy forks, so copies outlive the launcher
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

    // Keeps the last rows a moment while they fade: an emptied view drops them at once
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
    // The visible height eases toward this
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
        // Always full height, clipped to the eased height, so the view never resizes mid-change
        height: root.maxHeight
        opacity: root.results.length > 0 ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // Diffed, so rows that stay are kept
        model: ScriptModel {
            values: root.shownResults
        }
        spacing: 2
        clip: true
        currentIndex: 0
        // No reuseItems: a recycled row could stay half faded over new results
        cacheBuffer: 200

        flickDeceleration: 3000
        maximumFlickVelocity: 2000

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AlwaysOff
            width: 0
        }

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

        // Leaving rows drift left; a math result only fades
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
            // From the row's entry, not the mode, so leaving rows keep their look
            isClipboard: typeof modelData === "string" && modelData.includes("\t")
            isEmoji: typeof modelData === "string" && !modelData.includes("\t")
            isMath: modelData?.isMath ?? false
            entry: modelData
            highlighted: listView.currentIndex === index

            // A row fading out has index -1
            onEntered: if (index >= 0) listView.currentIndex = index
            onChosen: if (index >= 0) root._doActivate(modelData)

            // Here, not in an add transition: the view skips that for an empty list and for moves
            ListView.onAdd: enter(Math.min(index, 10) * 18)
        }
    }
}
