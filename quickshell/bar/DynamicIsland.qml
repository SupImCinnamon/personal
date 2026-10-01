import QtQuick
import Quickshell

ShellRoot {
    property int widthNormal: 100
    property int widthHovered: 110
    property int widthExpanded: 420
    property int heightNormal: 30
    property int heightHovered: 32
    property int heightExpanded: 120

    property int maxWidth: 520
    property int maxHeight: 200
    property int reservedSpace: 26

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors.top: true
            margins.top: 5
            exclusiveZone: reservedSpace
            color: "transparent"

            implicitWidth: maxWidth
            implicitHeight: maxHeight

            mask: Region { item: pill }

            Rectangle {
                id: pill

                property bool expanded: false
                property bool hovered: mouse.containsMouse

                anchors.horizontalCenter: parent.horizontalCenter
                y: 0

                width: expanded ? widthExpanded : (hovered ? widthHovered : widthNormal)
                height: expanded ? heightExpanded : (hovered ? heightHovered : heightNormal)
                radius: Math.min(height / 2, 34)
                color: root.pillColor
                clip: false

                Behavior on width  { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }

                Text {
                    anchors.centerIn: parent
                    visible: opacity > 0
                    opacity: pill.expanded ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    text: Qt.formatTime(clock.date, "hh:mm")
                    color: root.textColor
                    font {
                        family: root.font
                        pixelSize: root.fontSize
                        bold: true
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    visible: opacity > 0
                    opacity: pill.expanded ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, "hh:mm:ss")
                        color: "#FFFFFF"
                        font {
                            family: root.font
                            pixelSize: root.fontSizeBig
                            bold: true
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                        color: root.textColorSecondary
                        font {
                            family: root.font
                            pixelSize: root.fontSize - 1
                            
                        }
                    }
                }

                MouseArea {
                    id: mouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: pill.expanded = !pill.expanded
                }
            }
        }
    }
}