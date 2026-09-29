pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string mem

    Process {
        id: memProc
        command: ["sh", "-c", "free -h | awk '{print $3}' | awk 'NR == 2' | awk -F 'i' '{print $1}'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: mem = this.text.trim()
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        onTriggered: memProc.running = true
    }
}