import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

Text {
  text: "|"
  verticalAlignment: Text.AlignVCenter
  Layout.fillHeight: true
  opacity: 0.75
  font.family: root.font 
  font.pixelSize: root.fontSize
  color: root.textColorSecondary
}