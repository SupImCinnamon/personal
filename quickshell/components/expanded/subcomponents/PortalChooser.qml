import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

// A minimal file browser living inside the Island.
// `req` is the request object from the sidecar (see island_portal.py).
FocusScope {
    id: root
    required property var req
    signal accepted(var uris)
    signal cancelled()

    readonly property bool isSave: req.type === "save"
    readonly property bool dirMode: req.directory === true
    property var picked: []          // selected file:// URI strings
    property int filterIndex: 0
    property bool askOverwrite: false

    // Portal filters: [[label, [[0, glob], [1, mime]]], ...]
    // This sketch only honours globs; MIME entries fall back to "*".
    function globsFor(i) {
        const f = req.filters || []
        if (f.length === 0 || i >= f.length) return ["*"]
        const g = f[i][1].filter(p => p[0] === 0).map(p => p[1])
        return g.length ? g : ["*"]
    }

    function confirm() {
        if (isSave) {
            const name = nameField.text.trim()
            if (!name) return
            const uri = dir.folder.toString() + "/" + encodeURIComponent(name)
            if (dir.indexOf(uri) >= 0 && !askOverwrite) { askOverwrite = true; return }
            accepted([uri])
        } else if (dirMode) {
            accepted(picked.length ? picked : [dir.folder.toString()])
        } else if (picked.length) {
            accepted(picked)
        }
    }

    Keys.onReturnPressed: confirm()
    Keys.onEscapePressed: cancelled()
    Component.onCompleted: forceActiveFocus()

    FolderListModel {
        id: dir
        folder: req.current_folder ? "file://" + req.current_folder
                                   : "file://" + Quickshell.env("HOME")
        showDirs: true
        showFiles: !root.dirMode
        showDirsFirst: true
        showDotAndDotDot: false
        nameFilters: root.isSave ? ["*"] : root.globsFor(root.filterIndex)
        Component.onCompleted: console.log("[chooser] start folder:", folder,
                                   "HOME:", Quickshell.env("HOME"),
                                   "current_folder:", root.req.current_folder)
    }

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: "transparent"

        // Dropping a file from any app satisfies the dialog.
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            enabled: !root.isSave && !root.dirMode
            onDropped: drop => {
                if (drop.hasUrls)
                    root.accepted(drop.urls.map(u => u.toString()))
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 8

            Label {
                text: req.title + (req.app_id ? "  ·  " + req.app_id : "")
                color: "white"; font.bold: true
                Layout.fillWidth: true; elide: Text.ElideRight
            }

            RowLayout {
                Layout.fillWidth: true
                Button { text: "↑"; onClicked: dir.folder = dir.parentFolder }
                Label {
                    text: dir.folder.toString().replace("file://", "")
                    color: "#aaa"; elide: Text.ElideLeft; Layout.fillWidth: true
                }
                ComboBox {
                    visible: !root.isSave && (req.filters || []).length > 1
                    model: (req.filters || []).map(f => f[0])
                    onActivated: i => root.filterIndex = i
                }
            }

            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true
                model: dir
                delegate: ItemDelegate {
                    id: del
                    required property string fileName
                    required property bool fileIsDir
                    required property url fileUrl
                    width: ListView.view.width
                    text: (fileIsDir ? "▸ " : "   ") + fileName
                    highlighted: root.picked.includes(fileUrl.toString())

                    contentItem: Text {
                        text: del.text
                        color: "white"
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: del.highlighted ? "#33ffffff" : (del.hovered ? "#14ffffff" : "transparent")
                    }

                    onClicked: {
                        if (fileIsDir) { dir.folder = fileUrl; return }
                        if (root.isSave) { nameField.text = fileName; return }
                        const u = fileUrl.toString()
                        if (req.multiple) {
                            root.picked = root.picked.includes(u)
                                ? root.picked.filter(x => x !== u)
                                : root.picked.concat([u])
                        } else {
                            root.accepted([u])   // single-select: click = done
                        }
                    }
                }
            }

            TextField {
                id: nameField
                visible: root.isSave
                Layout.fillWidth: true
                text: req.current_name || ""
                placeholderText: "File name"
                onTextChanged: root.askOverwrite = false
                onAccepted: root.confirm()
            }

            Label {
                visible: root.askOverwrite
                text: "File exists. Press Enter again to overwrite."
                color: "#ffb4ab"
            }

            Label {
                visible: req.multiple && root.picked.length > 0
                text: root.picked.length + " selected · Enter to confirm"
                color: "#aaa"
            }
        }
    }
}