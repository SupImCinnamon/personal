import QtQuick

Item {
    anchors.fill: parent
    Column {
        anchors.centerIn: parent
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm:ss")
            color: root.textColor
            font { family: root.font; pixelSize: root.fontSizeBig; bold: true }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
            color: root.textColorSecondary
            font { family: root.font; pixelSize: root.fontSize - 2 }
        }
    }
}