// LeftBar.qml
// Vertical status bar on the left side
import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray
import "components"

Scope {
    id: leftBarScope
    
    // Visibility state for the unified panel
    property bool unifiedPanelVisible: false
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: bar
            required property var modelData
            screen: modelData
            
            // Color scheme
            readonly property color colorMain: Theme.surface
            readonly property color colorMainLight: Theme.accentStrong
            readonly property color colorMainDark: Theme.bg
            readonly property color colorAccent: Theme.accentStrong
            readonly property color colorAccentDim: Theme.accent2
            readonly property color colorSecondary: Theme.secondaryStrong
            readonly property color colorSecondary2: Theme.border
            readonly property int cardWidth: 36
            readonly property int cardRadius: 14
            readonly property int itemSpacing: 4
            readonly property int topPadding: 6
            readonly property int sliderHeight: Math.max(72, Math.min(128, Math.floor((height - 330) / 2)))
            
            anchors {
                top: true
                left: true
                bottom: true
            }
            
            implicitWidth: 50
            exclusionMode: ExclusionMode.Normal
            exclusiveZone: implicitWidth
            color: "transparent"
            
            Item {
                anchors.fill: parent
                anchors.margins: 2

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: Theme.bg
                    opacity: 0.96
                    border.width: 1
                    border.color: Theme.border

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 1
                        height: 18
                        radius: parent.radius
                        color: Theme.surface2
                        opacity: Theme.mode === "light" ? 0.42 : 0.22
                    }

                    ColumnLayout {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 4
                        anchors.topMargin: bar.topPadding
                        anchors.bottomMargin: 6
                        spacing: bar.itemSpacing

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: workspaceWidget.implicitHeight + 8 
                            radius: bar.cardRadius
                            color: Theme.surface
                            border.color: Theme.accentStrong
                            border.width: 1

                            WorkspacesWidget {
                                id: workspaceWidget
                                anchors.fill: parent
                                anchors.margins: 6
                                compact: false
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: 40
                            radius: bar.cardRadius
                            color: Theme.surface
                            border.color: Theme.secondaryStrong
                            border.width: 1

                            ClockWidget {
                                id: clockWidget
                                anchors.fill: parent
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: 40
                            radius: bar.cardRadius
                            color: Theme.surface
                            border.color: Theme.border
                            border.width: 1

                            NetworkWidget {
                                anchors.fill: parent
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: bar.sliderHeight
                            radius: bar.cardRadius
                            color: "transparent"
                            border.color: Theme.accentStrong
                            border.width: 0

                            BrightnessWidget {
                                anchors.fill: parent
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: bar.sliderHeight
                            radius: bar.cardRadius
                            color: "transparent"
                            border.color: Theme.secondaryStrong
                            border.width: 0

                            VolumeWidget {
                                anchors.fill: parent
                            }
                        }

                        Item {
                            Layout.fillHeight: true
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: 38
                            radius: bar.cardRadius
                            color: Theme.surface
                            border.color: Theme.accentStrong
                            border.width: 1

                            BatteryWidget {
                                anchors.fill: parent
                            }
                        }

                        Repeater {
                            model: SystemTray.items

                            Rectangle {
                                required property var modelData
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: bar.cardWidth
                                Layout.preferredHeight: 40
                                radius: bar.cardRadius
                                color: "transparent"
                                border.color: Theme.accentStrong
                                border.width: 0

                                SidebarTrayItemWidget {
                                    anchors.fill: parent
                                    itemData: modelData
                                }
                            }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: bar.cardWidth
                            Layout.preferredHeight: powerWidget.implicitHeight + 8
                            radius: bar.cardRadius
                            color: "transparent"
                            border.color: Theme.accentStrong
                            border.width: 1

                            SidebarPowerWidget {
                                id: powerWidget
                                anchors.fill: parent
                            }
                        }
                    }
                }
            }
        }
    }
}
