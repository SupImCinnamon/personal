import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  property int maxLength: 40
  
  property string windowTitle: emptyText
    
  Text {
    text: windowTitle.length > maxLength ? windowTitle.substring(0, maxLength).trim() + "..." : windowTitle
    leftPadding: 2
    font.family: root.font
    font.pixelSize: root.fontSize
    color: root.textColor
    verticalAlignment: Text.AlignVCenter
    Layout.fillHeight: true
  }
  
  // Get initial window title
  Process {
    id: initialProc
    command: ["sh", "-c", "niri msg -j focused-window | jq -r '.title // \"Desktop\"'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var title = this.text.trim()
        windowTitle = title || emptyText
      }
    }
  }
  
  // Listen to real-time events
  Process {
    id: eventStream
    command: ["sh", "-c", "niri msg -j event-stream | jq --unbuffered -r 'select(.WindowFocusChanged) | .WindowFocusChanged.id' | while read -r id; do if [ \"$id\" = \"null\" ]; then echo \"Desktop\"; else niri msg windows | awk -v id=\"$id\" '$0 ~ \"Window ID \" id \":\" {found=1} found && /Title:/ {match($0, /\\\"([^\\\"]+)\\\"/, m); print m[1]; exit}'; fi; done"]
    running: true
    
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        if (data && data.length > 0) {
          windowTitle = data.trim() || emptyText
        }
      }
    }
  }
}