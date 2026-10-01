import Quickshell
import QtQuick
import "./bar"

ShellRoot {
  id: root

  property string font: "JetbrainsMono Nerd Font"
  property int fontSize: 14
  property int fontSizeBig: 28

  property color textColor: "#ffffff"
  property color textColorSecondary: "#aaaaaa"
  property color pillColor: "#000000"

  DynamicIsland {}

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max)
  }
}