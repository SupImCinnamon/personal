import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.utils
import qs.components.bridges
import qs.components

Item {
    anchors.fill: parent
    anchors.leftMargin: 10
    
    Text {
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        text: Icons.phone
        color: "#3cce5f"
        font.family: root.iconFont
        font.pixelSize: root.fontSize
        font.bold: true
    }

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        anchors.leftMargin: 25
        text: DiscordBridge.durationText
        color: "#3cce5f"
        font.family: root.font
        font.pixelSize: root.fontSize - 2
        font.bold: true
    }
    Row {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        anchors.rightMargin: 12
        spacing: 6
    Waveform {
        activeA: DiscordBridge.call?.speakingThem ?? false
        activeB: DiscordBridge.call?.speakingMe ?? false
    }
    }
}