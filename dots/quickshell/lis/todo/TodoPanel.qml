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

    TodoState {
        id: todoState
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
            text: "To-do"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#dddddd"
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter

            text: {
                const total = todoState.tasks.length;
                const done = todoState.tasks.filter(t => t.done).length;
                return total > 0 ? (done + "/" + total) : "";
            }

            font.pixelSize: 12
            color: "#666666"
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
        anchors.margins: 24
        anchors.topMargin: 20
        spacing: 14

        // Add task input
        Rectangle {
            Layout.fillWidth: true
            height: 40
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
                        text: "Add a task…"
                        color: "#555555"
                        font.pixelSize: 13
                        visible: input.text.length === 0
                    }

                    Keys.onReturnPressed: {
                        todoState.addTask(input.text);
                        input.text = "";
                    }
                    Keys.onEnterPressed: {
                        todoState.addTask(input.text);
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
                            todoState.addTask(input.text);
                            input.text = "";
                        }
                    }
                }
            }
        }

        // Task list
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick

                anchors.fill: parent
                contentWidth: width
                contentHeight: list.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                pressDelay: 0
                flickableDirection: Flickable.VerticalFlick

                Item {
                    id: list

                    readonly property real rowHeight: 44
                    readonly property real rowSpacing: 4
                    readonly property real rowStep: rowHeight + rowSpacing

                    property var orderIds: []
                    property bool dragActive: false
                    property real draggedId: -1
                    property int draggedFromIndex: -1
                    property int draggedGroupStart: 0
                    property int draggedGroupEnd: 0

                    function syncOrderFromState() {
                        if (list.dragActive) {
                            return;
                        }
                        list.orderIds = todoState.sorted().map(t => t.id);
                    }

                    Component.onCompleted: syncOrderFromState()

                    Connections {
                        target: todoState
                        function onTasksChanged() {
                            list.syncOrderFromState();
                        }
                    }

                    width: flick.width
                    height: Math.max(0, list.orderIds.length * list.rowStep - list.rowSpacing)

                    Repeater {
                        id: repeater

                        model: todoState.tasks

                        delegate: TodoItem {
                            id: delegateItem

                            required property var modelData

                            readonly property int slot: list.orderIds.indexOf(modelData.id)
                            readonly property bool isDragged: list.dragActive && modelData.id === list.draggedId

                            width: list.width
                            visible: delegateItem.slot !== -1
                            y: delegateItem.isDragged ? delegateItem.dragY : delegateItem.slot * list.rowStep

                            Behavior on y {
                                enabled: !delegateItem.isDragged
                                NumberAnimation {
                                    duration: 150
                                    easing.type: Easing.OutCubic
                                }
                            }

                            z: delegateItem.isDragged ? 10 : 0

                            taskId: modelData.id
                            text: modelData.text
                            done: modelData.done
                            important: modelData.important

                            onToggleDone: todoState.toggleDone(delegateItem.taskId)
                            onToggleImportant: todoState.toggleImportant(delegateItem.taskId)
                            onRemoveRequested: todoState.removeTask(delegateItem.taskId)

                            onDragStarted: {
                                const startIndex = list.orderIds.indexOf(delegateItem.taskId);
                                if (startIndex === -1) {
                                    return;
                                }
                                list.dragActive = true;
                                list.draggedId = delegateItem.taskId;
                                list.draggedFromIndex = startIndex;

                                let groupStart = startIndex;
                                let groupEnd = startIndex;
                                const sameGroup = (id) => {
                                    const t = todoState.tasks.find(x => x.id === id);
                                    return t && t.important === delegateItem.important;
                                };
                                while (groupStart > 0 && sameGroup(list.orderIds[groupStart - 1])) {
                                    groupStart--;
                                }
                                while (groupEnd < list.orderIds.length - 1 && sameGroup(list.orderIds[groupEnd + 1])) {
                                    groupEnd++;
                                }
                                list.draggedGroupStart = groupStart;
                                list.draggedGroupEnd = groupEnd;

                                delegateItem.dragY = startIndex * list.rowStep;
                            }
                            onDragMoved: (y) => {
                                if (!delegateItem.isDragged) {
                                    return;
                                }
                                delegateItem.dragY = y - list.rowHeight / 2;

                                let targetIndex = Math.round(delegateItem.dragY / list.rowStep);
                                targetIndex = Math.max(list.draggedGroupStart, Math.min(targetIndex, list.draggedGroupEnd));

                                const currentIndex = list.orderIds.indexOf(delegateItem.taskId);
                                if (targetIndex !== currentIndex) {
                                    const newOrder = list.orderIds.slice();
                                    const [moved] = newOrder.splice(currentIndex, 1);
                                    newOrder.splice(targetIndex, 0, moved);
                                    list.orderIds = newOrder;
                                }
                            }
                            onDragEnded: {
                                if (!delegateItem.isDragged) {
                                    return;
                                }
                                delegateItem.dragY = delegateItem.slot * list.rowStep;

                                const finalOrder = list.orderIds.slice();
                                list.dragActive = false;
                                list.draggedId = -1;
                                list.draggedFromIndex = -1;

                                todoState.applyOrder(finalOrder);
                            }
                        }
                    }
                }
            }

            // Empty state
            Text {
                anchors.centerIn: parent
                visible: todoState.tasks.length === 0
                text: "No tasks yet"
                color: "#444444"
                font.pixelSize: 13
            }
        }

        // Clear done button
        Rectangle {
            Layout.fillWidth: true
            height: 38
            radius: 8
            visible: todoState.tasks.some(t => t.done)
            color: clearHover.containsMouse ? "#252525" : "#1a1a1a"
            border.color: "#2a2a2a"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "Clear completed"
                color: "#888888"
                font.pixelSize: 13
            }

            MouseArea {
                id: clearHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: todoState.clearDone()
            }

            Behavior on color {
                ColorAnimation {
                    duration: 100
                }
            }
        }
    }
}
