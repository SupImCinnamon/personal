import QtQuick
import Quickshell.Widgets
import qs.utils
import qs.bar
import qs.components.bridges

Item {
    anchors.fill: parent
    anchors.leftMargin: 12
    Column {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 15
        anchors.topMargin: 27
        spacing: 17
        
        Row {
            anchors.left: parent.left
            spacing: 10
            ClippingRectangle {
                width: 40
                height: 40
                radius: width / 2

                Image {
                    fillMode: Image.PreserveAspectCrop
                    width: 40
                    height: 40
                    sourceSize.width: 80
                    sourceSize.height: 80
                    smooth: true
                    mipmap: true
                    source: DiscordBridge.call?.avatar
                }
            }
            Column {
                spacing: -3
                Text {
                    text: DiscordBridge.call?.name
                    width: 150
                    color: root.textColor
                    elide: Text.ElideRight
                    font { 
                        family: root.font
                        pixelSize: root.fontSize
                    }
                }
                Text {
                    text: "Discord"
                    width: 150
                    color: root.textColorSecondary
                    elide: Text.ElideRight
                    font { 
                        family: root.font
                        pixelSize: root.fontSize - 2
                    }
                }
            }
            Item {
                
                height: 40
                width: 1
                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 84
                    text: DiscordBridge.durationText
                    width: 150
                    color: "#3cce5f"
                    elide: Text.ElideRight
                    font { 
                        family: root.font
                        pixelSize: root.fontSize - 2
                    }
                }
            }
        }
        Row {
            spacing: 15
            Rectangle {
                width: 46
                height: 46
                radius: width / 2
                color: root.backgroundColor
                scale: muteHover.hovered ? 1.06 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: DiscordBridge.call?.muted ? Icons.micOff : Icons.mic
                    color: DiscordBridge.call?.muted ? Qt.lighter("#ff4e46", 1.06) : root.textColor
                    font {
                        family: root.iconFont
                        pixelSize: root.fontSize + 8
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        DiscordBridge.send("toggleMute") 
                    }
                }
                HoverHandler {
                    id: muteHover
                }
            }
            Rectangle {
                width: 46
                height: 46
                radius: width / 2
                color: root.backgroundColor
                scale: deafenHover.hovered ? 1.06 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: DiscordBridge.call?.deafened ? Icons.deafenOff : Icons.deafen
                    color: DiscordBridge.call?.deafened ? Qt.lighter("#ff4e46", 1.06) : root.textColor
                    font {
                        family: root.iconFont
                        pixelSize: root.fontSize + 8
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        DiscordBridge.send("toggleDeafen") 
                    }
                }
                HoverHandler {
                    id: deafenHover
                }
            }
            Rectangle {
                width: 46
                height: 46
                radius: width / 2
                color: root.backgroundColor
                scale: cameraHover.hovered ? 1.06 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: 1
                    text: Icons.camera
                    color: root.textColor
                    font {
                        family: root.iconFont
                        pixelSize: root.fontSize + 8
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {

                    }
                }
                HoverHandler {
                    id: cameraHover
                }
            }
            Rectangle {
                width: 46
                height: 46
                radius: width / 2
                color: root.backgroundColor
                scale: screenshareHover.hovered ? 1.06 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    text: DiscordBridge.screensharing ? Icons.screenshareOff : Icons.screenshare
                    color: root.textColor
                    font {
                        family: root.iconFont
                        pixelSize: root.fontSize + 8
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        DiscordBridge.screensharing ? DiscordBridge.send("stopStream") : DiscordBridge.send("startStream")
                    }
                }
                HoverHandler {
                    id: screenshareHover
                }
            }
            Rectangle {
                width: 46
                height: 46
                radius: width / 2
                color: "#ff4e46"
                scale: hangUpHover.hovered ? 1.06 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: 150
                    }
                }

                Text {
                    id: phoneIcon
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 2
                    text: Icons.phone
                    color: root.textColor
                    font { 
                        family: root.iconFont; 
                        pixelSize: root.fontSize + 8; 
                        bold: false
                    }
                    transform: Rotation {
                        origin.x: phoneIcon.width / 2
                        origin.y: phoneIcon.height / 2
                        angle: 135
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        DiscordBridge.send("hangup")
                        Island.expanded = false
                    }
                }
                HoverHandler {
                    id: hangUpHover
                }
            }
        }
    }
}