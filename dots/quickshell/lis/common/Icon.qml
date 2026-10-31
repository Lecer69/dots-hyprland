import QtQuick
import QtQuick.Effects

// A white SVG icon, tinted dark in light mode
Image {
    // Off for icons that aren't ours (app icons)
    property bool tint: true

    layer.enabled: Theme.light && tint
    layer.effect: MultiEffect {
        colorization: 1
        colorizationColor: Theme.adapt("#ffffff")
    }
}
