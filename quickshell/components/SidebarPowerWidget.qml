// SidebarPowerWidget.qml
// Expanding power section for the left rail
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: sidebarPower

    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accentStrong
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorRed: Theme.critical
    readonly property color colorOrange: Theme.secondaryStrong

    property bool expanded: mainHover.hovered || actionHover.hovered
    readonly property int buttonSize: 26
    readonly property int buttonGap: 4
    readonly property int collapsedHeight: 34
    readonly property int expandedHeight: collapsedHeight + (3 * buttonSize) + (3 * buttonGap)
    property int currentHeight: expanded ? expandedHeight : collapsedHeight

    implicitWidth: 36
    implicitHeight: currentHeight
    color: "transparent"

    Process {
        id: powerProcess
        command: ["true"]
    }

    function runAction(action) {
        if (action === "logout") powerProcess.command = ["niri", "msg", "action", "quit"]
        else if (action === "suspend") powerProcess.command = ["systemctl", "suspend"]
        else if (action === "reboot") powerProcess.command = ["systemctl", "reboot"]
        else if (action === "shutdown") powerProcess.command = ["systemctl", "poweroff"]
        powerProcess.running = true
    }

    Behavior on currentHeight {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    HoverHandler {
        id: mainHover
    }

    HoverHandler {
        id: actionHover
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: sidebarPower.buttonGap

        Repeater {
            model: [
                { icon: "\uf2f5", color: sidebarPower.colorAccent, action: "logout" },
                { icon: "\uf186", color: sidebarPower.colorMainLight, action: "suspend" },
                { icon: "\uf2f1", color: sidebarPower.colorOrange, action: "reboot" }
            ]

            Rectangle {
                id: actionButton
                required property var modelData
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: sidebarPower.buttonSize
                Layout.preferredHeight: sidebarPower.buttonSize
                radius: 8
                color: hover.containsMouse ? modelData.color : Theme.surface
                border.width: 1
                border.color: modelData.color
                visible: sidebarPower.expanded
                opacity: sidebarPower.expanded ? 1 : 0
                scale: sidebarPower.expanded ? 1 : 0.8

                Behavior on opacity {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
                Behavior on scale {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }

                Text {
                    anchors.centerIn: parent
                    text: actionButton.modelData.icon
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 10
                    color: hover.containsMouse ? "#000000" : actionButton.modelData.color
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: sidebarPower.runAction(actionButton.modelData.action)
                }
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: sidebarPower.buttonSize
            Layout.preferredHeight: sidebarPower.buttonSize
            radius: 9
            color: mainArea.containsMouse ? Theme.surface2 : Theme.surface
            border.width: 1
            border.color: sidebarPower.colorAccent

            Text {
                anchors.centerIn: parent
                text: "\uf011"
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 11
                color: sidebarPower.colorAccent
            }

            MouseArea {
                id: mainArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: sidebarPower.runAction("shutdown")
            }
        }
    }
}
