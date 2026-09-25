pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
  id: root
  property string fanrpm

    Process {
        id: cpuinfoproc
        command: ["sh", "-c", "echo \"$(cat <(grep 'cpu ' /proc/stat) <(sleep 0.2 && grep 'cpu ' /proc/stat) | awk -v RS=\"\" '{printf \"%.0f\", ($13-$2+$15-$4)*100/($13-$2+$15-$4+$16-$5)}')%   $(sensors | awk '/RPM/ {print $2}' FS='[[:space:]]+' | awk 'NR==2')\""]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.fanrpm = this.text.trim()
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: cpuinfoproc.running = true
    }
}