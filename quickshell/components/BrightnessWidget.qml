// BrightnessWidget.qml
// Compact brightness widget for the vertical bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: brightnessWidget
    
    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorYellow: Theme.accentStrong
    
    property int brightnessLevel: 100
    property bool hovered: brightnessHover.hovered
    property bool dragging: brightnessDrag.pressed

    function clampPercent(value) {
        return Math.max(1, Math.min(100, Math.round(value)))
    }

    function setBrightnessPercent(value) {
        let nextValue = clampPercent(value)
        brightnessSet.command = ["brightnessctl", "set", nextValue + "%"]
        brightnessSet.running = true
    }

    function percentFromTrack(mouseY) {
        let ratio = 1 - (mouseY / brightnessTrack.height)
        return clampPercent(ratio * 100)
    }
    
    implicitWidth: 36
    implicitHeight: 36
    color: "transparent"
    
    Process {
        id: brightnessProcess
        command: ["brightnessctl", "-m"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(",")
                if (parts.length >= 4) {
                    let percent = parts[3]
                    let val = parseInt(percent.replace("%", ""))
                    if (!isNaN(val)) brightnessWidget.brightnessLevel = val
                }
            }
        }
    }
    
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: brightnessProcess.running = true
    }
    
    Process {
        id: brightnessSet
        command: ["brightnessctl", "set", "100%"]
        onExited: brightnessProcess.running = true
    }

    Rectangle {
        id: brightnessFrame
        anchors.fill: parent
        anchors.margins: 5
        radius: 12
        color: Theme.surface
        opacity: brightnessWidget.hovered ? 1 : 0.92
        border.width: 1
        border.color: brightnessWidget.dragging ? Theme.accentStrong : Theme.border
        scale: brightnessWidget.dragging ? 0.98 : (brightnessWidget.hovered ? 1.02 : 1.0)

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
                if (brightnessWidget.brightnessLevel < 30) return "\uf186"
                if (brightnessWidget.brightnessLevel < 70) return "\uf042"
                return "\uf185"
            }
            font.family: "Font Awesome 6 Free Solid"
            font.weight: Font.Black
            font.pixelSize: 13
            color: brightnessWidget.colorYellow
        }

        Item {
            id: brightnessTrack
            anchors.top: parent.top
            anchors.topMargin: 16
            anchors.bottom: brightnessLabel.top
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
                border.color: Theme.border
            }

            Rectangle {
                width: 4
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                height: Math.max(0, parent.height * (brightnessWidget.brightnessLevel / 100))
                radius: 999
                color: brightnessWidget.colorYellow
            }

            Rectangle {
                width: 14
                height: 14
                radius: 999
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(0, Math.min(parent.height - height, parent.height * (1 - (brightnessWidget.brightnessLevel / 100)) - (height / 2)))
                color: Theme.bg
                border.width: 1
                border.color: brightnessWidget.colorYellow
            }

            MouseArea {
                id: brightnessDrag
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: mouse => brightnessWidget.setBrightnessPercent(brightnessWidget.percentFromTrack(mouse.y))
                onPositionChanged: mouse => {
                    if (pressed) brightnessWidget.setBrightnessPercent(brightnessWidget.percentFromTrack(mouse.y))
                }
            }
        }

        Text {
            id: brightnessLabel
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: brightnessWidget.brightnessLevel + "%"
            font.pixelSize: 8
            font.family: "JetBrains Mono"
            font.bold: true
            color: Theme.text
        }
    }

    HoverHandler {
        id: brightnessHover
    }

    WheelHandler {
        onWheel: event => {
            let delta = event.angleDelta.y > 0 ? 5 : -5
            brightnessWidget.setBrightnessPercent(brightnessWidget.brightnessLevel + delta)
        }
    }
}
