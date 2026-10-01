import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.utils

Scope {
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
            exclusiveZone: Config.reservedSpace
            color: "transparent"

            implicitWidth: Config.maxWidth
            implicitHeight: Config.maxHeight

            mask: Region { item: pill }

            Rectangle {
                id: pill

                readonly property var layout: Island.layouts[Island.activity]
                readonly property size target: Island.currentSize

                readonly property var views: ({
                    idle:         { compact: idleCompact,  expanded: idleExpanded },
                    notification: { compact: notifCompact, expanded: notifExpanded }
                })

                anchors.horizontalCenter: parent.horizontalCenter
                y: 0

                width: target.width + (Island.hovered && !Island.expanded ? 16 : 0)
                height: target.height
                radius: Math.min(height / 2, 34)
                color: root.pillColor
                clip: false

                Behavior on width  { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }

                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        const v = pill.views[Island.activity]
                        return Island.expanded ? v.expanded : v.compact
                    }
                }

                Component {
                    id: idleCompact
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatTime(clock.date, "hh:mm")
                        color: root.textColor
                        font { family: root.font; pixelSize: root.fontSize; bold: true }
                    }
                }

                Component {
                    id: idleExpanded
                    Item {
                        anchors.fill: parent
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatTime(clock.date, "hh:mm:ss")
                                color: root.textColor
                                font { family: root.font; pixelSize: root.fontSizeBig; bold: true }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                                color: root.textColorSecondary
                                font { family: root.font; pixelSize: root.fontSize - 2 }
                            }
                        }
                    }
                }

                Component {
                    id: notifCompact
                    Item {
                        anchors.fill: parent
                        RowLayout {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            anchors.leftMargin: 10
                            anchors.left: parent.left
                            Text {
                                verticalAlignment: Text.AlignVCenter
                                text: Island.notification ? Icons.bell : ""
                                color: "white"; font.bold: true
                                font.family: root.iconFont
                            }
                            Text {
                                verticalAlignment: Text.AlignVCenter
                                text: Island.notification ? Island.notification.appName : ""
                                color: "white"; font.bold: true
                                font.family: root.font
                            }
                        }
                    }
                }

                Component {
                    id: notifExpanded
                    Item {
                        anchors.fill: parent
                        Column {
                            width: parent.width - 32
                            spacing: 15
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 15
                            anchors.leftMargin: 15
                            RowLayout {
                                width: parent.width
                                spacing: 15
                                Image {
                                    Layout.preferredWidth: 40 
                                    Layout.preferredHeight: 40
                                    fillMode: Image.PreserveAspectFit
                                    source: Island.notification ? Quickshell.iconPath(Island.notification.appName) : ""
                                    asynchronous: false
                                    cache: false
                                }
                                Text {
                                    Layout.fillWidth: true 
                                    elide: Text.ElideRight
                                    text: Island.notification ? (Island.notification.summary) : ""
                                    color: "white"; font.bold: true
                                    font.family: root.font
                                }
                            }   
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                maximumLineCount: 3
                                wrapMode: Text.Wrap
                                text: Island.notification ? (Island.notification.body || "") : ""
                                color: root.textColorSecondary
                                font.family: root.font
                            }

                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: Island.hovered = containsMouse
                    onClicked: Island.expanded = !Island.expanded
                }
            }
        }
    }
}