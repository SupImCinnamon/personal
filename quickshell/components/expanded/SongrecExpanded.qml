import QtQuick
import Quickshell.Widgets
import qs.bar
import qs.components.bridges
import qs.components.expanded.subcomponents

Item {
    anchors.fill: parent

    // ---- listening: mirrors the compact view ----
    Row {
        anchors.centerIn: parent
        spacing: 12
        visible: SongrecBridge.state === "listening"

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: SongrecBridge.phrase
            color: "white"
            font.family: root.font
            font.pixelSize: root.fontSize + 2
            font.bold: true
        }
    }

    // ---- nothing found ----
    Column {
        anchors.centerIn: parent
        spacing: 4
        visible: SongrecBridge.state === "none"

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "No song found"
            color: "white"
            font.family: root.font
            font.pixelSize: root.fontSize + 2
            font.bold: true
        }
    }

    // ---- found ----
    Item {
        anchors.fill: parent
        visible: SongrecBridge.state === "found"

        ClippingRectangle {
            id: art
            width: 64; height: 64
            radius: 8
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            color: "#252526"

            Image {
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                source: SongrecBridge.result?.art ?? ""
                asynchronous: true
                sourceSize.width: 256
                sourceSize.height: 256
                smooth: true
            }
        }

        Column {
            anchors.left: art.right
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                elide: Text.ElideRight
                text: SongrecBridge.result?.title ?? ""
                color: "white"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                font.bold: true
            }
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: SongrecBridge.result?.artist ?? ""
                color: root.textColorSecondary
                font.family: root.font
            }
        }
    }
}