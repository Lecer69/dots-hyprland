pragma Singleton

import QtQuick
import Quickshell
import qs.settings.data

// Colors are written as their dark values; light mode keeps each one's contrast against the panel
Singleton {
    id: root

    readonly property bool light: SettingsData.s.general.lightMode ?? false

    readonly property color panel: adapt("#0f0f0f")
    readonly property color hover: adapt("#161616")
    readonly property color border: adapt("#1f1f1f")
    readonly property color text: adapt("#e6e6e6")
    readonly property color textDim: adapt("#6b6b6b")
    // App icons tinted to one grey; a dark one would turn them into blobs
    readonly property color appIconTint: light ? "#555555" : "#e8e8e8"

    readonly property real _darkPanel: _luminance(Qt.color("#0f0f0f"))
    readonly property real _lightPanel: _luminance(Qt.color("#f5f5f5"))

    function _luminance(c: color): real {
        const f = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * f(c.r) + 0.7152 * f(c.g) + 0.0722 * f(c.b);
    }

    function adapt(value): color {
        const c = Qt.color(value);
        if (!root.light)
            return c;

        const y = root._luminance(c);
        const above = y >= root._darkPanel;
        let ratio = above ? (y + 0.05) / (root._darkPanel + 0.05) : (root._darkPanel + 0.05) / (y + 0.05);
        // A strong color turns muddy at text contrast
        if (Math.max(c.r, c.g, c.b) - Math.min(c.r, c.g, c.b) > 0.2)
            ratio = Math.min(ratio, 4.5);
        const target = above ? (root._lightPanel + 0.05) / ratio - 0.05 : Math.min(1, (root._lightPanel + 0.05) * ratio - 0.05);

        // Same hue and saturation, lightness searched for the target luminance
        const hue = Math.max(0, c.hslHue);
        let lo = 0, hi = 1, out = c;
        for (let i = 0; i < 16; i++) {
            const l = (lo + hi) / 2;
            out = Qt.hsla(hue, c.hslSaturation, l, c.a);
            if (root._luminance(out) < target)
                lo = l;
            else
                hi = l;
        }
        return out;
    }
}
