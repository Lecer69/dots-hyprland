pragma Singleton

import QtQuick
import Quickshell

// Finds settings among the rows the pages have, so a new row needs no listing
Singleton {
    id: root

    // The rows as last read, for the launcher: they outlast the panel
    property var entries: []

    function remember(rows: var): void {
        root.entries = rows.map(e => Object.assign({}, e, { row: null }));
    }

    // { isSetting, label, description, section, page, pageName, row, name, text }, in page order
    function rows(pager: Item, pageNames: var): var {
        const out = [];
        for (let i = 0; i < pager.children.length; i++)
            root._collect(pager.children[i], i, pageNames[i], { section: "" }, out);
        return out;
    }

    function _collect(item: Item, page: int, pageName: string, context: var, out: var): void {
        for (const child of item.children) {
            if (typeof child.label === "string" && typeof child.description === "string") {
                if (child.label !== "" && child.available !== false) {
                    const name = child.label.toLowerCase();
                    out.push({
                        isSetting: true,
                        label: child.label,
                        description: child.description,
                        section: context.section,
                        page: page,
                        pageName: pageName,
                        row: child,
                        name: name,
                        text: [name, child.description, context.section, pageName].join(" ").toLowerCase()
                    });
                }
            } else if (typeof child.title === "string") {
                context.section = child.title;
            } else {
                root._collect(child, page, pageName, context, out);
            }
        }
    }

    // Names starting with the first word, then containing it, then the rest
    function search(list: var, query: string): var {
        const words = query.trim().toLowerCase().split(/\s+/).filter(w => w !== "");
        if (words.length === 0)
            return [];

        const hits = list.filter(e => words.every(w => e.text.includes(w)));
        return hits.filter(e => e.name.startsWith(words[0]))
            .concat(hits.filter(e => !e.name.startsWith(words[0]) && e.name.includes(words[0])))
            .concat(hits.filter(e => !e.name.includes(words[0])));
    }
}
