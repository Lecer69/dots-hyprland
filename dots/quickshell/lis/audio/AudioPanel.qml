pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.common

// Output, input, and the apps using audio, each on its own tab
PanelFrame {
    id: root

    property bool shown: false
    // 0 Output, 1 Input, 2 Apps
    property int tab: 0

    readonly property var audioNodes: Pipewire.nodes.values.filter(n => n.audio)
    readonly property var sinks: audioNodes.filter(n => !n.isStream && n.isSink)
    readonly property var sources: audioNodes.filter(n => !n.isStream && !n.isSink)
    // Apps playing and recording audio (isSink can't tell these apart).
    // Level meters, like this panel's own for the mic, aren't apps
    readonly property var streams: audioNodes.filter(n => n.isStream && n.properties["media.class"] === "Stream/Output/Audio")
    readonly property var recordings: audioNodes.filter(n => n.isStream && n.properties["media.class"] === "Stream/Input/Audio"
        && n.properties["stream.monitor"] !== "true")

    title: "Audio"
    // As tall as the tallest tab, so switching tabs doesn't resize it
    implicitHeight: headerHeight + 8 + tabs.implicitHeight + 20 + pages.implicitHeight + 24

    // Volume, mute and properties (media.class above) only update for
    // tracked nodes
    PwObjectTracker {
        objects: root.shown ? root.audioNodes : []
    }

    // Only while the meter shows: it records from the mic
    PwNodePeakMonitor {
        id: micLevel

        node: Pipewire.defaultAudioSource
        enabled: root.shown && root.tab === 1
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 20

        RowLayout {
            id: tabs

            spacing: 4

            Repeater {
                model: ["Output", "Input", "Apps"]

                delegate: Rectangle {
                    id: tabItem

                    required property string modelData
                    required property int index

                    readonly property bool active: root.tab === tabItem.index
                    // How many apps are using audio, on the Apps tab
                    readonly property int count: tabItem.index === 2 ? root.streams.length + root.recordings.length : 0

                    implicitWidth: tabLabel.implicitWidth + 24
                    implicitHeight: 30
                    radius: 6
                    color: tabItem.active ? "#1f1f1f" : tabArea.containsMouse ? "#161616" : "transparent"

                    Row {
                        id: tabLabel

                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            id: tabName

                            text: tabItem.modelData
                            color: tabItem.active ? "#ffffff" : tabArea.containsMouse ? "#cccccc" : "#808080"
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.baseline: tabName.baseline
                            visible: tabItem.count > 0
                            text: tabItem.count
                            color: "#6b6b6b"
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: tabArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.tab = tabItem.index
                    }
                }
            }
        }

        Flickable {
            id: flick

            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: pages.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            StackLayout {
                id: pages

                width: flick.width
                height: Math.max(implicitHeight, flick.height)
                currentIndex: root.tab

                // Output
                ColumnLayout {
                    spacing: 0

                    VolumeControl {
                        Layout.fillWidth: true
                        visible: Pipewire.defaultAudioSink !== null
                        node: Pipewire.defaultAudioSink
                    }

                    Text {
                        visible: root.sinks.length === 0
                        text: "No output devices"
                        color: "#6b6b6b"
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.topMargin: 24
                        Layout.bottomMargin: 8
                        visible: root.sinks.length > 1
                        text: "Device"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.sinks.length > 1
                        spacing: 2

                        Repeater {
                            model: root.sinks

                            AudioDeviceRow {
                                required property var modelData

                                Layout.fillWidth: true
                                node: modelData
                                selected: modelData === Pipewire.defaultAudioSink
                                onClicked: Pipewire.preferredDefaultAudioSink = modelData
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Input
                ColumnLayout {
                    spacing: 0

                    VolumeControl {
                        Layout.fillWidth: true
                        visible: Pipewire.defaultAudioSource !== null
                        node: Pipewire.defaultAudioSource
                        input: true
                    }

                    // Live microphone level, lined up under the slider
                    Item {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        Layout.leftMargin: 28
                        Layout.rightMargin: 48
                        visible: Pipewire.defaultAudioSource !== null
                        implicitHeight: 3

                        Rectangle {
                            anchors.fill: parent
                            radius: 1.5
                            color: "#1f1f1f"
                        }

                        Rectangle {
                            height: parent.height
                            radius: 1.5
                            width: parent.width * Math.min(1, micLevel.peak)
                            color: "#808080"

                            Behavior on width { NumberAnimation { duration: 80 } }
                        }
                    }

                    Text {
                        visible: root.sources.length === 0
                        text: "No input devices"
                        color: "#6b6b6b"
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.topMargin: 24
                        Layout.bottomMargin: 8
                        visible: root.sources.length > 1
                        text: "Device"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.sources.length > 1
                        spacing: 2

                        Repeater {
                            model: root.sources

                            AudioDeviceRow {
                                required property var modelData

                                Layout.fillWidth: true
                                node: modelData
                                selected: modelData === Pipewire.defaultAudioSource
                                onClicked: Pipewire.preferredDefaultAudioSource = modelData
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }

                // Apps
                ColumnLayout {
                    spacing: 0

                    Text {
                        visible: root.streams.length === 0 && root.recordings.length === 0
                        text: "No apps are playing or recording"
                        color: "#6b6b6b"
                        font.pixelSize: 13
                    }

                    Text {
                        Layout.bottomMargin: 10
                        visible: root.streams.length > 0
                        text: "Playing"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.streams.length > 0
                        spacing: 14

                        Repeater {
                            model: root.streams

                            AudioStreamItem {
                                required property var modelData

                                Layout.fillWidth: true
                                node: modelData
                            }
                        }
                    }

                    Text {
                        Layout.topMargin: root.streams.length > 0 ? 24 : 0
                        Layout.bottomMargin: 10
                        visible: root.recordings.length > 0
                        text: "Recording"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        visible: root.recordings.length > 0
                        spacing: 14

                        Repeater {
                            model: root.recordings

                            AudioStreamItem {
                                required property var modelData

                                Layout.fillWidth: true
                                node: modelData
                                input: true
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
