import QtQuick

// A note's text, edited as plain text. When it has links, a read-only
// rich-text copy laid over the editor draws the text with the links colored:
// the two lay out the same, pixel for pixel, so the editor's own text is left
// transparent under it. Ctrl+click opens a link.
Item {
    id: root

    property alias text: editor.text
    property string placeholder: ""
    readonly property Item editorItem: editor

    // { start, end, url } for each link in the text
    readonly property var links: root._findLinks(editor.text)
    readonly property bool hasLinks: root.links.length > 0
    // The link under the mouse, "" for none
    readonly property string hoveredLink: hover.hovered ? root._linkAt(hover.point.position.x, hover.point.position.y) : ""

    function reset(): void {
        editor.cursorPosition = 0;
        flick.contentY = 0;
    }

    function _escapeHtml(text: string): string {
        return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    function _findLinks(text: string): var {
        const found = [];
        const re = /\b(?:https?:\/\/|www\.)[^\s<>"']+/gi;
        let match;
        while ((match = re.exec(text)) !== null) {
            let url = match[0];
            // Leave out trailing punctuation, and a closing bracket the link
            // didn't open, as in "(see https://example.com)."
            for (;;) {
                const last = url[url.length - 1];
                const open = { ")": "(", "]": "[", "}": "{" }[last];
                if (open ? url.split(open).length >= url.split(last).length : !".,;:!?'\"".includes(last))
                    break;
                url = url.slice(0, -1);
            }
            if (!/^(?:https?:\/\/|www\.)./i.test(url))
                continue;
            found.push({ start: match.index, end: match.index + url.length, url: /^www\./i.test(url) ? "https://" + url : url });
        }
        return found;
    }

    function _html(text: string, links: var): string {
        let html = "";
        let last = 0;
        for (const link of links) {
            html += root._escapeHtml(text.slice(last, link.start))
                + '<span style="color: #89b4fa">' + root._escapeHtml(text.slice(link.start, link.end)) + "</span>";
            last = link.end;
        }
        return '<div style="white-space: pre-wrap">' + html + root._escapeHtml(text.slice(last)) + "</div>";
    }

    // Only over a link's characters, not the empty space after it at a
    // line's end
    function _linkAt(x: real, y: real): string {
        const pos = editor.positionAt(x, y);
        for (const i of [pos, pos - 1]) {
            const link = root.links.find(l => i >= l.start && i < l.end);
            if (!link)
                continue;
            const a = editor.positionToRectangle(i);
            const b = editor.positionToRectangle(i + 1);
            if (y >= a.y && y < a.y + a.height && (a.y !== b.y || (x >= Math.min(a.x, b.x) && x <= Math.max(a.x, b.x))))
                return link.url;
        }
        return "";
    }

    // Keeps the cursor in view while typing
    function _ensureVisible(r: rect): void {
        if (flick.contentY >= r.y)
            flick.contentY = r.y;
        else if (flick.contentY + flick.height <= r.y + r.height)
            flick.contentY = r.y + r.height - flick.height;
    }

    Flickable {
        id: flick

        anchors.fill: parent
        contentWidth: width
        contentHeight: editor.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        TextEdit {
            id: editor

            width: flick.width
            // Clicks anywhere below the text still land in it
            height: Math.max(implicitHeight, flick.height)
            textFormat: TextEdit.PlainText
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            font.pixelSize: 14
            color: root.hasLinks ? "transparent" : "#e6e6e6"
            selectedTextColor: root.hasLinks ? "transparent" : "#ffffff"
            selectionColor: "#333333"

            onCursorRectangleChanged: root._ensureVisible(cursorRectangle)

            // The text color is transparent under the overlay, and the
            // default cursor takes that color
            cursorDelegate: Rectangle {
                id: cursor

                property bool blinkOn: true

                width: 2
                color: "#e6e6e6"
                visible: editor.cursorVisible
                opacity: cursor.blinkOn ? 1 : 0

                Timer {
                    id: blink

                    interval: 530
                    repeat: true
                    running: editor.activeFocus
                    onTriggered: cursor.blinkOn = !cursor.blinkOn
                }

                Connections {
                    target: editor

                    function onCursorPositionChanged() {
                        cursor.blinkOn = true;
                        blink.restart();
                    }
                }
            }

            HoverHandler {
                id: hover

                cursorShape: root.hoveredLink !== "" && (hover.point.modifiers & Qt.ControlModifier)
                    ? Qt.PointingHandCursor : Qt.IBeamCursor
            }

            TapHandler {
                acceptedModifiers: Qt.ControlModifier
                onTapped: eventPoint => {
                    const url = root._linkAt(eventPoint.position.x, eventPoint.position.y);
                    if (url !== "")
                        Qt.openUrlExternally(url);
                }
            }
        }

        // Draws the text over the editor; disabled, so the mouse goes through
        TextEdit {
            width: editor.width
            visible: root.hasLinks
            enabled: false
            readOnly: true
            textFormat: TextEdit.RichText
            wrapMode: TextEdit.Wrap
            font: editor.font
            color: "#e6e6e6"
            text: root.hasLinks ? root._html(editor.text, root.links) : ""
        }

        Text {
            visible: editor.text.length === 0
            text: root.placeholder
            color: "#4a4a4a"
            font: editor.font
        }
    }
}
