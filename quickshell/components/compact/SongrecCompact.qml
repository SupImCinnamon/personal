import QtQuick
import qs.utils
import qs.bar
import qs.components.bridges
import qs.components.expanded.subcomponents

Item {
    anchors.fill: parent
    anchors.leftMargin: 10
    anchors.rightMargin: 10
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Icons.music
        color: root.textColor
        font.bold: true
        font.family: root.iconFont
        font.pixelSize: root.fontSize + 6
    }
    Text {
        anchors.centerIn: parent
        elide: Text.ElideRight
        color: root.textColor
        font.bold: true
        font.family: root.font
        text: SongrecBridge.state === "found" ? SongrecBridge.result.title
            : SongrecBridge.state === "none"  ? "No song found"
            : SongrecBridge.phrase
    }
    Rectangle {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 15
        color: root.backgroundColor
    }
}