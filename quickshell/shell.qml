//@ pragma UseQApplication
// shell.qml
import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts

Scope {
    id: rootScope
    property bool hotCornerHovered: false
    property bool hoverGraceActive: false
    property int hoverGraceMs: 450
    property bool unifiedPanelHovered: false
    property bool unifiedPanelVisible: hotCornerHovered || unifiedPanelHovered || hoverGraceActive
    property bool debugOverlayEnabled: true
    property int debugOverlayMaxLines: 8

    ListModel {
        id: logModel
    }

    Timer {
        id: hoverGraceTimer
        interval: rootScope.hoverGraceMs
        repeat: false
        onTriggered: rootScope.hoverGraceActive = false
    }

    function messageTypeLabel(msgType) {
        if (msgType === QtDebugMsg) return "debug"
        if (msgType === QtInfoMsg) return "info"
        if (msgType === QtWarningMsg) return "warn"
        if (msgType === QtCriticalMsg) return "error"
        if (msgType === QtFatalMsg) return "fatal"
        return "log"
    }

    function trimMessage(message) {
        if (message === undefined || message === null) return ""
        var text = String(message)
        if (text.length > 240) {
            text = text.slice(0, 240) + "..."
        }
        return text
    }

    function appendLog(msgType, message) {
        logModel.append({
            type: messageTypeLabel(msgType),
            message: trimMessage(message)
        })
        if (logModel.count > debugOverlayMaxLines) {
            logModel.remove(0, logModel.count - debugOverlayMaxLines)
        }
    }

    Component.onCompleted: {
        console.log("[quickshell] unified widget shell loaded")
    }

    LeftBar {
        id: leftBar
        unifiedPanelVisible: rootScope.unifiedPanelVisible
    }
    
    UnifiedPanel {
        id: unifiedPanel
        panelVisible: rootScope.unifiedPanelVisible
        onPanelHoveredChanged: rootScope.unifiedPanelHovered = panelHovered
    }

    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: debugOverlay
            required property var modelData
            screen: modelData

            anchors {
                top: true
                right: true
            }

            implicitWidth: 440
            implicitHeight: 180
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            visible: rootScope.debugOverlayEnabled && logModel.count > 0

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: "#050505"
                opacity: 0.92
                border.width: 1
                border.color: Theme.accentStrong

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "Logs"
                            color: Theme.accentStrong
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Item {
                            Layout.preferredWidth: clearLogs.implicitWidth
                            Layout.preferredHeight: clearLogs.implicitHeight

                            Text {
                                id: clearLogs
                                anchors.centerIn: parent
                                text: "Clear"
                                color: Theme.accentStrong
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: logModel.clear()
                            }
                        }
                    }

                    ListView {
                        id: logList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        model: logModel
                        onCountChanged: positionViewAtEnd()

                        delegate: RowLayout {
                            width: logList.width
                            spacing: 8

                            Text {
                                text: model.type
                                font.pixelSize: 10
                                font.bold: true
                                color: model.type === "error" || model.type === "fatal"
                                    ? "#ff6b6b"
                                    : (model.type === "warn" ? Theme.secondaryStrong : Theme.accentStrong)
                            }

                            Text {
                                text: model.message
                                font.pixelSize: 10
                                color: "#ffffff"
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Top-Right Trigger Zone
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: rightTriggerZone
            required property var modelData
            screen: modelData
            
            anchors {
                top: true
                right: true
            }
            
            implicitWidth: 96
            implicitHeight: 36
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: {
                    rootScope.hotCornerHovered = true
                    rootScope.hoverGraceActive = true
                    hoverGraceTimer.stop()
                }
                onExited: {
                    rootScope.hotCornerHovered = false
                    rootScope.hoverGraceActive = true
                    hoverGraceTimer.restart()
                }
            }
        }
    }
}
