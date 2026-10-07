import QtQuick
import qs.bar
import qs.components.expanded.subcomponents

Item {
    readonly property bool isCast: Island.portal?.type === "screencast"
    readonly property real extraHeight: isCast ? 0 : 300
    readonly property real extraWidth: isCast ? 0 : 300

    FileChooser {
        anchors.fill: parent
        anchors.margins: 14
        visible: !parent.isCast
        enabled: !parent.isCast
        req: Island.portal ?? ({})
        onAccepted: uris => Island.portalAccept(uris)
        onCancelled: Island.portalCancel()
    }

    Loader {
        anchors.fill: parent
        anchors.margins: 14
        active: parent.isCast
        sourceComponent: ScreencastChooser {
            req: Island.portal
            onAccepted: uris => Island.portalAccept(uris)
            onCancelled: Island.portalCancel()
        }
    }
}