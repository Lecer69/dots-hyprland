import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common

Rectangle {
    id: card

    property bool isOpen: false
    property string initialQuery: ""

    signal closeRequested()

    property string query: ""
    property bool isClipboard: query.startsWith(":")
    property bool isEmoji: query.startsWith(";")

    property string cleanQuery: {
        if (isClipboard) return query.slice(1)
        if (isEmoji) return query.slice(1)

        return query
    }

    // Picked: the card swells and fades instead of folding up
    property bool launching: false

    onIsOpenChanged: {
        if (!isOpen) return
        launching = false
        resultsList.chosen = false
        query = initialQuery
        searchBar.setQuery(initialQuery)
    }

    // Emptied once faded, so it closes as it looked
    onOpacityChanged: {
        if (isOpen || opacity > 0) return
        query = ""
        launching = false
        resultsList.chosen = false
    }

    // After the results have updated
    onQueryChanged: Qt.callLater(resultsList.resetSelection)

    onInitialQueryChanged: {
        if (isOpen) {
            query = initialQuery
            searchBar.setQuery(initialQuery)
        }
    }

    // So the clipboard view opens with the history there
    Component.onCompleted: ClipboardHistory.refresh()

    onIsClipboardChanged: {
        if (isClipboard)
            ClipboardHistory.refresh()
    }

    property var emojiList: []

    FileView {
        id: emojiFileView
        path: Qt.resolvedUrl("../scripts/fuzzel-emoji.sh")
        onLoadedChanged: {
            const lines = emojiFileView.text().split("\n")
            const dataIndex = lines.indexOf("### DATA ###")

            if (dataIndex === -1) return

            card.emojiList = lines
                .slice(dataIndex + 1)
                .filter(l => l.trim() !== "")
                .map(l => l.trim())
        }
    }

    onIsEmojiChanged: {
        if (isEmoji && emojiList.length === 0)
            emojiFileView.reload()
    }

    function evalMath(expr) {
        if (expr.trim() === "") return null

        if (!/^[\d\s\+\-\*\/\%\^\(\)\.\,sqrtceilfloorlogabsroundpiePIE]+$/i.test(expr)) return null

        try {
            // Math functions to their JS names
            const sanitized = expr
                .replace(/sqrt/gi, "Math.sqrt")
                .replace(/ceil/gi,  "Math.ceil")
                .replace(/floor/gi, "Math.floor")
                .replace(/round/gi, "Math.round")
                .replace(/log/gi,   "Math.log")
                .replace(/abs/gi,   "Math.abs")
                .replace(/\bpi\b/gi, "Math.PI")
                .replace(/\be\b/g,   "Math.E")
                .replace(/\^/g,     "**")
            const result = Function('"use strict"; return (' + sanitized + ')')()
            if (typeof result !== "number" || !isFinite(result)) return null

            const rounded = parseFloat(result.toPrecision(10))
            return String(rounded)
        } catch(e) {
            return null
        }
    }

    property string mathResult: {
        if (isClipboard || isEmoji) return ""
        return evalMath(cleanQuery) ?? ""
    }

    property var mathResults: {
        if (mathResult === "") return []
        return [{ isMath: true, result: mathResult, expression: cleanQuery }]
    }

    function scoreApp(e, q) {
        const name = (e.name ?? "").toLowerCase()
        const generic = (e.genericName ?? "").toLowerCase()

        if (name === q) return 1000
        if (name.startsWith(q)) return 100
        if (name.split(/[\s\-_]/).some(w => w.startsWith(q))) return 50
        if (name.includes(q)) return 10
        if (generic.startsWith(q)) return 8
        if (generic.includes(q)) return 3
        return 0
    }

    property var appResults: {
        if (isClipboard || isEmoji) return []
        const q = cleanQuery.toLowerCase().trim()
        if (q === "") return []
        return (DesktopEntries.applications?.values ?? [])
            .map(e => ({ entry: e, score: scoreApp(e, q) }))
            .filter(x => x.score > 0)
            .sort((a, b) => b.score - a.score)
            .map(x => x.entry)
            .slice(0, 30)
    }

    // The whole history; the list only makes rows on screen
    property var clipResults: {
        if (!isClipboard) return []
        return ClipboardHistory.filter(cleanQuery)
    }

    property var emojiResults: {
        if (!isEmoji) return []
        const q = cleanQuery.toLowerCase().trim()
        if (q === "") return emojiList.slice(0, 120)
        return emojiList.filter(e => e.toLowerCase().includes(q)).slice(0, 120)
    }

    property var results: {
        if (isClipboard) return clipResults
        if (isEmoji)     return emojiResults
        return [...mathResults, ...appResults]
    }

    width: 520
    height: col.implicitHeight + 16
    color: Theme.panel
    radius: 12
    border.color: Theme.border
    border.width: 1

    opacity: isOpen ? 1 : 0
    scale: isOpen ? 1 : launching ? 1.04 : 0.95
    transformOrigin: launching ? Item.Center : Item.Top
    transform: Translate {
        y: card.isOpen || card.launching ? 0 : -12
        Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    }
    // Held a moment longer on launch, so the icon zoom shows
    Behavior on opacity {
        NumberAnimation {
            duration: card.launching ? 320 : 180
            easing.type: card.launching ? Easing.InQuad : Easing.OutCubic
        }
    }
    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    ColumnLayout {
        id: col
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 8
            leftMargin: 8
            rightMargin: 8
        }
        spacing: 4

        SearchBar {
            id: searchBar
            Layout.fillWidth: true
            isClipboard: card.isClipboard
            isEmoji: card.isEmoji
            isOpen: card.isOpen
            onQueryChanged: q => card.query = q
            onEnterPressed: resultsList.activateCurrentItem()
            onArrowUp:      resultsList.moveUp()
            onArrowDown:    resultsList.moveDown()
            onCloseRequested: card.closeRequested()
        }

        ResultsList {
            id: resultsList
            Layout.fillWidth: true
            results: card.results
            isClipboard: card.isClipboard
            isEmoji: card.isEmoji
            onActivated: {
                card.launching = true
                card.closeRequested()
            }
        }
    }
}
