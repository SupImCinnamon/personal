import QtQuick
import qs.bar

Text {
    anchors.centerIn: parent
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: Island.portal?.type == "screencast" ? "Choose screen" : "Choose file"
    color: root.textColor
    font { 
        family: root.font
        pixelSize: root.fontSize
        bold: true 
    }
}