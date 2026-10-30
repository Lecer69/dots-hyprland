import QtQuick
import Quickshell

// Cover colours; ColorQuantizer only reads local files, so the shown cover is grabbed to a cache file
Item {
    id: root

    property Image source: null
    property bool active: false
    property color fallback: "#89b4fa"
    property int _shot: 0

    // Most vivid first; greys left out
    readonly property var vivid: {
        const colors = quantizer.colors ?? []
        const out = []
        for (let i = 0; i < colors.length; i++) {
            const c = colors[i]
            if (c.hslSaturation > 0.18 && c.hslLightness > 0.08 && c.hslLightness < 0.92)
                out.push(c)
        }
        const score = c => c.hslSaturation * (1 - Math.abs(c.hslLightness - 0.5) * 1.5)
        return out.sort((a, b) => score(b) - score(a))
    }
    // Darkest first
    readonly property var tones: {
        const colors = quantizer.colors ?? []
        const out = []
        for (let i = 0; i < colors.length; i++)
            out.push(colors[i])
        return out.sort((a, b) => a.hslLightness - b.hslLightness)
    }
    // Black and white
    readonly property bool mono: root.vivid.length === 0 && root.tones.length > 0

    readonly property color base: root.vivid[0] ?? root.fallback
    readonly property real hue: Math.max(0, root.base.hslHue)
    readonly property real saturation: Math.max(0.45, root.base.hslSaturation)

    // Light enough to read on the dark panel
    property color accent: root.mono ? root.grey(root.tones[root.tones.length - 1], 0.84, 0.9)
        : Qt.hsla(root.hue, root.saturation, Math.max(0.62, Math.min(0.74, root.base.hslLightness)), 1)
    // The shader's three colours, dark to light
    property color deep: root.mono ? root.grey(root.tones[0], 0.06, 0.16) : Qt.hsla(root.hue, root.saturation * 0.8, 0.16, 1)
    property color mid: root.mono ? root.grey(root.tones[Math.floor(root.tones.length / 2)], 0.22, 0.36) : root.shade(root.vivid[1], 0.06, 0.38)
    property color light: root.mono ? root.grey(root.tones[root.tones.length - 1], 0.45, 0.6) : root.shade(root.vivid[2], -0.07, 0.55)

    Behavior on accent { ColorAnimation { duration: 700 } }
    Behavior on deep { ColorAnimation { duration: 700 } }
    Behavior on mid { ColorAnimation { duration: 700 } }
    Behavior on light { ColorAnimation { duration: 700 } }

    // Without a colour, the base hue shifted
    function shade(c: var, shift: real, lightness: real): color {
        const h = c ? Math.max(0, c.hslHue) : (root.hue + shift + 1) % 1
        const s = c ? Math.max(0.4, c.hslSaturation) : root.saturation
        return Qt.hsla(h, s, lightness, 1)
    }

    // Lightness clamped; a faint tint stays
    function grey(c: var, min: real, max: real): color {
        return Qt.hsla(Math.max(0, c.hslHue), c.hslSaturation, Math.max(min, Math.min(max, c.hslLightness)), 1)
    }

    function refresh(): void {
        const image = root.source
        if (!root.active || !image || image.status !== Image.Ready || image.width <= 0)
            return
        image.grabToImage(result => {
            const path = Quickshell.cachePath("media-cover.png")
            if (!result.saveToFile(path))
                return
            // A new query makes the quantizer read it again
            root._shot++
            quantizer.source = "file://" + path + "?" + root._shot
        }, Qt.size(64, 64))
    }

    ColorQuantizer {
        id: quantizer

        depth: 3
        rescaleSize: 64
    }
}
