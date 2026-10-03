import Quickshell
import QtQuick
import QtQuick.Layouts
import "../../bar"

Item {
    anchors.fill: parent

    Column {
        width: parent.width - 32
        spacing: 15
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 15
        anchors.leftMargin: 15

        RowLayout {
            width: parent.width
            spacing: 15

            Image {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                fillMode: Image.PreserveAspectFit
                source: Island.notification ? Quickshell.iconPath(Island.notification.appName) : ""
                asynchronous: false
                cache: false
            }

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: Island.notification ? (Island.notification.summary) : ""
                color: "white"
                font.bold: true
                font.family: root.font
            }

        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            maximumLineCount: 3
            wrapMode: Text.Wrap
            text: Island.notification ? (Island.notification.body || "") : ""
            color: root.textColorSecondary
            font.family: root.font
        }

    }

}
