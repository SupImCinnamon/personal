import QtQuick
import Quickshell.Widgets
import qs.utils
import qs.bar
import qs.components.bridges

Item {
    anchors.fill: parent
    anchors.leftMargin: 12
    ClippingRectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 45
        height: 45
        radius: 25

        Image {
            fillMode: Image.PreserveAspectCrop
            width: 45
            height: 45
            sourceSize.width: 90
            sourceSize.height: 90
            smooth: true
            mipmap: true
            source: Island.incomingCall.avatar
        }
    }
    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 55

        Text {
            text: "Discord"
            color: root.textColorSecondary
            font { 
                family: root.font
                pixelSize: root.fontSize - 4
            }
        }
        Text {
            text: Island.incomingCall.name
            width: 150
            color: root.textColor
            elide: Text.ElideRight
            font { 
                family: root.font; 
                pixelSize: root.fontSize; 
                bold: true 
            }
        }
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 12
        spacing: 12
        Rectangle {
            width: 40
            height: 40
            radius: width / 2
            color: "#ff4e46"
            scale: declineHovered.hovered ? 1.06 : 1

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
                    pixelSize: root.fontSize + 4; 
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
                    DiscordBridge.send("decline")
                }
            }
            HoverHandler {
                id: declineHovered
            }
        }
        Rectangle {
            width: 40
            height: 40
            radius: width / 2
            color: "#3cce5f"
            scale: acceptHovered.hovered ? 1.06 : 1

            Behavior on scale {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 1
                text: Icons.phone
                color: root.textColor
                font { 
                    family: root.iconFont; 
                    pixelSize: root.fontSize + 4; 
                    bold: false
                }
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    DiscordBridge.send("accept")
                }
            }
            HoverHandler {
                id: acceptHovered
            }
        }
    }
}