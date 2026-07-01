pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Column {
    id: root

    required property string categoryName
    readonly property bool isCategorized: categoryName.length > 0

    property int maxBindWidth: 0
    property real columnSpacing: 20
    property real titleSpacing: 8

    property color accentColor: "#f38ba8"
    property color textColor: "#dddddd"
    property color dimTextColor: "#888888"
    property color keyBgColor: "#1a1a1a"
    property color keyBorderColor: "#2a2a2a"

    property int keyFontSize: 10
    property int descFontSize: 11
    property int titleFontSize: 13
    property real maxDescWidth: 260

    property var keyBlacklist: ["SUPER_L", "SUPER_R"]
    property var keySubstitutions: ({
        "Super": "Super",
        "mouse_up": "Scroll ↓",
        "mouse_down": "Scroll ↑",
        "mouse:272": "LMB",
        "mouse:273": "RMB",
        "mouse:275": "MouseBack",
        "Slash": "/",
        "Hash": "#",
        "Return": "Enter",
    })

    function modMaskToStringList(modMask) {
        const list = []
        if (modMask & (1 << 2)) list.push("Ctrl")
        if (modMask & (1 << 6)) list.push("Super")
        if (modMask & (1 << 0)) list.push("Shift")
        if (modMask & (1 << 3)) list.push("Alt")
        if (modMask & (1 << 1)) list.push("Caps")
        if (modMask & (1 << 4)) list.push("Mod2")
        if (modMask & (1 << 5)) list.push("Mod3")
        if (modMask & (1 << 7)) list.push("Mod5")
        return list
    }

    function hasDescription(bind) {
        return bind.description && bind.description.length > 0
    }

    function effectiveDescription(bind) {
        if (hasDescription(bind)) return bind.description
        const dispatcher = bind.dispatcher || ""
        const arg = bind.arg || ""
        if (!dispatcher && !arg) return ""
        return (dispatcher + (arg ? " " + arg : "")).trim()
    }

    function isCategory(bind, cat) {
        const desc = root.effectiveDescription(bind)
        const idx = desc.indexOf(":")
        if (idx <= 0) return false
        return desc.substring(0, idx).trim() === cat
    }

    function isUncategorized(bind) {
        const desc = root.effectiveDescription(bind)
        return hasDescription(bind) && desc.indexOf(":") === -1
    }

    function isRepetitiveKey(key) {
        if (!key) return false
        const k = key.toLowerCase()
        return k === "left" || k === "right" || k === "up" || k === "down"
            || (/^\d+$/.test(key))
    }

    function actionSignature(bind) {
        const key = bind.key || ""
        if (!isRepetitiveKey(key)) return ""

        const desc = root.effectiveDescription(bind)
        if (!desc) return ""

        const stripped = desc
            .replace(/\b(left|right|up|down)\b/gi, "")
            .replace(/\b\d+\b/g, "")
            .replace(/[ \t]{2,}/g, " ")
            .trim()

        if (!stripped) return ""

        return String(bind.modmask) + "\xA7" + stripped
    }

    function dedupe(arr) {
        const seen = Object.create(null)
        const out = []
        for (let i = 0; i < arr.length; i++) {
            const b = arr[i]
            const sig = actionSignature(b)
            if (sig === "") {
                out.push(b)
            } else if (!(sig in seen)) {
                seen[sig] = true
                out.push(b)
            }
        }
        return out
    }

    function transformKey(key) {
        if (!key) return ""
        const k = key.toLowerCase()
        if (k === "left" || k === "right" || k === "up" || k === "down")
            return "←/→/↑/↓"
        if (/^\d+$/.test(key))
            return "1..2..3..."
        return root.keySubstitutions[key] || key
    }

    function transformDescription(bind, cat) {
        const desc = root.effectiveDescription(bind)
        let text = desc

        // Strip category prefix (e.g. "Window: ")
        if (cat && cat.length > 0) {
            const re = new RegExp(
                "^\\s*" + cat.replace(/[.*+?^${}()|[\]\\]/g, "\\$&") + "\\s*:\\s*"
            )
            text = text.replace(re, "")
        }

        if (actionSignature(bind) === "") return text

        text = text.replace(/\b(left|right|up|down)\b/gi, "←/→/↑/↓")
        text = text.replace(/\b\d+\b/g, "1..2..3...")
        return text
    }

    visible: repeater.model.length > 0
    spacing: titleSpacing

    Row {
        spacing: 8

        Rectangle {
            width: 4
            height: titleText.implicitHeight
            radius: 2
            color: root.accentColor
        }

        Text {
            id: titleText
            text: root.isCategorized ? root.categoryName : "Uncategorized"
            font.pixelSize: root.titleFontSize
            font.weight: Font.DemiBold
            color: root.textColor
        }
    }

    Column {
        spacing: 4
        Repeater {
            id: repeater
            model: {
                const all = Array.from(CheatsheetService.keybinds)
                const filtered = all.filter(bind => {
                    if (!root.hasDescription(bind)) return false
                    if (root.isCategorized)
                        return root.isCategory(bind, root.categoryName)
                    else
                        return root.isUncategorized(bind)
                })
                return root.dedupe(filtered)
            }
            delegate: BindRow {
                required property var modelData
                keyData: modelData
                categoryName: root.categoryName
            }
        }
    }

    // Components
    component KeyCap: Rectangle {
        id: keyCap
        property string label: ""
        radius: 6
        color: root.keyBgColor
        border.width: 1
        border.color: root.keyBorderColor
        implicitWidth: Math.max(18, keyLabel.implicitWidth + 8)
        implicitHeight: keyLabel.implicitHeight + 5

        Text {
            id: keyLabel
            anchors.centerIn: parent
            text: keyCap.label
            font.pixelSize: root.keyFontSize
            font.family: "JetBrainsMono Nerd Font"
            color: root.textColor
        }
    }

    component BindRow: Row {
        id: bindRow
        required property var keyData
        property string categoryName: ""
        spacing: 12

        Item {
            id: modRow
            Component.onCompleted: root.maxBindWidth = Math.max(root.maxBindWidth, implicitWidth)
            width: root.maxBindWidth
            implicitWidth: pill.implicitWidth
            implicitHeight: pill.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: pill
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: innerRow.implicitWidth + 10
                implicitHeight: innerRow.implicitHeight + 6
                width: implicitWidth
                height: implicitHeight
                radius: 6
                color: root.keyBgColor
                border.width: 1
                border.color: root.keyBorderColor

                Row {
                    id: innerRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: root.modMaskToStringList(bindRow.keyData.modmask)
                        delegate: Item {
                            required property string modelData
                            width: modelData === "Super" ? 11 : modText.implicitWidth
                            height: modText.implicitHeight

                            Image {
                                id: superIcon
                                anchors.centerIn: parent
                                source: "../icons/windows.svg"
                                visible: modelData === "Super"
                                width: 11
                                height: 11
                                smooth: true
                            }

                            Text {
                                id: modText
                                anchors.centerIn: parent
                                visible: modelData !== "Super"
                                text: root.keySubstitutions[modelData] || modelData
                                font.pixelSize: root.keyFontSize
                                font.family: "JetBrainsMono Nerd Font"
                                color: root.textColor
                            }
                        }
                    }

                    Text {
                        visible: !root.keyBlacklist.includes(bindRow.keyData.key)
                        text: root.transformKey(bindRow.keyData.key)
                        font.pixelSize: root.keyFontSize
                        font.family: "JetBrainsMono Nerd Font"
                        color: root.textColor
                    }
                }
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: root.descFontSize
            color: root.dimTextColor
            text: root.transformDescription(bindRow.keyData, bindRow.categoryName)
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            width: Math.min(implicitWidth, root.maxDescWidth)
        }
    }
}