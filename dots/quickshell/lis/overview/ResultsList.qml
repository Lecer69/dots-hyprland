pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io

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

    property var activeCopyProc: null

    Component {
        id: copyProc
        Process {
            property var args: []
            command: args
            running: true
        }
    }

    function _doActivate(entry) {
        if (entry?.isMath) {
            root.activeCopyProc = copyProc.createObject(root, {
                args: ["wl-copy", "--foreground", "--", entry.result]
            })
        } else if (root.isEmoji) {
            const emoji = (entry ?? "").split(" ")[0]
            root.activeCopyProc = copyProc.createObject(root, {
                args: ["wl-copy", "--foreground", "--", emoji]
            })
        } else if (root.isClipboard) {
            const line = entry ?? ""
            const id = line.split("\t")[0]

            if (root.isImageEntry(line)) {
                root.activeCopyProc = copyProc.createObject(root, {
                    args: ["sh", "-c", "cliphist decode " + JSON.stringify(id) + " | wl-copy --foreground"]
                })
            } else {
                const content = line.replace(/^\S+\t/, "")
                if (content.startsWith("file://")) {
                    root.activeCopyProc = copyProc.createObject(root, {
                        args: ["sh", "-c", "printf '%s' " + JSON.stringify(content) + " | wl-copy --foreground --type text/uri-list"]
                    })
                } else {
                    root.activeCopyProc = copyProc.createObject(root, {
                        args: ["sh", "-c", "cliphist decode " + JSON.stringify(id) + " | wl-copy --foreground"]
                    })
                }
            }
        } else {
            entry?.execute()
        }
        root.activated()
    }

    function isImageEntry(line) {
        return /\[\[ binary data/.test(line ?? "")
    }

    readonly property int maxHeight: 480

    implicitHeight: Math.min(listView.contentHeight, maxHeight)
    visible: results.length > 0

    ListView {
        id: listView
        anchors.fill: parent
        model: root.results
        spacing: 2
        clip: true
        currentIndex: 0
        highlightMoveDuration: 60
        cacheBuffer: 0
        onModelChanged: currentIndex = 0

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
            isImage: root.isClipboard && root.isImageEntry(modelData)
            entry: modelData
            highlighted: listView.currentIndex === index

            onEntered: listView.currentIndex = index
            onChosen: root._doActivate(modelData)
        }
    }
}
