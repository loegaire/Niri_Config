// UnifiedPanel.qml
// A large centered popout merging all utility widgets
import Quickshell
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "components"

Scope {
    id: unifiedPanelScope
    
    property bool panelVisible: false
    property bool panelHovered: false
    
    Variants {
        model: Quickshell.screens
        
        PanelWindow {
            id: unifiedPanel
            required property var modelData
            screen: modelData
            
            // Theme Colors
            readonly property color colorMain: Theme.surface
            readonly property color colorMainLight: Theme.accent
            readonly property color colorAccent: Theme.accent
            readonly property color colorAccentDim: Theme.accent2
            readonly property color colorSecondary: Theme.secondary
            readonly property color colorSecondary2: Theme.border

            readonly property int leftBarOffset: 54
            implicitWidth: Math.round((screen.width - leftBarOffset) * 0.86)
            implicitHeight: Math.round(screen.height * 0.90)
            anchors {
                top: true
                left: true
            }
            margins {
                left: leftBarOffset + Math.max(0, Math.round((screen.width - leftBarOffset - implicitWidth) / 2))
                top: 42
            }
            exclusionMode: ExclusionMode.Ignore
            
            visible: unifiedPanelScope.panelVisible
            color: "transparent"
            
            Rectangle {
                id: panelContent
                anchors.fill: parent
                radius: 16
                color: "transparent"

                HoverHandler {
                    id: panelHover
                    onHoveredChanged: unifiedPanelScope.panelHovered = hovered
                }
                
                // A single quiet image layer is enough; utility widgets stay solid for readability.
                Image {
                    anchors.fill: parent
                    source: "file:///home/thinh/niri-config/quickshell/asset2.jpg"
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.16
                    z: -2
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: panelContent.width
                            height: panelContent.height
                            radius: panelContent.radius
                        }
                    }
                }
                
                // Dark overlay for readability
                Rectangle {
                    anchors.fill: parent
                    color: unifiedPanel.colorMain
                    opacity: 0.84
                    radius: panelContent.radius
                    z: -1
                }
                
                // Shadow
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -2
                    radius: panelContent.radius
                    color: Theme.bg
                    opacity: 0.5
                    z: -2
                }
                
                readonly property int contentMargin: 14
                readonly property int contentGap: 12
                readonly property real innerWidth: panelContent.width - (contentMargin * 2)
                
                Flickable {
                    id: panelFlick
                    anchors.fill: parent
                    contentWidth: width
                    contentHeight: contentRoot.height
                    clip: true
                    interactive: contentHeight > height
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AlwaysOff }
                    
                    Item {
                        id: contentRoot
                        width: panelFlick.width
                        readonly property int topHeight: 520
                        readonly property int middleHeight: 390
                        readonly property int bottomHeight: 460
                        readonly property int utilityHeight: 300
                        readonly property int leftMargin: panelContent.contentMargin
                        readonly property int topMargin: panelContent.contentMargin
                        readonly property int gap: panelContent.contentGap
                        readonly property real usableWidth: width - (leftMargin * 2)
                        height: topMargin + topHeight + gap + middleHeight + gap + bottomHeight + gap + utilityHeight + topMargin

                        Item {
                            id: topSection
                            x: contentRoot.leftMargin
                            y: contentRoot.topMargin
                            width: contentRoot.usableWidth
                            height: contentRoot.topHeight

                            CalendarWidget {
                                id: calendar
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.round((parent.width - contentRoot.gap) * 0.58)
                            }

                            ColumnLayout {
                                anchors.left: calendar.right
                                anchors.leftMargin: contentRoot.gap
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                spacing: contentRoot.gap

                                MediaPlayerWidget {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 205
                                    Layout.minimumHeight: 190
                                }

                                WeatherWidget {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.minimumHeight: 215
                                }
                            }
                        }

                        Item {
                            id: middleSection
                            x: contentRoot.leftMargin
                            y: topSection.y + topSection.height + contentRoot.gap
                            width: contentRoot.usableWidth
                            height: contentRoot.middleHeight

                            SystemInfoWidget {
                                id: systemInfo
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.round((parent.width - contentRoot.gap) * 0.52)
                            }

                            ClipboardWidget {
                                anchors.left: systemInfo.right
                                anchors.leftMargin: contentRoot.gap
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                            }
                        }

                        Item {
                            id: bottomSection
                            x: contentRoot.leftMargin
                            y: middleSection.y + middleSection.height + contentRoot.gap
                            width: contentRoot.usableWidth
                            height: contentRoot.bottomHeight

                            NotesWidget {
                                id: notes
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.round((parent.width - contentRoot.gap) * 0.32)
                            }

                            Item {
                                anchors.left: notes.right
                                anchors.leftMargin: contentRoot.gap
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom

                                ToggleGridWidget {
                                    id: toggles
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: Math.round((parent.width - contentRoot.gap) * 0.43)
                                }

                                ActionButtonsWidget {
                                    anchors.left: toggles.right
                                    anchors.leftMargin: contentRoot.gap
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                }
                            }
                        }

                        Item {
                            id: utilitySection
                            x: contentRoot.leftMargin
                            y: bottomSection.y + bottomSection.height + contentRoot.gap
                            width: contentRoot.usableWidth
                            height: contentRoot.utilityHeight

                            ColumnLayout {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: Math.round((parent.width - contentRoot.gap) * 0.34)
                                spacing: contentRoot.gap

                                QuoteWidget {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 96
                                }

                                PowerWidget {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }

                            RowLayout {
                                anchors.left: parent.left
                                anchors.leftMargin: Math.round((parent.width - contentRoot.gap) * 0.34) + contentRoot.gap
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                spacing: contentRoot.gap

                                SystemTrayWidget {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
