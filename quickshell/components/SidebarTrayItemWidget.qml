// SidebarTrayItemWidget.qml
// Single full-size tray entry for the left rail
import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Services.SystemTray
import ".."

Rectangle {
    id: trayItemWidget

    required property var itemData

    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accentStrong

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
            || trayItemWidget.window
            || (trayItemWidget.Window ? trayItemWidget.Window.window : null)
            || findBackingWindow(trayItemWidget)
            || (Qt.application.allWindows && Qt.application.allWindows.length > 0 ? Qt.application.allWindows[0] : null)
            || Qt.application.activeWindow
    }

    function openMenu() {
        if (!itemData.hasMenu || !itemData.menu || !itemData.display) return
        let parentWindow = trayItemWidget.parentWindowRef
        if (!parentWindow) {
            parentWindow = trayItemWidget.resolveParentWindow()
            trayItemWidget.parentWindowRef = parentWindow
        }
        if (!parentWindow) return
        itemData.display(parentWindow, Math.round(width), Math.round(height))
    }

    Component.onCompleted: Qt.callLater(function() {
        parentWindowRef = resolveParentWindow()
    })
    onWindowChanged: parentWindowRef = resolveParentWindow()

    color: "transparent"

    Rectangle {
        anchors.fill: parent
        anchors.margins: 5
        radius: 10
        color: hover.containsMouse ? Theme.surface2 : Theme.surface
        border.width: 1
        border.color: trayItemWidget.colorMainLight

        Image {
            anchors.centerIn: parent
            width: 20
            height: 20
            property string fallbackIcon: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='14' height='14' viewBox='0 0 14 14' fill='none' stroke='%23a7f595' stroke-width='1'><rect x='1.8' y='1.8' width='10.4' height='7.4' rx='1.4'/><path d='M4.5 11.2h5'/></svg>"
            source: (trayItemWidget.itemData.icon && trayItemWidget.itemData.icon.indexOf("input-keyboard-symbolic") !== -1)
                ? fallbackIcon
                : (trayItemWidget.itemData.icon || fallbackIcon)
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
                if (mouse.button === Qt.RightButton && trayItemWidget.itemData.hasMenu && trayItemWidget.itemData.menu) {
                    trayItemWidget.openMenu()
                } else if ((trayItemWidget.itemData.onlyMenu || trayItemWidget.itemData.hasMenu) && trayItemWidget.itemData.menu) {
                    trayItemWidget.openMenu()
                } else {
                    trayItemWidget.itemData.activate()
                }
            }
        }
    }
}
