import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "./modules"
import "../widgets"
import "../components"

Scope {
  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData

      color: "transparent"

      anchors {
          top: true
          left: false
          right: false
      }


      implicitWidth: 1800
      implicitHeight: 28
      BackgroundEffect.blurRegion: Region { 
        item: content
        bottomLeftRadius: 12
        bottomRightRadius: 12
        topLeftRadius: 0
        topRightRadius: 0 
      }

      Rectangle {
        id: content
        anchors.fill: parent
        color: "#66000000"


        bottomLeftRadius: 12
        bottomRightRadius: 12
        topLeftRadius: 0
        topRightRadius: 0

        RowLayout {
          id: leftRow
          anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
          }
          
          spacing: 7.5
          Item { width: 2 }
          Cross {}
          ActiveWorkspace { screen: barWindow.screen }
          //Separator {}
          //ActiveWindow {}
        }

        RowLayout {
            id: centerRow
            anchors {
              horizontalCenter: parent.horizontalCenter
              verticalCenter: parent.verticalCenter
            }
            spacing: 7.5

            Date {}
            Separator {}
            Weather {}
        }

        RowLayout {
            id: rightRow
            anchors {
              right: parent.right
              verticalCenter: parent.verticalCenter
            }
            spacing: 7.5
      
            //Diskspace {}
            //Separator {}
            Memory {}
            Separator {}
            //Cpuinfo {}
            //Separator {}
            Volume {}
            Brightness {}
            Item { width: 2 }
        
        }
      }
    }
  }
}