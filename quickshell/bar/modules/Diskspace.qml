import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./procs"

RowLayout {
    spacing: 5
    
    Text {
        text: "󰋊 " + Diskspaceproc.space

        font.family: root.font 
        font.pixelSize: root.fontSize
        color: "#cbc9c5"
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }
}

