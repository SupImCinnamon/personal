import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import qs.bar

ShellRoot {
  id: root

  property string font: "JetbrainsMono Nerd Font"
  property string iconFont: "lucide"
  property int fontSize: 16
  property int fontSizeBig: 28

  property color textColor: "#ffffff"
  property color textColorSecondary: "#aaaaaa"
  property color pillColor: "#000000"

  DynamicIsland {}

      NotificationServer {
        imageSupported: true
        bodyImagesSupported: true
        onNotification: n => {
            n.tracked = true
            Island.showNotification(n)
        }
    }

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max)
  }
}