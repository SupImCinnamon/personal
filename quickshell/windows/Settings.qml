import Quickshell

FloatingWindow {
  // The mask region is set to `rect`, meaning only `rect` is clickable.
  // All other clicks pass through the window to ones behind it.
  mask: Region { item: rect }

  Rectangle {
    id: rect

    anchors.centerIn: parent
    width: 100
    height: 100
  }
}