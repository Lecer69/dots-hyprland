pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import Quickshell.Widgets
import QtQuick

Variants {
    id: root

    required property PolkitAgent agent

    model: Quickshell.screens

    delegate: PanelWindow {
        id: win
        required property var modelData

        screen: modelData
        visible: root.agent.isActive
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "quickshell:polkitagent"

        readonly property var flow: root.agent.flow

        property string passwordBuffer: ""

        onVisibleChanged: {
            if (visible)
                passwordBuffer = ""
        }

        Connections {
            target: win.flow
            enabled: win.flow !== null
            function onIsCompletedChanged() {
                if (win.flow && win.flow.isCompleted)
                    win.passwordBuffer = ""
            }
        }

        Loader {
            id: contentLoader
            anchors.fill: parent
            active: win.visible
            sourceComponent: dialogContent
        }

        Component {
            id: dialogContent

            Item {
                id: contentRoot
                anchors.fill: parent

                readonly property alias keyItem: keyItem

                Component.onCompleted: keyItem.forceActiveFocus()

                readonly property color cBg:      '#080808'
                readonly property color cOverlay0: "#6c7086"
                readonly property color cOverlay1: "#7f849c"
                readonly property color cSubtext0: "#a6adc8"
                readonly property color cText:     "#cdd6f4"
                readonly property color cMauve:    "#cba6f7"
                readonly property color cRed:      "#f38ba8"
                readonly property color cYellow:   "#f9e2af"

                // Dim overlay
                Rectangle {
                    anchors.fill: parent
                    color: '#7f000000'
                }

                // Centred card
                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: 360
                    height: col.implicitHeight + 48
                    radius: 14
                    color: contentRoot.cBg

                    Column {
                        id: col
                        anchors {
                            top: parent.top
                            left: parent.left
                            right: parent.right
                            topMargin: 24
                            leftMargin: 24
                            rightMargin: 24
                        }
                        spacing: 14

                        // Title row
                        Row {
                            spacing: 10
                            width: parent.width

                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 20; height: 20
                                source: (win.flow && win.flow.iconName.length > 0)
                                        ? Quickshell.iconPath(win.flow.iconName)
                                        : Quickshell.iconPath("dialog-password")
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: "Authentication Required"
                                    color: contentRoot.cText
                                    font { pixelSize: 14; weight: 600 }
                                }
                                Text {
                                    text: win.flow ? win.flow.actionId : ""
                                    color: contentRoot.cOverlay1
                                    font { pixelSize: 11 }
                                    elide: Text.ElideMiddle
                                    width: 300
                                }
                            }
                        }

                        // Main message
                        Text {
                            width: parent.width
                            text: win.flow ? win.flow.message : ""
                            color: contentRoot.cSubtext0
                            font { pixelSize: 13 }
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        // Supplementary message
                        Text {
                            width: parent.width
                            text: win.flow ? win.flow.supplementaryMessage : ""
                            color: (win.flow && win.flow.supplementaryIsError) ? contentRoot.cRed : contentRoot.cYellow
                            font { pixelSize: 12 }
                            wrapMode: Text.WordWrap
                            visible: text.length > 0
                        }

                        // Identity picker
                        Column {
                            width: parent.width
                            spacing: 6
                            visible: win.flow ? win.flow.identities.length > 1 : false

                            Text {
                                text: "Authenticate as"
                                color: contentRoot.cOverlay1
                                font { pixelSize: 11 }
                            }

                            Repeater {
                                model: win.flow ? win.flow.identities : []
                                delegate: Rectangle {
                                    required property var modelData
                                    width: col.width
                                    height: 36
                                    radius: 14
                                    color: (win.flow && win.flow.selectedIdentity === modelData) ? "#1acba6f7" : "#88000000"

                                    Row {
                                        anchors {
                                            left: parent.left
                                            leftMargin: 12
                                            verticalCenter: parent.verticalCenter
                                        }
                                        spacing: 8

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "\uf007"
                                            font {
                                                pixelSize: 12
                                            }
                                            color: contentRoot.cOverlay0
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.toString()
                                            color: contentRoot.cText
                                            font {
                                                pixelSize: 13
                                            }
                                        }
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: win.flow.selectedIdentity = modelData
                                    }
                                }
                            }
                        }

                        // Password field
                        Column {
                            width: parent.width
                            spacing: 6

                            readonly property bool inputRequired: win.flow ? win.flow.isResponseRequired : false

                            opacity: inputRequired ? 1.0 : 0.35

                            Text {
                                text: win.flow ? win.flow.inputPrompt : "Password:"
                                color: contentRoot.cOverlay1
                                font {
                                    pixelSize: 11
                                }
                            }

                            Rectangle {
                                width: parent.width; height: 40
                                radius: 14
                                color: "#88000000"

                                Text {
                                    anchors {
                                        left: parent.left
                                        leftMargin: 14
                                        right: parent.right
                                        rightMargin: 14
                                        verticalCenter: parent.verticalCenter
                                    }
                                    text: win.passwordBuffer.length > 0
                                          ? Array(win.passwordBuffer.length + 1).join("●")
                                          : "Password…"
                                    color: win.passwordBuffer.length > 0 ? contentRoot.cText : contentRoot.cOverlay0
                                    font {
                                        pixelSize: win.passwordBuffer.length > 0 ? 10 : 13
                                        letterSpacing: win.passwordBuffer.length > 0 ? 4 : 0
                                    }
                                    clip: true
                                }
                            }
                        }

                        // Auth failed
                        Row {
                            spacing: 6
                            visible: win.flow ? win.flow.failed : false
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "\uf071"
                                font {
                                    pixelSize: 12
                                }
                                color: contentRoot.cRed
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Authentication failed"
                                color: contentRoot.cRed
                                font {
                                    pixelSize: 12
                                }
                            }
                        }

                        // Buttons
                        Row {
                            anchors.right: parent.right
                            spacing: 8

                            Rectangle {
                                width: 86; height: 34; radius: 14
                                color: cancelMa.containsMouse ? "#22ffffff" : "#00000000"

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: contentRoot.cSubtext0
                                    font {
                                        pixelSize: 13
                                    }
                                }

                                MouseArea {
                                    id: cancelMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.passwordBuffer = ""
                                        win.flow.cancelAuthenticationRequest()
                                    }
                                }
                            }

                            Rectangle {
                                width: 116; height: 34; radius: 14
                                color: authMa.containsMouse ? Qt.lighter(contentRoot.cMauve, 1.15) : contentRoot.cMauve

                                Behavior on color { ColorAnimation { duration: 120 } }

                                Text {
                                    anchors.centerIn: parent
                                    text: (win.flow && win.flow.isResponseRequired) ? "Authenticate" : "OK"
                                    color: "#1e1e2e"
                                    font {
                                        pixelSize: 13
                                        weight: 600
                                    }
                                }

                                MouseArea {
                                    id: authMa
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (win.flow && win.flow.isResponseRequired) {
                                            win.flow.submit(win.passwordBuffer)
                                            win.passwordBuffer = ""
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: 0
                        }
                    }
                }

                // Key capture
                Item {
                    id: keyItem
                    anchors.fill: parent
                    focus: true

                    Keys.onPressed: (event) => {
                        if (!win.flow) return

                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (win.flow.isResponseRequired) {
                                win.flow.submit(win.passwordBuffer)
                                win.passwordBuffer = ""
                            }
                            event.accepted = true

                        } else if (event.key === Qt.Key_Escape) {
                            win.passwordBuffer = ""
                            win.flow.cancelAuthenticationRequest()
                            event.accepted = true

                        } else if (event.key === Qt.Key_Backspace) {
                            if (win.flow.isResponseRequired && win.passwordBuffer.length > 0)
                                win.passwordBuffer = win.passwordBuffer.slice(0, -1)
                            event.accepted = true

                        } else if (event.text.length > 0 && !event.isAutoRepeat && win.flow.isResponseRequired) {
                            win.passwordBuffer += event.text
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
