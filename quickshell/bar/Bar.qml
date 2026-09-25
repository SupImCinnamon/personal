import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "./modules"
import "../widgets"

Scope {
  id: root
  property string time 
  property string font: "SauceCodePro NF"
  property int fontSize: 15
  property color textColor: "#cbc9c5"

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: barWindow
      required property var modelData
      screen: modelData

      color: "#0c1114"

      anchors {
        top: true
        left: true
        right: true
      }

      implicitHeight: 25

      RowLayout {
        anchors.fill: parent

          // Left Modules
          RowLayout {
            id: leftRow
            anchors.left: Qt.AlignLeft
            spacing: 10 // Spacing between items
            ActiveWorkspace {
              screen: barWindow.screen
            }
            ActiveWindow {}
          }

          // Center Modules
          RowLayout {
              id: centerRow
              anchors.horizontalCenter: parent.horizontalCenter
              spacing: 10
              
          }

          // Right Modules
          RowLayout {
              id: rightRow
              anchors.right: parent.right
              spacing: 7.5
	      
              Separator {}
              Diskspace {}
              Separator {}
              Cpuinfo {}
              Separator {}
              Weather {}
              Separator {}
              Date {}
          }
      }
    }
  }
}