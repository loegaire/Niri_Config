// WorkspacesWidget.qml
// Displays Niri workspaces
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: workspacesWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.bg
    readonly property color colorMainLight: Theme.accentStrong
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.border
    
    property int activeWorkspaceId: 1
    property bool compact: false

    // Niri workspace tracking
    property var niriWorkspaces: []
    property bool usingNiri: true
    
    property var displayedWorkspaces: [1]
    
    implicitWidth: workspaceColumn.implicitWidth + 2
    implicitHeight: workspaceColumn.implicitHeight + 2
    color: "transparent"

    Component.onCompleted: displayedWorkspaces = visibleWorkspaceIds()
    onActiveWorkspaceIdChanged: displayedWorkspaces = visibleWorkspaceIds()

    function workspaceHasWindows(id: int): bool {
        if (usingNiri) {
            for (let i = 0; i < niriWorkspaces.length; i++) {
                if (niriWorkspaces[i].idx === id) {
                    return niriWorkspaces[i].active_window_id !== null
                }
            }
            return false
        }

        return false
    }

    function visibleWorkspaceIds() {
        let ids = []
        if (usingNiri) {
            for (let i = 0; i < niriWorkspaces.length; i++) {
                let id = niriWorkspaces[i].idx
                if (ids.indexOf(id) === -1) ids.push(id)
            }
        } else if (activeWorkspaceId > 0) {
            ids.push(activeWorkspaceId)
        }
        if (ids.length === 0) ids.push(1)
        ids.sort((a, b) => a - b)
        return ids
    }

    function updateFromNiri(list) {
        niriWorkspaces = list
        let focused = null
        for (let i = 0; i < list.length; i++) {
            if (list[i].is_focused) {
                focused = list[i]
            }
        }
        displayedWorkspaces = visibleWorkspaceIds()
        if (focused) {
            activeWorkspaceId = focused.idx
        }
    }

    Process {
        id: niriProcess
        command: ["niri", "msg", "-j", "workspaces"]
        running: true

        property string buffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                niriProcess.buffer += data
            }
        }

        onExited: {
            let text = niriProcess.buffer.trim()
            niriProcess.buffer = ""
            if (!text) {
                niriWorkspaces = []
                displayedWorkspaces = visibleWorkspaceIds()
                return
            }
            try {
                let list = JSON.parse(text)
                if (Array.isArray(list)) {
                    updateFromNiri(list)
                }
            } catch (e) {
                console.warn("WorkspacesWidget: failed to parse niri workspaces")
                niriWorkspaces = []
                displayedWorkspaces = visibleWorkspaceIds()
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: {
            if (!niriProcess.running) {
                niriProcess.running = true
            }
        }
    }
    
    ColumnLayout {
        id: workspaceColumn
        anchors.centerIn: parent
        width: parent.width
        spacing: 3
        
        Repeater {
            model: workspacesWidget.compact ? [workspacesWidget.activeWorkspaceId] : workspacesWidget.displayedWorkspaces
            
            Rectangle {
                id: wsRect
                required property int modelData
                
                property bool isActive: modelData === workspacesWidget.activeWorkspaceId
                property bool hasWindows: workspacesWidget.workspaceHasWindows(modelData)
                
                Layout.alignment: Qt.AlignHCenter
                width: workspaceColumn.width
                height: workspacesWidget.compact ? 18 : 22
                radius: 7
                color: isActive ? workspacesWidget.colorSecondary : (hasWindows ? Theme.surface2 : Theme.surface)
                border.width: 1
                border.color: wsHover.containsMouse ? workspacesWidget.colorAccent : (isActive ? workspacesWidget.colorAccentDim : workspacesWidget.colorSecondary2)
                scale: wsHover.containsMouse ? 1.03 : 1.0

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 3
                    height: parent.height - 6
                    radius: 2
                    color: workspacesWidget.colorAccent
                    visible: wsRect.isActive
                }

                Text {
                    anchors.centerIn: parent
                    text: String(wsRect.modelData)
                    font.pixelSize: 9
                    font.family: "JetBrains Mono"
                    font.bold: wsRect.isActive
                    color: wsRect.isActive ? "#000000" : (wsRect.hasWindows ? Theme.accentStrong : Theme.muted)
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 4
                    height: 4
                    radius: 2
                    color: wsRect.isActive ? workspacesWidget.colorMain : workspacesWidget.colorAccent
                    visible: wsRect.hasWindows
                }
                
                MouseArea {
                    id: wsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (workspacesWidget.usingNiri) {
                            niriFocusProcess.command = ["niri", "msg", "action", "focus-workspace", String(wsRect.modelData)]
                            niriFocusProcess.running = true
                        }
                    }
                }
            }
        }
    }

    Process {
        id: niriFocusProcess
        command: ["true"]
    }
}
