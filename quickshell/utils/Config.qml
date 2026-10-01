pragma Singleton
import Quickshell
import qs.bar

Singleton {
    property int widthNormal: 100
    property int widthHovered: 110
    property int widthExpanded: 420
    property int heightNormal: 30
    property int heightHovered: 32
    property int heightExpanded: 120

    property int topMargin: 5
    property bool shouldReserveSpace: true
    property int reservedSpace: 26

    property int hoverGrowW: 10
    property int hoverGrowH: 2

        // Extra room so the spring overshoot isn't clipped by the window edge
    property int overshoot: 40

    property int maxWidth: overshoot
        + Math.max(...Object.values(Island.layouts).map(l => l.expanded.width))
    property int maxHeight: overshoot
        + Math.max(...Object.values(Island.layouts).map(l => l.expanded.height))
}