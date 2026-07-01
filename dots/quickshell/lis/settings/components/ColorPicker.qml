import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.data
import qs.settings.pages
import qs.settings

Item {
    id: root

    property string value: "#5c8aff"
    signal selected(string val)

    implicitWidth: trigger.width
    implicitHeight: trigger.height

    property real hue: 0
    property real sat: 0
    property real val2: 0
    property real alpha: 1.0

    function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

    function hexToHsv(hex) {
        let h = hex.replace("#", "")
        if (h.length === 8) {
            root.alpha = parseInt(h.substring(6, 8), 16) / 255
            h = h.substring(0, 6)
        } else {
            root.alpha = 1.0
        }
        if (h.length !== 6) return
        const r = parseInt(h.substring(0, 2), 16) / 255
        const g = parseInt(h.substring(2, 4), 16) / 255
        const b = parseInt(h.substring(4, 6), 16) / 255
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b)
        const d = mx - mn
        let hh = 0
        if (d !== 0) {
            if (mx === r) hh = ((g - b) / d) % 6
            else if (mx === g) hh = (b - r) / d + 2
            else hh = (r - g) / d + 4
        }
        hh = hh * 60
        if (hh < 0) hh += 360
        root.hue = hh
        root.sat = mx === 0 ? 0 : d / mx
        root.val2 = mx
    }

    function hsvToHex() {
        const c = root.val2 * root.sat
        const x = c * (1 - Math.abs(((root.hue / 60) % 2) - 1))
        const m = root.val2 - c
        let r = 0, g = 0, b = 0
        const hh = root.hue
        if (hh < 60)      { r = c; g = x; b = 0 }
        else if (hh < 120) { r = x; g = c; b = 0 }
        else if (hh < 180) { r = 0; g = c; b = x }
        else if (hh < 240) { r = 0; g = x; b = c }
        else if (hh < 300) { r = x; g = 0; b = c }
        else               { r = c; g = 0; b = x }
        const ri = Math.round((r + m) * 255)
        const gi = Math.round((g + m) * 255)
        const bi = Math.round((b + m) * 255)
        const toHex = n => n.toString(16).padStart(2, "0")
        let hex = "#" + toHex(ri) + toHex(gi) + toHex(bi)
        if (root.alpha < 1.0) hex += toHex(Math.round(root.alpha * 255))
        return hex
    }

    function commit() {
        const hex = hsvToHex()
        root.value = hex
        root.selected(hex)
    }

    Component.onCompleted: hexToHsv(root.value)
    onValueChanged: {
        if (!popup.opened) hexToHsv(root.value)
    }

    // rigger button: swatch + hex label
    Rectangle {
        id: trigger
        width: 132
        height: 30
        radius: 8
        color: mouseArea.containsMouse ? "#1affffff" : "#14ffffff"
        border.color: popup.opened ? "#5c8aff" : "#22ffffff"
        border.width: 1

        Behavior on color { ColorAnimation { duration: 100 } }
        Behavior on border.color { ColorAnimation { duration: 100 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 10
            spacing: 8

            Rectangle {
                width: 20; height: 20
                radius: 5
                color: root.value
                border.color: "#33ffffff"
                border.width: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.value.toUpperCase()
                font.pixelSize: 12
                color: "#eeffffff"
                elide: Text.ElideRight
            }

            Text {
                text: "⌄"
                font.pixelSize: 10
                color: "#88ffffff"
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.opened ? popup.close() : popup.open()
        }
    }

    // popup with full SV square + hue strip + hex input
    Popup {
        id: popup
        y: trigger.height + 6
        x: 0
        width: 240
        padding: 14
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent
        modal: false

        background: Rectangle {
            color: "#1e1e1e"
            radius: 12
            border.color: "#22ffffff"
            border.width: 1
            layer.enabled: true
        }

        onOpened: hexToHsv(root.value)
        onClosed: root.commit()

        contentItem: ColumnLayout {
            spacing: 12

            // SV square
            Item {
                id: svSquare
                Layout.fillWidth: true
                Layout.preferredHeight: 160

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#ffffff" }
                        GradientStop { position: 1.0; color: Qt.hsva(root.hue / 360, 1, 1, 1) }
                    }

                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: "#000000" }
                        }
                    }
                }

                Rectangle {
                    width: 14; height: 14; radius: 7
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: 2
                    x: root.sat * svSquare.width - width / 2
                    y: (1 - root.val2) * svSquare.height - height / 2

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -1
                        radius: 8
                        color: "transparent"
                        border.color: "#33000000"
                        border.width: 1
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    function update(mx, my) {
                        const cx = root.clamp(mx, 0, svSquare.width)
                        const cy = root.clamp(my, 0, svSquare.height)
                        root.sat = cx / svSquare.width
                        root.val2 = 1 - cy / svSquare.height
                        root.commit()
                    }

                    onPressed: mouse => update(mouse.x, mouse.y)
                    onPositionChanged: mouse => { if (pressed) update(mouse.x, mouse.y) }
                }
            }

            // Hue strip
            Item {
                id: hueStrip
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.000; color: "#ff0000" }
                        GradientStop { position: 0.167; color: "#ffff00" }
                        GradientStop { position: 0.333; color: "#00ff00" }
                        GradientStop { position: 0.500; color: "#00ffff" }
                        GradientStop { position: 0.667; color: "#0000ff" }
                        GradientStop { position: 0.833; color: "#ff00ff" }
                        GradientStop { position: 1.000; color: "#ff0000" }
                    }
                }

                Rectangle {
                    width: 6
                    height: hueStrip.height + 4
                    radius: 3
                    color: "#ffffff"
                    border.color: "#33000000"
                    border.width: 1
                    y: -2
                    x: (root.hue / 360) * (hueStrip.width - width)
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    function update(mx) {
                        const cx = root.clamp(mx, 0, hueStrip.width)
                        root.hue = (cx / hueStrip.width) * 360
                        root.commit()
                    }

                    onPressed: mouse => update(mouse.x)
                    onPositionChanged: mouse => { if (pressed) update(mouse.x) }
                }
            }

            // Alpha strip
            Item {
                id: alphaStrip
                Layout.fillWidth: true
                Layout.preferredHeight: 18

                Rectangle {
                    anchors.fill: parent
                    radius: 9
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: Qt.hsva(root.hue / 360, root.sat, root.val2, 1) }
                    }
                    border.color: "#22ffffff"
                    border.width: 1
                }

                Rectangle {
                    width: 6
                    height: alphaStrip.height + 4
                    radius: 3
                    color: "#ffffff"
                    border.color: "#33000000"
                    border.width: 1
                    y: -2
                    x: root.alpha * (alphaStrip.width - width)
                }

                MouseArea {
                    anchors.fill: parent
                    preventStealing: true

                    function update(mx) {
                        const cx = root.clamp(mx, 0, alphaStrip.width)
                        root.alpha = cx / alphaStrip.width
                        root.commit()
                    }

                    onPressed: mouse => update(mouse.x)
                    onPositionChanged: mouse => { if (pressed) update(mouse.x) }
                }
            }

            // Hex input + preview
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 28; height: 28
                    radius: 8
                    color: root.value
                    border.color: "#22ffffff"
                    border.width: 1
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 30
                    radius: 8
                    color: hexField.activeFocus ? "#1affffff" : "#14ffffff"
                    border.color: hexField.activeFocus ? "#5c8aff" : "#22ffffff"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 100 } }

                    TextInput {
                        id: hexField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        text: root.value.toUpperCase()
                        color: "#eeffffff"
                        font.pixelSize: 12
                        selectByMouse: true
                        maximumLength: 9
                        validator: RegularExpressionValidator { regularExpression: /#?[0-9A-Fa-f]{0,8}/ }

                        onEditingFinished: {
                            let v = text.startsWith("#") ? text : "#" + text
                            if (/^#[0-9A-Fa-f]{6}$|^#[0-9A-Fa-f]{8}$/.test(v)) {
                                root.hexToHsv(v)
                                root.commit()
                            } else {
                                text = root.value.toUpperCase()
                            }
                        }
                    }
                }
            }

            // Quick presets row
            Row {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["#5c8aff", "#ff6b6b", "#51cf66", "#ffd43b", "#cc5de8", "#22d3ee", "#ff922b", "#ffffff"]
                    delegate: Rectangle {
                        required property string modelData
                        width: 20; height: 20
                        radius: 5
                        color: modelData
                        border.color: root.value.toLowerCase() === modelData.toLowerCase() ? "#ffffff" : "#22ffffff"
                        border.width: root.value.toLowerCase() === modelData.toLowerCase() ? 2 : 1

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.hexToHsv(modelData)
                                root.commit()
                            }
                        }
                    }
                }
            }
        }
    }
}
