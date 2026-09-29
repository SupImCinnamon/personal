import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import "./modules"
import "../widgets"

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

      width: 1800
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
          anchors.fill: parent
          anchors.rightMargin: 10
          anchors.leftMargin: 10

          RowLayout {
            id: leftRow
            anchors.left: parent.left
            spacing: 7.5

            ActiveWorkspace { screen: barWindow.screen }
            Separator {}
            ActiveWindow {}
          }

          RowLayout {
              id: centerRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 7.5

              Date {}
              Separator {}
              Weather {}
          }

          RowLayout {
              id: rightRow
              anchors.right: parent.right
              spacing: 6
	      
              Diskspace {}
              Separator {}
              Memory {}
              Separator {}
              Cpuinfo {}
              Separator {}
              Volume {}
              Brightness {}
          }
        }
      }
    }
  }
}