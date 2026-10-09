// ToggleGridWidget.qml
// Compact Swiss-style toggle cards with real commands where supported.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: toggleGridWidget

    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorOrange: Theme.secondary2
    readonly property color colorRed: Theme.critical

    property var toggleStates: [false, false, true, false, false, false]

    function setToggleState(index, enabled) {
        let next = toggleStates.slice()
        next[index] = enabled
        toggleStates = next
    }

    function runCommand(cmd) {
        commandProcess.command = ["sh", "-c", cmd]
        commandProcess.running = true
    }

    function toggleState(index, label) {
        let next = toggleStates.slice()
        next[index] = !next[index]
        toggleStates = next

        if (label === "DND") {
            runCommand("makoctl mode -t do-not-disturb")
        } else if (label === "WiFi") {
            runCommand("nm-connection-editor || kitty -e nmtui-connect || notify-send 'Network settings unavailable'")
        } else if (label === "BT") {
            if (next[index]) {
                runCommand("rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on; blueman-manager || notify-send 'Bluetooth manager unavailable'")
            } else {
                runCommand("bluetoothctl power off; notify-send 'Bluetooth' 'Powered off'")
            }
        } else if (label === "Cool") {
            runCommand("if command -v powerprofilesctl >/dev/null 2>&1; then powerprofilesctl set " + (next[index] ? "power-saver" : "balanced") + "; else notify-send 'Power profiles unavailable' 'Install power-profiles-daemon for Cool mode'; fi")
        } else if (label === "Night") {
            runCommand("$HOME/niri-config/thinh-swiss/switch-theme.sh toggle")
        }
    }

    Process { id: commandProcess; command: ["true"] }

    Process {
        id: btStateProcess
        command: ["sh", "-c", "bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2; exit}'"]
        stdout: SplitParser {
            onRead: data => toggleGridWidget.setToggleState(3, data.trim() === "yes")
        }
    }

    Process {
        id: themeStateProcess
        command: ["sh", "-c", "test -f \"$HOME/niri-config/thinh-swiss/current\" && cat \"$HOME/niri-config/thinh-swiss/current\" || echo light"]
        stdout: SplitParser {
            onRead: data => toggleGridWidget.setToggleState(1, data.trim() === "dark")
        }
    }

    Component.onCompleted: {
        btStateProcess.running = true
        themeStateProcess.running = true
    }

    radius: 8
    clip: true
    color: toggleGridWidget.colorMain
    border.width: 1
    border.color: Theme.border

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5
            color: toggleGridWidget.colorAccent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\uf013"
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 13
                    color: Theme.onAccentText
                }

                Text {
                    text: "Toggles"
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.onAccentText
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignTop
            columns: 2
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: [
                    { icon: "\uf017", label: "DND", hint: "Notifications", color: toggleGridWidget.colorSecondary, textColor: Theme.secondaryStrong, live: true },
                    { icon: "\uf186", label: "Night", hint: "Theme", color: toggleGridWidget.colorAccent, textColor: Theme.accentStrong, live: true },
                    { icon: "\uf1eb", label: "WiFi", hint: "Networks", color: toggleGridWidget.colorOrange, textColor: Theme.secondaryStrong, live: true },
                    { icon: "\uf293", label: "BT", hint: "Bluetooth", color: toggleGridWidget.colorAccent, textColor: Theme.accentStrong, live: true },
                    { icon: "\uf2dc", label: "Cool", hint: "Power saver", color: toggleGridWidget.colorAccentDim, textColor: Theme.accentStrong, live: true },
                    { icon: "\uf023", label: "Lock", hint: "Visual only", color: toggleGridWidget.colorSecondary, textColor: Theme.secondaryStrong, live: false }
                ]

                Rectangle {
                    id: toggleCard
                    required property var modelData
                    required property int index

                    property bool isActive: toggleGridWidget.toggleStates[index] || false

                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 56
                    radius: 8
                    color: toggleHover.containsMouse ? Theme.surface2 : Theme.surface
                    border.width: 1
                    border.color: isActive ? modelData.color : Theme.border
                    scale: toggleTap.pressed ? 0.99 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            radius: 6
                            color: toggleCard.isActive ? toggleCard.modelData.color : Theme.bg

                            Text {
                                anchors.centerIn: parent
                                text: toggleCard.modelData.icon
                                font.family: "Font Awesome 6 Free Solid"
                                font.weight: Font.Black
                                font.pixelSize: 13
                                color: toggleCard.isActive ? Theme.onAccentText : toggleCard.modelData.textColor
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: toggleCard.modelData.label
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                font.bold: true
                                color: Theme.text
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: toggleCard.modelData.hint
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                color: toggleCard.isActive ? toggleCard.modelData.textColor : Theme.muted
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignVCenter
                            width: 38
                            height: 20
                            radius: 10
                            color: toggleCard.isActive ? toggleCard.modelData.color : Theme.surface2
                            border.width: 1
                            border.color: toggleCard.isActive ? toggleCard.modelData.color : Theme.border

                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                y: 3
                                x: toggleCard.isActive ? parent.width - width - 4 : 4
                                color: toggleCard.isActive ? "#000000" : Theme.text

                                Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }
                        }
                    }

                    HoverHandler { id: toggleHover }

                    TapHandler {
                        id: toggleTap
                        onTapped: {
                            if (toggleCard.modelData.live) {
                                toggleGridWidget.toggleState(toggleCard.index, toggleCard.modelData.label)
                            } else {
                                let next = toggleGridWidget.toggleStates.slice()
                                next[toggleCard.index] = !next[toggleCard.index]
                                toggleGridWidget.toggleStates = next
                            }
                        }
                    }
                }
            }
        }
    }
}
