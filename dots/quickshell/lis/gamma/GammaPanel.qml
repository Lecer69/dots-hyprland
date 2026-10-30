import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    readonly property int presetColumns: 2
    readonly property int presetCellHeight: 56
    readonly property int presetCellSpacing: 8
    readonly property int presetRows: Math.max(2, Math.min(Math.ceil(gammaState.presets.length / presetColumns), 6))
    readonly property int presetListHeight: presetRows * (presetCellHeight + presetCellSpacing) - presetCellSpacing

    implicitWidth: 460
    implicitHeight: header.height + content.implicitHeight + content.anchors.topMargin + content.anchors.bottomMargin

    GammaState {
        id: gammaState
    }

    // Removing a preset rebuilds every cell, so focus returns once they're back
    function removePreset(index: int, id: real): void {
        gammaState.removePreset(id)
        Qt.callLater(() => presetRepeater.itemAt(Math.min(index, presetRepeater.count - 1))?.forceActiveFocus())
    }

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Display"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            font.pixelSize: 12
            color: closeHover.containsMouse ? "#dddddd" : "#666666"

            MouseArea {
                id: closeHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }

    }

    ColumnLayout {
        id: content

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 20

        GammaSlider {
            label: "Brightness"
            value: gammaState.brightness
            onMoved: function(v) {
                gammaState.brightness = v;
            }
            onReleased: function(v) {
                gammaState.brightness = v;
                gammaState.apply();
            }
        }

        GammaSlider {
            label: "Contrast"
            value: gammaState.contrast
            onMoved: function(v) {
                gammaState.contrast = v;
            }
            onReleased: function(v) {
                gammaState.contrast = v;
                gammaState.apply();
            }
        }

        GammaSlider {
            label: "Gamma"
            value: gammaState.gamma
            onMoved: function(v) {
                gammaState.gamma = v;
            }
            onReleased: function(v) {
                gammaState.gamma = v;
                gammaState.apply();
            }
        }

        GammaSlider {
            label: "Saturation"
            value: gammaState.saturation
            onMoved: function(v) {
                gammaState.saturation = v;
            }
            onReleased: function(v) {
                gammaState.saturation = v;
                gammaState.apply();
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Presets"
                    color: "#6b6b6b"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                Text {
                    text: gammaState.presets.length > 0 ? gammaState.presets.length : ""
                    color: "#6b6b6b"
                    font.pixelSize: 12
                }

            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 8
                color: "#161616"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    TextInput {
                        id: input

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: "#e6e6e6"
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        activeFocusOnTab: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Save current as preset…"
                            color: "#6b6b6b"
                            font.pixelSize: 13
                            visible: input.text.length === 0
                        }

                        Keys.onReturnPressed: {
                            gammaState.addPreset(input.text);
                            input.text = "";
                        }
                        Keys.onEnterPressed: {
                            gammaState.addPreset(input.text);
                            input.text = "";
                        }
                    }

                    Text {
                        text: "+"
                        font.pixelSize: 16
                        color: addHover.containsMouse ? "#ffffff" : "#808080"

                        MouseArea {
                            id: addHover

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                gammaState.addPreset(input.text);
                                input.text = "";
                            }
                        }
                    }

                }

            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                implicitHeight: root.presetListHeight

                Flickable {
                    id: flick

                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: presetGrid.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    flickableDirection: Flickable.VerticalFlick

                    Grid {
                        id: presetGrid

                        width: flick.width
                        columns: root.presetColumns
                        spacing: root.presetCellSpacing

                        Repeater {
                            id: presetRepeater

                            model: gammaState.presets

                            delegate: GammaPresetItem {
                                id: preset

                                required property var modelData
                                required property int index

                                function focusAt(i: int): void {
                                    presetRepeater.itemAt(i)?.forceActiveFocus()
                                }

                                width: (presetGrid.width - presetGrid.spacing * (presetGrid.columns - 1)) / presetGrid.columns
                                height: root.presetCellHeight
                                presetId: modelData.id
                                name: modelData.name
                                gamma: modelData.gamma
                                brightness: modelData.brightness
                                contrast: modelData.contrast
                                saturation: modelData.saturation
                                onApplyRequested: gammaState.applyPreset(presetId)
                                onRemoveRequested: gammaState.removePreset(presetId)

                                Keys.onLeftPressed: preset.focusAt(preset.index - 1)
                                Keys.onRightPressed: preset.focusAt(preset.index + 1)
                                Keys.onUpPressed: preset.focusAt(preset.index - presetGrid.columns)
                                Keys.onDownPressed: preset.focusAt(preset.index + presetGrid.columns)
                                Keys.onDeletePressed: root.removePreset(preset.index, presetId)
                            }
                        }

                    }

                }

                Text {
                    anchors.centerIn: parent
                    visible: gammaState.presets.length === 0
                    text: "No presets yet"
                    color: "#6b6b6b"
                    font.pixelSize: 13
                }

            }

        }

        Rectangle {
            Layout.alignment: Qt.AlignRight
            Layout.topMargin: -8
            Layout.preferredHeight: 28
            Layout.preferredWidth: resetLabel.implicitWidth + 24
            radius: 6
            color: resetHover.pressed ? "#333333" : resetHover.containsMouse || activeFocus ? "#2a2a2a" : "#1f1f1f"

            activeFocusOnTab: true
            Keys.onSpacePressed: gammaState.reset()
            Keys.onReturnPressed: gammaState.reset()
            Keys.onEnterPressed: gammaState.reset()

            Text {
                id: resetLabel

                anchors.centerIn: parent
                text: "Reset to defaults"
                color: "#e6e6e6"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            MouseArea {
                id: resetHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: gammaState.reset()
            }

        }

    }

}
