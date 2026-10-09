// ActionButtonsWidget.qml
// Launch shortcuts as compact Swiss utility tiles.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: actionButtonsWidget

    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorOrange: Theme.secondary2
    readonly property color colorRed: Theme.critical

    function runCommand(cmd) {
        actionProcess.command = ["sh", "-c", cmd]
        actionProcess.running = true
    }

    function handleAction(label) {
        switch (label) {
        case "Snap":
            runCommand("grim -g \"$(slurp)\" - | wl-copy")
            break
        case "Rec":
            runCommand("obs")
            break
        case "Theme":
            runCommand("nwg-look || xdg-open \"$HOME/.config\"")
            break
        case "Files":
            runCommand("thunar || xdg-open \"$HOME\"")
            break
        case "Term":
            runCommand("kitty")
            break
        case "Web":
            runCommand("firefox")
            break
        default:
            console.log("Action:", label)
        }
    }

    Process { id: actionProcess; command: ["true"] }

    radius: 8
    clip: true
    color: actionButtonsWidget.colorMain
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
            color: actionButtonsWidget.colorAccent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\uf0e7"
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 13
                    color: Theme.onAccentText
                }

                Text {
                    text: "Actions"
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
            columns: 3
            columnSpacing: 12
            rowSpacing: 12

            Repeater {
                model: [
                    { icon: "\uf030", label: "Snap", hint: "Area copy", color: actionButtonsWidget.colorAccent, textColor: Theme.accentStrong },
                    { icon: "\uf03d", label: "Rec", hint: "OBS", color: actionButtonsWidget.colorRed, textColor: actionButtonsWidget.colorRed },
                    { icon: "\uf53f", label: "Theme", hint: "Look", color: actionButtonsWidget.colorSecondary, textColor: Theme.secondaryStrong },
                    { icon: "\uf07b", label: "Files", hint: "Home", color: actionButtonsWidget.colorOrange, textColor: Theme.secondaryStrong },
                    { icon: "\uf120", label: "Term", hint: "Kitty", color: actionButtonsWidget.colorAccentDim, textColor: Theme.accentStrong },
                    { icon: "\uf269", label: "Web", hint: "Firefox", color: actionButtonsWidget.colorAccent, textColor: Theme.accentStrong }
                ]

                Rectangle {
                    id: actionCard
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    Layout.preferredHeight: 60
                    radius: 8
                    color: actionHover.containsMouse ? Theme.surface2 : Theme.surface
                    border.width: 1
                    border.color: actionHover.containsMouse ? modelData.color : Theme.border
                    scale: actionTap.pressed ? 0.99 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            radius: 6
                            color: actionCard.modelData.color

                            Text {
                                anchors.centerIn: parent
                                text: actionCard.modelData.icon
                                font.family: "Font Awesome 6 Free Solid"
                                font.weight: Font.Black
                                font.pixelSize: 13
                                color: Theme.onAccentText
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: actionCard.modelData.label
                                font.pixelSize: 12
                                font.family: "JetBrains Mono"
                                font.bold: true
                                color: Theme.text
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: actionCard.modelData.hint
                                font.pixelSize: 11
                                font.family: "JetBrains Mono"
                                color: actionCard.modelData.textColor
                                elide: Text.ElideRight
                            }
                        }

                        Text {
                            text: "\uf105"
                            font.family: "Font Awesome 6 Free Solid"
                            font.weight: Font.Black
                            font.pixelSize: 13
                            color: actionHover.containsMouse ? actionCard.modelData.textColor : Theme.muted2
                        }
                    }

                    HoverHandler { id: actionHover }

                    TapHandler {
                        id: actionTap
                        onTapped: actionButtonsWidget.handleAction(actionCard.modelData.label)
                    }
                }
            }
        }
    }
}
