import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs.utils
import qs.bar
                    
Rectangle {
    id: controlCenterFrame
    anchors.fill: parent
    anchors.margins: 15
    radius: 16
    color: "transparent"
    Column {
        anchors.fill: parent
        spacing: 15
        Rectangle {
            width: parent.width
            height: 55
            radius: 16
            color: root.backgroundColor
            Item {
                anchors.fill: parent
                anchors.leftMargin: 3
                Row {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: 15
                    anchors.leftMargin: 3
                    anchors.topMargin: 4
                    ClippingRectangle {
                        width: 45
                        height: 45
                        radius: 25
                        Image {
                            fillMode: Image.PreserveAspectCrop
                            width: 45
                            height: 45
                            sourceSize.width: 90
                            sourceSize.height: 90
                            smooth: true
                            mipmap: false
                            source: "file:///home/cinnamon/Desktop/face.png"
                        }
                    }
                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 4
                        Text {
                            text: "Cinnamon"
                            color: root.textColor
                            font {
                                family: root.font
                                pixelSize: root.fontSize - 2
                            }
                        }
                        Text {
                            text: "EndeavourOS"
                            color: root.textColorSecondary
                            font {
                                family: root.font
                                pixelSize: root.fontSize - 2
                            }
                        }
                    }
                }
                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 0
                    spacing: -3
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(clock.date, "hh:mm")
                        color: root.textColor
                        font {
                            family: root.font
                            pixelSize: root.fontSizeBig 
                            bold: true
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(clock.date, "ddd, d MMM")
                        color: root.textColorSecondary
                        font {
                            family: root.font
                            pixelSize: root.fontSize - 4
                        }
                    }
                }
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.rightMargin: 7
                    anchors.topMargin: 5
                    width: 120
                    height: 45
                    radius: 16
                    color: Qt.lighter(root.backgroundColor, 1.6)
                    Item {
                        anchors.fill: parent
                        anchors.topMargin: -1
                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            width: 36
                            height: 36
                            radius: 18
                            color: Qt.lighter(root.backgroundColor, 2.2)
                            Text {
                                anchors.centerIn: parent
                                text: Icons.cog
                                color: root.textColor
                                font {
                                    family: root.iconFont
                                    pixelSize: root.fontSize + 6
                                }
                            }
                        }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.verticalCenter: parent.verticalCenter
                            width: 1
                            height: 28
                            radius: 2
                            color: Qt.lighter(root.backgroundColor, 3)
                        }
                        Rectangle {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 12
                            width: 36
                            height: 36
                            radius: 18
                            color: Qt.lighter(root.backgroundColor, 2.2)
                            Text {
                                anchors.centerIn: parent
                                text: Icons.more
                                color: root.textColor
                                font {
                                    family: root.iconFont
                                    pixelSize: root.fontSize + 6
                                }
                            }
                        }
                    }
                }
            }
        }
        Row {
            spacing: 15
            Column {
                spacing: 15
                Rectangle {
                    width: 350
                    height: 250
                    radius: 16
                    color: root.backgroundColor
                }
                Row {
                    spacing: 17
                    Rectangle {
                        width: 75
                        height: 75
                        radius: 16
                        color: root.notifMuted ? root.textColorSecondary : root.backgroundColor
                        Text {
                            anchors.centerIn: parent
                            text: Icons.bellOff
                            color: root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 12
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Island.controlCenter && Island.expanded
                            onClicked: {
                                root.notifMuted = !root.notifMuted
                            }
                        }
                    }
                    Rectangle {
                        width: 75
                        height: 75
                        radius: 16
                        color: root.backgroundColor
                        Text {
                            anchors.centerIn: parent
                            text: Icons.recording
                            color: root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 16
                            }
                        }
                    }
                    Rectangle {
                        width: 75
                        height: 75
                        radius: 16
                        color: root.nightLight ? root.textColorSecondary : root.backgroundColor

                        Text {
                            anchors.centerIn: parent
                            text: Icons.nightLight
                            color: root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 16
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Island.controlCenter && Island.expanded
                            onClicked: {
                                if(root.nightLight) {
                                    nightLightProc.running = false;
                                    root.nightLight = false;
                                } else {
                                    if(!nightLightProc.running) {
                                        nightLightProc.running = true;
                                        root.nightLight = true;
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: 75
                        height: 75
                        radius: 16
                        color: root.backgroundColor
                        Text {
                            anchors.centerIn: parent
                            text: Icons.bellOff
                            color: root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 12
                            }
                        }
                    }
                }
            }
            Rectangle {
                width: 100
                height: 340
                radius: 16
                color: root.backgroundColor
                Column {
                    spacing: 15
                    anchors.centerIn: parent
                    anchors.top: parent.top
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Icons.brightnessFull
                        color: root.textColor
                        font {
                            family: root.iconFont
                            pixelSize: root.fontSize + 12
                        }
                    }
                    Item {
                        width: 64
                        height: 210
                        anchors.horizontalCenter: parent.horizontalCenter
                        ClippingRectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 60
                            height: 210
                            radius: 24
                            color: Qt.darker(root.backgroundColor, 1.3)
                            Rectangle {
                                width: parent.width
                                height: parent.height * root.brightness
                                anchors.bottom: parent.bottom
                                bottomLeftRadius: 16
                                bottomRightRadius: 16   
                                color: root.textColor
                            }
                            MouseArea {
                                id: brightnessSliderArea
                                anchors.fill: parent
                                enabled: Island.controlCenter && Island.expanded

                                function seek(mouseY) {
                                    const ratio = Math.max(0, Math.min(1, 1 - (mouseY / height)));
                                    root.brightness = ratio;
                                }
                                onPressed: mouse => seek(mouse.y)
                                onPositionChanged: mouse => { if (pressed) seek(mouse.y) }
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(root.brightness * 100) + "%"
                        color: root.textColor
                        font {
                            family: root.font
                            pixelSize: root.fontSize
                        }
                    }
                }
            }
            Rectangle {
                width: 100
                height: 340
                radius: 16
                color: root.backgroundColor
                Column {
                    spacing: 15
                    anchors.centerIn: parent
                    anchors.top: parent.top
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Icons.volumeFull
                        color: root.textColor
                        font {
                            family: root.iconFont
                            pixelSize: root.fontSize + 12
                        }
                    }
                    Item {
                        width: 64
                        height: 210
                        anchors.horizontalCenter: parent.horizontalCenter
                        ClippingRectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 60
                            height: 210
                            radius: 24
                            color: Qt.darker(root.backgroundColor, 1.3)
                            
                            Rectangle {
                                width: parent.width
                                height: parent.height * Pipewire.defaultAudioSink?.audio.volume
                                anchors.bottom: parent.bottom
                                bottomLeftRadius: 16
                                bottomRightRadius: 16
                                color: root.textColor
                            }

                            MouseArea {
                                id: volumeSliderArea
                                anchors.fill: parent
                                enabled: Island.controlCenter && Island.expanded

                                function seekVolume(mouseY) {
                                    const ratio = Math.max(0, Math.min(1, 1 - (mouseY / height)));
                                    Pipewire.defaultAudioSink.audio.volume = clamp(ratio, 0, 1);
                                }
                                onPressed: mouse => seekVolume(mouse.y)
                                onPositionChanged: mouse => { if (pressed) seekVolume(mouse.y) }
                            }
                        }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(Pipewire.defaultAudioSink?.audio.volume * 100) + "%"
                        color: root.textColor
                        font {
                            family: root.font
                            pixelSize: root.fontSize
                        }
                    }
                }
            }
            Rectangle {
                width: 340
                height: 660
                radius: 16
                color: root.backgroundColor
                Item {
                    anchors.fill: parent
                    anchors.margins: 15
                    Text {
                        text: "Notifications"
                        color: root.textColor
                        font {
                            family: root.font
                            pixelSize: root.fontSize
                        }
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: -7
                        width: 36
                        height: 36
                        radius: 18
                        color: root.notifMuted ? Qt.lighter(root.backgroundColor, 1.6) : Qt.lighter(root.backgroundColor, 1.6)
                        Text {
                            anchors.centerIn: parent
                            text: Icons.bellOff
                            color: root.notifMuted ? "#FACC15" : root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 2
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: Island.controlCenter && Island.expanded
                            onClicked: {
                                root.notifMuted = !root.notifMuted
                            }
                        }
                    }
                    
                    ListView {
                        anchors.fill: parent
                        anchors.topMargin: 50
                        anchors.bottomMargin: 60
                        model: notifHistory
                        spacing: 15
                        clip: true 

                        delegate: Rectangle {
                            width: ListView.view.width 
                            height: contentLayout.height + 24 
                            color: Qt.lighter(root.backgroundColor, 1.6)
                            radius: 16

                            Row {
                                id: contentLayout
                                width: parent.width - 24 
                                anchors.centerIn: parent
                                spacing: 12

                                Image {
                                    id: notifIcon
                                    width: 40
                                    height: 40
                                    anchors.verticalCenter: parent.verticalCenter
                                    fillMode: Image.PreserveAspectFit
                                    source: Quickshell.iconPath(appName)
                                    asynchronous: false
                                    cache: false
                                }

                                Column {
                                    width: parent.width - notifIcon.width - parent.spacing
                                    spacing: 4

                                    Column {
                                        width: parent.width
                                        spacing: 0
                                        
                                        Text { 
                                            width: parent.width
                                            text: capitalizeFirstLetter(appName)
                                            color: root.textColor
                                            font.family: root.font
                                            font.pixelSize: root.fontSize - 2
                                            wrapMode: Text.WordWrap
                                        }
                                        Text { 
                                            width: parent.width
                                            text: summary
                                            color: root.textColor
                                            font.family: root.font
                                            font.pixelSize: root.fontSize - 2
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                    
                                    Text { 
                                        width: parent.width
                                        text: body
                                        color: root.textColor
                                        font.family: root.font
                                        font.pixelSize: root.fontSize - 4
                                        wrapMode: Text.WordWrap 
                                    }
                                }
                            }
                            
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    try {
                                        notif.dismiss()
                                    } catch (err) {

                                    }
                                    notifHistory.remove(index)
                                }
                            }
                        }
                    }
                    
                    Column {
                        spacing: 15
                        anchors.centerIn: parent
                        visible: notifHistory.count == 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Icons.bellCheck
                            color: root.textColor
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize + 32
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "All quiet for now."
                            color: root.textColor
                            font {
                                family: root.font
                                pixelSize: root.fontSize
                            }
                        }
                    }
                    
                    Rectangle {
                        height: 45
                        radius: 16
                        color: Qt.lighter(root.backgroundColor, 1.6)
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        visible: notifHistory.count != 0
                        Text {
                            anchors.centerIn: parent
                            text: "Clear all"
                            color: root.textColor
                            font {
                                family: root.font
                                pixelSize: root.fontSize - 2
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: notifHistory.count != 0
                            onClicked: {
                                for (let i = 0; i <= notifHistory.count; i++) {
                                    try {
                                        notifHistory.get(i).notif.dismiss()
                                    } catch (err) {

                                    }
                                }
                                notifHistory.clear()
                            }
                        }
                    }
                }
            }
        }
    }
    Column {
        anchors.top: parent.top
        anchors.topMargin: 425
        spacing: 15
        Rectangle {
            radius: 16
            width: 581
            height: 210
            color: root.backgroundColor
        }
        Rectangle {
            radius: 16
            width: 581
            height: 78
            color: root.backgroundColor
        }
    }
}