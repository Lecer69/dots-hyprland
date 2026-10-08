import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
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

    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Display"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#dddddd"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: closeHover.containsMouse ? "#252525" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: "#888888"
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    Rectangle {
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: "#222222"
    }

    ColumnLayout {
        id: content

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        anchors.topMargin: 28
        spacing: 20

        GammaSlider {
            label: "Brightness"
            value: gammaState.brightness
            accent: "#f9e2af"
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
            accent: "#89b4fa"
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
            accent: "#a6e3a1"
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
            accent: "#cba6f7"
            onMoved: function(v) {
                gammaState.saturation = v;
            }
            onReleased: function(v) {
                gammaState.saturation = v;
                gammaState.apply();
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: -4
            Layout.preferredHeight: 1
            color: "#222222"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            RowLayout {
                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Presets"
                    color: "#aaaaaa"
                    font.pixelSize: 13
                }

                Text {
                    text: gammaState.presets.length > 0 ? gammaState.presets.length : ""
                    color: "#666666"
                    font.pixelSize: 12
                }

            }

            // Save preset input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                radius: 8
                color: "#1a1a1a"
                border.color: input.activeFocus ? "#444444" : "#2a2a2a"
                border.width: 1

                Behavior on border.color {
                    ColorAnimation {
                        duration: 100
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 8
                    spacing: 8

                    TextInput {
                        id: input

                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        color: "#dddddd"
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Save current as preset…"
                            color: "#555555"
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

                    Rectangle {
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: addHover.containsMouse ? "#252525" : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#a6e3a1"
                        }

                        MouseArea {
                            id: addHover

                            anchors.fill: parent
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

            // Preset list
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
                            model: gammaState.presets

                            delegate: GammaPresetItem {
                                required property var modelData

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
                            }
                        }

                    }

                }

                // Empty state
                Text {
                    anchors.centerIn: parent
                    visible: gammaState.presets.length === 0
                    text: "No presets yet"
                    color: "#444444"
                    font.pixelSize: 13
                }

            }

        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: -12
            Layout.preferredHeight: 38
            radius: 8
            color: resetHover.containsMouse ? "#252525" : "#1a1a1a"
            border.color: "#2a2a2a"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Reset to defaults"
                color: "#888888"
                font.pixelSize: 13
            }

            MouseArea {
                id: resetHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: gammaState.reset()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }

            }

        }

    }

}
