import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./procs"

RowLayout {
    spacing: 5
    
    Text {
        text: ""

        font.family: root.font 
        font.pixelSize: 15
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }
    Text {
        text: Memoryproc.mem

        font.family: root.font 
        font.pixelSize: root.fontSize
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }
}

