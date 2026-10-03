import QtQuick

Text {
    anchors.centerIn: parent
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    text: Qt.formatTime(clock.date, "hh:mm")
    color: root.textColor
    font { family: root.font; pixelSize: root.fontSize; bold: true }
}