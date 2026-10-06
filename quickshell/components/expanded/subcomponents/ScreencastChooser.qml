import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

FocusScope {
    id: root
    required property var req
    signal accepted(var uris)
    signal cancelled()
    
    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.cancelled()
    }
    Keys.onEscapePressed: cancelled()
    Component.onCompleted: forceActiveFocus()

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Text {
            text: (req.app_id ? capitalizeFirstLetter(req.app_id) : "An application") + " wants to share your screen" 
            color: "white"
            font.family: root.font
            font.pixelSize: root.fontSize
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            Repeater {
                model: Quickshell.screens

                delegate: Rectangle {
                    required property var modelData
                    visible: (root.req.outputs || []).includes(modelData.name)
                    Layout.fillWidth: visible
                    Layout.fillHeight: visible
                    Layout.preferredWidth: visible ? 1 : 0
                    radius: 12
                    clip: true
                    color: "#222"
                    border.width: area.containsMouse ? 2 : 0
                    border.color: "#3cce5f"
                    
                    ScreencopyView {
                        anchors.fill: parent
                        anchors.margins: 5
                        captureSource: parent.modelData
                        live: true
                    }
                    Text {
                        anchors { left: parent.left; bottom: parent.bottom; margins: 8 }
                        text: parent.modelData.name
                        color: "white"
                        style: Text.Outline
                        styleColor: "#aa000000"
                        font.family: root.font
                        font.pixelSize: root.fontSize
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.accepted([parent.modelData.name])
                    }
                }
            }
        }
    }
}