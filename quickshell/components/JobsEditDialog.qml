// JobsEditDialog.qml
// In-widget overlay dialog to add/remove weekly-recurring jobs.
// Operates on a local working copy; Save writes it through WeeklyJobs.replaceAllJobs().
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

Rectangle {
    id: dialog

    // ---- API ----------------------------------------------------------
    function openDialog(): void {
        // Snapshot current jobs into the working model.
        workingJobs = WeeklyJobs.jobs.map(function(j) { return WeeklyJobs.copyJob(j) })
        editingDay = WeeklyJobs.dayOfWeek(WeeklyJobs.now)
        newTitle.text = ""
        newDetail.text = ""
        newUrl.text = ""
        visible = true
    }

    function closeDialog(): void {
        visible = false
    }

    function confirmSave(): void {
        WeeklyJobs.replaceAllJobs(workingJobs)
        closeDialog()
    }

    // ---- state --------------------------------------------------------
    property var workingJobs: []
    property int editingDay: 0
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var dayLong: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

    function dayJobs(day: int): var {
        return workingJobs.filter(function(j) { return j.day === day })
    }

    function addWorkingJob(): void {
        var title = newTitle.text.trim()
        if (title.length === 0) return
        var url = newUrl.text.trim()
        workingJobs = workingJobs.concat([{
            id: "",
            day: editingDay,
            title: title,
            detail: newDetail.text.trim(),
            url: url.length > 0 && WeeklyJobs.isUrl(url) ? url : "",
            done: false
        }])
        newTitle.text = ""
        newDetail.text = ""
        newUrl.text = ""
    }

    function removeWorkingJob(index: int): void {
        var copy = workingJobs.slice()
        copy.splice(index, 1)
        workingJobs = copy
    }

    function workingDirty(): bool {
        if (workingJobs.length !== WeeklyJobs.jobs.length) return true
        return JSON.stringify(workingJobs.map(function(j) { return {id: j.id, day: j.day, title: j.title, detail: j.detail, url: j.url} }))
             !== JSON.stringify(WeeklyJobs.jobs.map(function(j) { return {id: j.id, day: j.day, title: j.title, detail: j.detail, url: j.url} }))
    }

    visible: false
    color: "#e6000000"

    // Dim background; swallow clicks
    MouseArea {
        anchors.fill: parent
        onClicked: dialog.closeDialog()
    }

    // Dialog panel
    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(parent.width - 16, 480)
        height: Math.min(parent.height - 16, 470)
        radius: 8
        color: Theme.surface
        border.width: 1
        border.color: Theme.accent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "\uf0ae"  // fa-list-check
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 14
                    color: Theme.secondaryStrong
                }

                Text {
                    Layout.fillWidth: true
                    text: "Weekly jobs"
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.secondaryStrong
                }

                Rectangle {
                    width: 26
                    height: 26
                    radius: 4
                    color: closeBtn.containsMouse ? Theme.border : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf00d"  // fa-xmark
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 12
                        color: Theme.critical
                    }

                    MouseArea {
                        id: closeBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.closeDialog()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Weekday selector
            RowLayout {
                Layout.fillWidth: true
                spacing: 3

                Repeater {
                    model: 7

                    Rectangle {
                        required property int index
                        readonly property bool active: dialog.editingDay === index
                        readonly property int count: dialog.dayJobs(index).length

                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 4
                        color: active
                            ? (dayHover.containsMouse ? Theme.accent2 : Theme.accent)
                            : (dayHover.containsMouse ? Theme.border : Theme.surface2)
                        border.width: active ? 0 : 1
                        border.color: Theme.border

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 0

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: dialog.dayNames[index]
                                font.pixelSize: 10
                                font.family: "JetBrains Mono"
                                font.bold: true
                                color: active ? Theme.onAccentText : Theme.muted
                            }

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: count > 0 ? String(count) : "·"
                                font.pixelSize: 8
                                font.family: "JetBrains Mono"
                                color: active ? Theme.onAccentText : Theme.muted2
                            }
                        }

                        MouseArea {
                            id: dayHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialog.editingDay = index
                        }
                    }
                }
            }

            // Selected day title
            Text {
                Layout.fillWidth: true
                text: dialog.dayLong[dialog.editingDay] + " — " + dialog.dayJobs(dialog.editingDay).length + " job(s)"
                font.pixelSize: 11
                font.family: "JetBrains Mono"
                color: Theme.muted
            }

            // Jobs list for selected day
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 4

                    Text {
                        Layout.fillWidth: true
                        text: "No jobs on this day"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.muted
                        opacity: 0.5
                        horizontalAlignment: Text.AlignHCenter
                        visible: dialog.dayJobs(dialog.editingDay).length === 0
                    }

                    Repeater {
                        model: dialog.dayJobs(dialog.editingDay)

                        Rectangle {
                            required property var modelData
                            // map to a global index in workingJobs for removal
                            readonly property int globalIndex: dialog.workingJobs.indexOf(modelData)

                            Layout.fillWidth: true
                            Layout.preferredHeight: row.implicitHeight + 10
                            radius: 4
                            color: Theme.bg
                            border.width: 1
                            border.color: Theme.border

                            RowLayout {
                                id: row
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 6

                                Text {
                                    text: "\uf0ae"  // fa-list-check
                                    font.family: "Font Awesome 6 Free Solid"
                                    font.pixelSize: 10
                                    color: Theme.accentStrong
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.pixelSize: 11
                                        font.family: "JetBrains Mono"
                                        color: Theme.text
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.detail + (modelData.url ? "  \uf08e" : "")
                                        font.pixelSize: 9
                                        font.family: "JetBrains Mono"
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        visible: modelData.detail.length > 0 || modelData.url.length > 0
                                    }
                                }

                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: removeBtn.containsMouse ? Theme.critical : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00d"  // fa-xmark
                                        font.family: "Font Awesome 6 Free Solid"
                                        font.pixelSize: 10
                                        color: Theme.critical
                                    }

                                    MouseArea {
                                        id: removeBtn
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: dialog.removeWorkingJob(globalIndex)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.border
            }

            // Add-job form
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Add job to " + dialog.dayLong[dialog.editingDay]
                    font.pixelSize: 10
                    font.family: "JetBrains Mono"
                    color: Theme.muted
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    radius: 4
                    color: Theme.bg
                    border.width: 1
                    border.color: newTitle.activeFocus ? Theme.accent : Theme.border

                    TextInput {
                        id: newTitle
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        clip: true
                        activeFocusOnPress: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "Title (e.g. IT4409 — check Teams)"
                            font: newTitle.font
                            color: Theme.muted
                            opacity: 0.5
                            visible: !newTitle.text && !newTitle.activeFocus
                        }

                        onAccepted: {
                            dialog.addWorkingJob()
                            newTitle.forceActiveFocus()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        radius: 4
                        color: Theme.bg
                        border.width: 1
                        border.color: newDetail.activeFocus ? Theme.accent : Theme.border

                        TextInput {
                            id: newDetail
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.pixelSize: 10
                            font.family: "JetBrains Mono"
                            color: Theme.text
                            clip: true
                            activeFocusOnPress: true
                            selectByMouse: true

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: "Detail (optional)"
                                font: newDetail.font
                                color: Theme.muted
                                opacity: 0.5
                                visible: !newDetail.text && !newDetail.activeFocus
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 4
                    color: Theme.bg
                    border.width: 1
                    border.color: newUrl.activeFocus ? Theme.accent : (newUrl.text.length > 0 && !WeeklyJobs.isUrl(newUrl.text.trim()) ? Theme.critical : Theme.border)

                    TextInput {
                        id: newUrl
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        clip: true
                        activeFocusOnPress: true
                        selectByMouse: true

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: "URL (optional, https://…)"
                            font: newUrl.font
                            color: Theme.muted
                            opacity: 0.5
                            visible: !newUrl.text && !newUrl.activeFocus
                        }
                    }
                }

                // Validation hint
                Text {
                    Layout.fillWidth: true
                    text: newUrl.text.length > 0 && !WeeklyJobs.isUrl(newUrl.text.trim())
                          ? "URL must start with http:// or https://"
                          : ""
                    font.pixelSize: 9
                    font.family: "JetBrains Mono"
                    color: Theme.critical
                    visible: text.length > 0
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: addBtnText.implicitWidth + 20
                        Layout.preferredHeight: 30
                        radius: 4
                        color: addBtn.containsMouse && newTitle.text.trim().length > 0
                            ? Theme.accent2 : (newTitle.text.trim().length > 0 ? Theme.accent : Theme.surface2)
                        border.width: newTitle.text.trim().length > 0 ? 0 : 1
                        border.color: Theme.border
                        opacity: newTitle.text.trim().length > 0 ? 1 : 0.5

                        Text {
                            id: addBtnText
                            anchors.centerIn: parent
                            text: "Add"
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            font.bold: true
                            color: newTitle.text.trim().length > 0 ? Theme.onAccentText : Theme.muted2
                        }

                        MouseArea {
                            id: addBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: dialog.addWorkingJob()
                        }
                    }
                }
            }

            // Footer: save / cancel / restore defaults
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: dialog.workingDirty() ? "unsaved changes" : ""
                    font.pixelSize: 9
                    font.family: "JetBrains Mono"
                    color: Theme.secondaryStrong
                }

                Rectangle {
                    Layout.preferredWidth: restoreBtnText.implicitWidth + 16
                    Layout.preferredHeight: 30
                    radius: 4
                    color: restoreBtn.containsMouse ? Theme.border : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Text {
                        id: restoreBtnText
                        anchors.centerIn: parent
                        text: "\uf01e defaults"  // fa-rotate-right
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 10
                        color: Theme.muted
                    }

                    MouseArea {
                        id: restoreBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            dialog.workingJobs = WeeklyJobs.seedJobs()
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: cancelBtnText.implicitWidth + 16
                    Layout.preferredHeight: 30
                    radius: 4
                    color: cancelBtn.containsMouse ? Theme.border : "transparent"
                    border.width: 1
                    border.color: Theme.border

                    Text {
                        id: cancelBtnText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.muted
                    }

                    MouseArea {
                        id: cancelBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.closeDialog()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: saveBtnText.implicitWidth + 20
                    Layout.preferredHeight: 30
                    radius: 4
                    color: saveBtn.containsMouse ? Theme.accent2 : Theme.accent

                    Text {
                        id: saveBtnText
                        anchors.centerIn: parent
                        text: "\uf0c7 Save"  // fa-floppy-disk
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 11
                        color: Theme.onAccentText
                    }

                    MouseArea {
                        id: saveBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: dialog.confirmSave()
                    }
                }
            }
        }
    }
}
