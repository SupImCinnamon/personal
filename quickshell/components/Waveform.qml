import QtQuick

Row {
    id: wave
    property bool activeA: false   // even bars (caller)
    property bool activeB: false   // odd bars (you)
    property int bars: 10
    property color colorA: "#3cce5f"
    property color colorB: "#ff9f0a"
    spacing: 2

    Repeater {
        id: rep
        model: wave.bars

        Rectangle {
            property bool mine: index >= bars / 2
            property bool live: mine ? wave.activeB : wave.activeA
            property real level: 0

            width: 3
            radius: 1.5
            anchors.verticalCenter: parent.verticalCenter
            height: 3 + level * 24
            color: mine ? wave.colorB : wave.colorA

            Behavior on level { 
                NumberAnimation { 
                    duration: 250 
                } 
            }
            onLiveChanged: if (!live) level = 0
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: wave.activeA || wave.activeB
        onTriggered: {
            for (let i = 0; i < rep.count; i++) {
                const b = rep.itemAt(i)
                if (b && b.live) b.level = 0.1 + (Math.random() * 0.8)
            }
        }
    }
}