pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property string date

  Process {
    id: dateProc
    command: ["date", "+%A, %d %B %H:%M"]
    running: true

    stdout: StdioCollector {
      onStreamFinished: root.date = this.text
    }
  }

  Timer {
    interval: 1000
    running: true
    repeat: true
    onTriggered: dateProc.running = true
  }
}