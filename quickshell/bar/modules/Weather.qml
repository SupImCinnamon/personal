import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./procs"

RowLayout {
    spacing: 7.5
    
    Text {
        text: {
            if(Weatherproc.weather[1] == "Overcast") {
                "󰖐"
            } else {
                "󰖗"
            }
        }
        font.family: root.font
        font.pixelSize: root.iconSize
        color: "#FFFFFF"
    }
    Text {
        text: Weatherproc.weather[0]
        font.family: root.font
        font.pixelSize: root.fontSize
        color: "#FFFFFF"
    }
}

