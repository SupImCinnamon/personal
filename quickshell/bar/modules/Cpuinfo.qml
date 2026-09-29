import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./procs"

RowLayout {
    property string fanrpm
    spacing: 7.5
    
    Text {
        text: Cpuinfoproc.fanrpm + " RPM"
        font.family: root.font
        font.pixelSize: root.fontSize
        color: root.textColor
        
    }

    Text {
        id: fanIcon
        text: "󰈐"
        font.family: root.font
        font.pixelSize: 18
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
        transform: Rotation {
            id: rotationTransform
            // Magic numbers :/
            origin.x: 9
            origin.y: 13.6
            angle: 0
        }
        
        PropertyAnimation {
            id: rotation
            target: rotationTransform
            property: "angle"
            from: 0
            to: 360
            duration: 1000
            loops: Animation.Infinite
        }
        
        Component.onCompleted: rotation.start()
    }
}

