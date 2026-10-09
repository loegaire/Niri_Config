// SystemTrayWidget.qml
// Interactive system tray cards
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import ".."

Rectangle {
    id: trayWidget

    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.border
    property var parentWindowRef: null

    function resolveParentWindow() {
        function findBackingWindow(obj) {
            let current = obj
            while (current) {
                if (current._backingWindow) return current._backingWindow
                if (current.window && current.window.toString && current.window.toString().includes("QQuickWindow")) {
                    return current.window
                }
                current = current.parent
            }
            return null
        }

        return Window.window
            || trayWidget.window
            || (trayWidget.Window ? trayWidget.Window.window : null)
            || findBackingWindow(trayWidget)
            || (Qt.application.allWindows && Qt.application.allWindows.length > 0 ? Qt.application.allWindows[0] : null)
            || Qt.application.activeWindow
    }

    function itemLabel(item) {
        return item.tooltipTitle || item.title || item.id || "Tray"
    }

    function itemSubLabel(item) {
        return item.status || (item.onlyMenu ? "Menu" : "Open")
    }

    function openMenu(item, targetItem) {
        if (!item.hasMenu || !item.menu || !item.display) return
        let parentWindow = trayWidget.parentWindowRef
        if (!parentWindow) {
            parentWindow = trayWidget.resolveParentWindow()
            trayWidget.parentWindowRef = parentWindow
        }
        if (!parentWindow) {
            console.warn("SystemTrayWidget: menu parent window unavailable")
            return
        }
        let relX = Math.round(targetItem.x + targetItem.width * 0.5)
        let relY = Math.round(targetItem.y + targetItem.height)
        item.display(parentWindow, relX, relY)
    }

    Component.onCompleted: Qt.callLater(function() {
        parentWindowRef = resolveParentWindow()
    })
    onWindowChanged: parentWindowRef = resolveParentWindow()

    radius: 10
    clip: true
    color: trayWidget.colorMain

    border.width: 1
    border.color: colorAccent

    Item {
        anchors.fill: parent
        z: 2
        opacity: 0.9

        Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8; width: 26; height: 2; color: trayWidget.colorAccent }
        Rectangle { anchors.left: parent.left; anchors.top: parent.top; anchors.margins: 8; width: 2; height: 26; color: trayWidget.colorAccent }
        Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; width: 26; height: 2; color: trayWidget.colorMainLight }
        Rectangle { anchors.right: parent.right; anchors.top: parent.top; anchors.margins: 8; width: 2; height: 26; color: trayWidget.colorMainLight }
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8; width: 24; height: 2; color: trayWidget.colorSecondary }
        Rectangle { anchors.left: parent.left; anchors.bottom: parent.bottom; anchors.margins: 8; width: 2; height: 24; color: trayWidget.colorSecondary }
        Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; width: 24; height: 2; color: trayWidget.colorAccentDim }
        Rectangle { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; width: 2; height: 24; color: trayWidget.colorAccentDim }

        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 26
            anchors.bottomMargin: 18
            width: 56
            height: 1
            color: "#b8b8b8"
            opacity: 0.45
            rotation: -18
        }

        Rectangle {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 22
            anchors.bottomMargin: 18
            width: 6
            height: 6
            radius: 3
            color: trayWidget.colorAccent
            opacity: 0.7
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 22
            radius: 6
            color: trayWidget.colorAccent

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 6

                Text {
                    text: "\uf2d2"
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 10
                    color: trayWidget.colorMain
                }

                Text {
                    text: "Tray"
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: trayWidget.colorMain
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: width > 280 ? 2 : 1
            rowSpacing: 8
            columnSpacing: 8

            Repeater {
                id: trayRepeater
                model: SystemTray.items

                Rectangle {
                    id: trayCard
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.minimumHeight: 58
                    radius: 12
                    color: trayHover.containsMouse ? Theme.border : Theme.surface2
                    border.width: 1
                    border.color: trayHover.containsMouse ? trayWidget.colorAccent : trayWidget.colorSecondary2
                    scale: trayPress.pressed ? 0.985 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }
                    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 10

                        Rectangle {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            radius: 10
                            color: Theme.surface
                            border.width: 1
                            border.color: trayHover.containsMouse ? trayWidget.colorAccentDim : Theme.border

                            Image {
                                anchors.centerIn: parent
                                width: 20
                                height: 20
                                property string fallbackIcon: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='20' height='20' viewBox='0 0 20 20' fill='none' stroke='%23a7cdd9' stroke-width='1.5'><rect x='2.5' y='2.5' width='15' height='11' rx='2'/><path d='M6 17h8'/></svg>"
                                source: (trayCard.modelData.icon && trayCard.modelData.icon.indexOf("input-keyboard-symbolic") !== -1)
                                    ? fallbackIcon
                                    : (trayCard.modelData.icon || fallbackIcon)
                                sourceSize.width: 20
                                sourceSize.height: 20
                                smooth: true
                                mipmap: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: trayWidget.itemLabel(trayCard.modelData)
                                font.pixelSize: 10
                                font.family: "JetBrains Mono"
                                font.bold: true
                                color: trayWidget.colorAccent
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: trayWidget.itemSubLabel(trayCard.modelData)
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                                color: trayWidget.colorMainLight
                                elide: Text.ElideRight
                                opacity: 0.9
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: trayCard.modelData.hasMenu ? Theme.surface : "transparent"
                            visible: trayCard.modelData.hasMenu

                            Text {
                                anchors.centerIn: parent
                                text: "\uf054"
                                font.family: "Font Awesome 6 Free Solid"
                                font.pixelSize: 9
                                color: trayWidget.colorAccent
                            }
                        }
                    }

                    HoverHandler {
                        id: trayHover
                    }

                    TapHandler {
                        id: trayPress
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onTapped: eventPoint => {
                            const item = trayCard.modelData
                            if (eventPoint.button === Qt.RightButton && item.hasMenu && item.menu) {
                                trayWidget.openMenu(item, trayCard)
                                return
                            }

                            if ((item.onlyMenu || item.hasMenu) && item.menu) {
                                trayWidget.openMenu(item, trayCard)
                            } else {
                                item.activate()
                            }
                        }
                    }
                }
            }

            Text {
                visible: trayRepeater.count === 0
                text: "No tray apps"
                font.pixelSize: 10
                font.family: "JetBrains Mono"
                color: trayWidget.colorMainLight
                opacity: 0.6
                Layout.columnSpan: 2
                Layout.alignment: Qt.AlignCenter
            }
        }
    }
}
