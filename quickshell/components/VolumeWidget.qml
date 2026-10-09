// VolumeWidget.qml
// Compact volume widget for the vertical bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import ".."

Rectangle {
    id: volumeWidget
    
    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorSecondary: Theme.secondaryStrong
    readonly property color colorRed: Theme.critical
    
    property var sink: Pipewire.defaultAudioSink
    property bool hasSink: sink && sink.audio
    property int volumeLevel: hasSink ? Math.round(sink.audio.volume * 100) : 0
    property bool isMuted: hasSink ? sink.audio.muted : false
    property bool hovered: volumeHover.hovered
    property bool dragging: volumeDrag.pressed

    function clampPercent(value) {
        return Math.max(0, Math.min(100, Math.round(value)))
    }

    function setVolumePercent(value) {
        if (!hasSink) return
        sink.audio.volume = clampPercent(value) / 100
        if (sink.audio.muted && sink.audio.volume > 0) {
            sink.audio.muted = false
        }
    }

    function percentFromTrack(mouseY) {
        let ratio = 1 - (mouseY / volumeTrack.height)
        return clampPercent(ratio * 100)
    }
    
    implicitWidth: 36
    implicitHeight: 36
    color: "transparent"
    
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
    
    Rectangle {
        id: volumeFrame
        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        color: Theme.surface
        opacity: volumeWidget.hovered ? 1 : 0.92
        border.width: 1
        border.color: volumeWidget.isMuted ? Theme.critical : (volumeWidget.dragging ? Theme.secondaryStrong : Theme.border)
        scale: volumeWidget.dragging ? 0.98 : (volumeWidget.hovered ? 1.02 : 1.0)

        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on opacity { NumberAnimation { duration: 120 } }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 16
            radius: parent.radius
            color: Theme.bg
            opacity: Theme.mode === "light" ? 0.28 : 0.06
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 4
            text: {
                if (volumeWidget.isMuted) return "\uf6a9"
                if (volumeWidget.volumeLevel === 0) return "\uf026"
                if (volumeWidget.volumeLevel < 50) return "\uf027"
                return "\uf028"
            }
            font.family: "Font Awesome 6 Free Solid"
            font.weight: Font.Black
            font.pixelSize: 13
            color: volumeWidget.isMuted ? volumeWidget.colorRed : volumeWidget.colorSecondary

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (volumeWidget.hasSink) {
                        volumeWidget.sink.audio.muted = !volumeWidget.sink.audio.muted
                    }
                }
            }
        }

        Item {
            id: volumeTrack
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.bottom: volumeLabel.top
            anchors.bottomMargin: 5
            anchors.horizontalCenter: parent.horizontalCenter
            width: 18

            Rectangle {
                width: 4
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 999
                color: Theme.surface2
                border.width: 1
                border.color: volumeWidget.isMuted ? Theme.critical : Theme.border
            }

            Rectangle {
                width: 4
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.max(0, parent.height * (volumeWidget.volumeLevel / 100))
                radius: 999
                color: volumeWidget.isMuted ? volumeWidget.colorRed : volumeWidget.colorSecondary
                opacity: volumeWidget.isMuted ? 0.5 : 1
            }

            Rectangle {
                width: 14
                height: 14
                radius: 999
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(0, Math.min(parent.height - height, parent.height * (1 - (volumeWidget.volumeLevel / 100)) - (height / 2)))
                color: Theme.bg
                border.width: 1
                border.color: volumeWidget.isMuted ? volumeWidget.colorRed : volumeWidget.colorSecondary
            }

            MouseArea {
                id: volumeDrag
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => volumeWidget.setVolumePercent(volumeWidget.percentFromTrack(mouse.y))
                onPositionChanged: mouse => {
                    if (pressed) volumeWidget.setVolumePercent(volumeWidget.percentFromTrack(mouse.y))
                }
            }
        }

        Text {
            id: volumeLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: volumeWidget.volumeLevel + "%"
            font.pixelSize: 8
            font.family: "JetBrains Mono"
            font.bold: true
            color: volumeWidget.isMuted ? Theme.critical : Theme.text
        }
    }
    
    Process {
        id: pavuProcess
        command: ["pavucontrol"]
    }
    
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: pavuProcess.running = true
    }

    HoverHandler {
        id: volumeHover
    }

    WheelHandler {
        onWheel: wheel => {
            if (volumeWidget.hasSink) {
                let delta = wheel.angleDelta.y > 0 ? 5 : -5
                volumeWidget.setVolumePercent(volumeWidget.volumeLevel + delta)
            }
        }
    }
}
