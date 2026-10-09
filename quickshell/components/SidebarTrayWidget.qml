// SidebarTrayWidget.qml
// Full-size stacked tray entries for the left rail
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import ".."

Rectangle {
    id: sidebarTray

    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorSecondary2: Theme.border
    property var parentWindowRef: null
    readonly property int itemHeight: 34
    readonly property int itemGap: 4

    implicitWidth: 36
    implicitHeight: Math.max(0, (trayRepeater.count * itemHeight) + (Math.max(0, trayRepeater.count - 1) * itemGap) + 10)
    color: "transparent"

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
            || sidebarTray.window
            || (sidebarTray.Window ? sidebarTray.Window.window : null)
            || findBackingWindow(sidebarTray)
            || (Qt.application.allWindows && Qt.application.allWindows.length > 0 ? Qt.application.allWindows[0] : null)
            || Qt.application.activeWindow
    }

    function openMenu(item, targetItem) {
        if (!item.hasMenu || !item.menu || !item.display) return
        let parentWindow = sidebarTray.parentWindowRef
        if (!parentWindow) {
            parentWindow = sidebarTray.resolveParentWindow()
            sidebarTray.parentWindowRef = parentWindow
        }
        if (!parentWindow) return
        item.display(parentWindow, Math.round(targetItem.x + targetItem.width), Math.round(targetItem.y + targetItem.height))
    }

    Component.onCompleted: Qt.callLater(function() {
        parentWindowRef = resolveParentWindow()
    })
    onWindowChanged: parentWindowRef = resolveParentWindow()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 5
        spacing: sidebarTray.itemGap

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            Rectangle {
                id: trayButton
                required property var modelData

                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: 26
                Layout.preferredHeight: 34
                radius: 8
                color: hover.containsMouse ? Theme.border : Theme.bg
                border.width: 1
                border.color: sidebarTray.colorMainLight

                Image {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    property string fallbackIcon: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 14 14' fill='none' stroke='%23a7cdd9' stroke-width='1'><rect x='1.8' y='1.8' width='10.4' height='7.4' rx='1.4'/><path d='M4.5 11.2h5'/></svg>"
                    source: (trayButton.modelData.icon && trayButton.modelData.icon.indexOf("input-keyboard-symbolic") !== -1)
                        ? fallbackIcon
                        : (trayButton.modelData.icon || fallbackIcon)
                    sourceSize.width: 14
                    sourceSize.height: 14
                    smooth: true
                    mipmap: true
                }

                MouseArea {
                    id: hover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        const item = trayButton.modelData
                        if (mouse.button === Qt.RightButton && item.hasMenu && item.menu) {
                            sidebarTray.openMenu(item, trayButton)
                        } else if ((item.onlyMenu || item.hasMenu) && item.menu) {
                            sidebarTray.openMenu(item, trayButton)
                        } else {
                            item.activate()
                        }
                    }
                }
            }
        }
    }
}
