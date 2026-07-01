import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

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

    onIsOpenChanged: {
        if (isOpen) {
            query = initialQuery
            searchBar.setQuery(initialQuery)
        } else {
            query = ""
            clipLines = []
        }
    }

    onInitialQueryChanged: {
        if (isOpen) {
            query = initialQuery
            searchBar.setQuery(initialQuery)
        }
    }

    property var clipLines: []

    Process {
        id: clipProc
        command: ["cliphist", "list"]
        running: false
        stdout: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    card.clipLines = [...card.clipLines, line]
            }
        }
    }

    onIsClipboardChanged: {
        if (isClipboard && clipLines.length === 0)
            clipProc.running = true
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
            // Replace common math functions with JS equivalents
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

    property var clipResults: {
        if (!isClipboard) return []
        const q = cleanQuery.toLowerCase()
        if (q === "") return clipLines.slice(0, 50)
        return clipLines.filter(l => l.toLowerCase().includes(q)).slice(0, 50)
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
    color: "#c30f0f0f"
    radius: 28

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
            onActivated: card.closeRequested()
        }
    }
}
