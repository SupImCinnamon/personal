import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "./bar"
import "./components"

ShellRoot {
  id: root
  property string font: "JetbrainsMono Nerd Font"
  property int fontSize: 14
  property int iconSize: 16
  property color textColor: "#ffffff"
  property color textColorSecondary: "#cbc9c5"
  property color windowColor: "#66000000"
  property color windowColorSecondary: "#66000000"
  property color mainColor: "#66000000"
  
  NotifElement {
    id: notifElement
  }

  YtdlPopup {
    id: ytdlPopup
  }

  IpcHandler {
    target: "ytdl"
    function open(): void {
      ytdlPopup.open()
    }
    function close(): void {
      ytdlPopup.close()
    }
  }

  NotificationServer {
    id: notifServer
    Component.onCompleted: {
      notifServer.notification.connect((notif) => {
        console.log(notif.summary);
        notifElement.displayNotification(notif.appName, notif.summary, notif.body);
      })
    }
  }
  Bar {}

  function clamp(value, min, max) {
    return Math.min(Math.max(value, min), max)
  }
}