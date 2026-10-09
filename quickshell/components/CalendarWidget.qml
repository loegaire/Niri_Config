// CalendarWidget.qml
// Calendar with khal event management + weekly job tracker.
//
// Weekly jobs are stored/persisted by the WeeklyJobs singleton. The bottom
// half of the widget lists today's recurring jobs; clicking one toggles its
// "finished" state, which also stops its 10-minute reminder notifications
// for the rest of the week (state auto-resets next week).
// The gear button opens a dialog to add/remove jobs for any weekday.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: calendarWidget

    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accent
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.border
    readonly property color colorCyan: Theme.accent
    readonly property color colorYellow: Theme.accent
    readonly property color colorRed: Theme.critical

    // Calendar state
    property date currentDate: new Date()
    property date selectedDate: new Date()
    property date viewDate: new Date()  // Month being viewed
    property var events: []  // khal events for selected date
    property var monthEvents: ({})  // All khal events in current month {day: [events]}
    property string statusMessage: ""
    property bool backendReady: true

    // View state
    property bool showEventView: false
    property int bottomTab: 0  // 0 = today's jobs, 1 = khal events for selected date
    readonly property var todayJobs: WeeklyJobs.jobsForDay(WeeklyJobs.dayOfWeek(WeeklyJobs.now))

    // Jobs editor dialog (lazily instantiated, overlays this widget)
    property alias jobsEditor: jobsEditorLoader.item

    implicitWidth: 520
    implicitHeight: showEventView ? 560 : 520
    radius: 8
    clip: true
    color: calendarWidget.colorMain

    border.width: 1
    border.color: Theme.border

    // Helper functions
    function formatDate(d: date): string {
        let year = d.getFullYear()
        let month = String(d.getMonth() + 1).padStart(2, '0')
        let day = String(d.getDate()).padStart(2, '0')
        return year + "-" + month + "-" + day
    }

    function getMonthName(month: int): string {
        let names = ["January", "February", "March", "April", "May", "June",
                     "July", "August", "September", "October", "November", "December"]
        return names[month]
    }

    function getDaysInMonth(year: int, month: int): int {
        return new Date(year, month + 1, 0).getDate()
    }

    function getFirstDayOfMonth(year: int, month: int): int {
        return new Date(year, month, 1).getDay()
    }

    function prevMonth() {
        let newDate = new Date(viewDate)
        newDate.setMonth(newDate.getMonth() - 1)
        viewDate = newDate
        loadMonthEvents()
    }

    function nextMonth() {
        let newDate = new Date(viewDate)
        newDate.setMonth(newDate.getMonth() + 1)
        viewDate = newDate
        loadMonthEvents()
    }

    function selectDate(day: int) {
        selectedDate = new Date(viewDate.getFullYear(), viewDate.getMonth(), day)
        loadEventsForDate()
        showEventView = true
    }

    function loadEventsForDate() {
        eventProcess.command = ["khal", "list", formatDate(selectedDate), formatDate(selectedDate), "--format", "{title}|{start-time}|{end-time}|{uid}"]
        eventProcess.running = true
    }

    function loadMonthEvents() {
        let year = viewDate.getFullYear()
        let month = viewDate.getMonth()
        let startDate = formatDate(new Date(year, month, 1))
        let endDate = formatDate(new Date(year, month + 1, 0))
        monthEventProcess.command = ["khal", "list", startDate, endDate, "--format", "{start-date}|{title}"]
        monthEventProcess.running = true
    }

    function addEvent(title: string, isRecurrent: bool, recurrence: string) {
        let dateStr = formatDate(selectedDate)
        let cmd = ["sh", "-c", "khal new -a private " + dateStr + " 09:00 1h " + JSON.stringify(title)]
        if (isRecurrent && recurrence !== "") {
            cmd[2] += " --repeat " + JSON.stringify(recurrence)
        }
        addEventProcess.command = cmd
        calendarWidget.statusMessage = "Adding event..."
        addEventProcess.running = true
    }

    function openJobsEditor() {
        jobsEditorLoader.active = true
        jobsEditorLoader.item.openDialog()
    }

    // Process to load events for selected date
    Process {
        id: eventProcess
        command: ["true"]

        property string buffer: ""
        property string errBuffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => eventProcess.buffer += data
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: data => eventProcess.errBuffer += data
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                calendarWidget.backendReady = false
                calendarWidget.statusMessage = eventProcess.errBuffer.trim() || "Calendar backend failed"
                calendarWidget.events = []
                eventProcess.buffer = ""
                eventProcess.errBuffer = ""
                return
            }
            calendarWidget.backendReady = true
            calendarWidget.statusMessage = ""
            let lines = buffer.trim().split("\n")
            let loadedEvents = []
            for (let line of lines) {
                if (line.includes("|")) {
                    let parts = line.split("|")
                    loadedEvents.push({
                        title: parts[0] || "Untitled",
                        startTime: parts[1] || "",
                        endTime: parts[2] || "",
                        uid: parts[3] || "",
                        completed: false
                    })
                }
            }
            calendarWidget.events = loadedEvents
            buffer = ""
            errBuffer = ""
        }
    }

    // Process to load month overview
    Process {
        id: monthEventProcess
        command: ["true"]

        property string buffer: ""
        property string errBuffer: ""

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => monthEventProcess.buffer += data
        }

        stderr: SplitParser {
            splitMarker: ""
            onRead: data => monthEventProcess.errBuffer += data
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                calendarWidget.backendReady = false
                monthEventProcess.buffer = ""
                monthEventProcess.errBuffer = ""
                return
            }
            calendarWidget.backendReady = true
            let lines = buffer.trim().split("\n")
            let eventsMap = {}
            for (let line of lines) {
                if (line.includes("|")) {
                    let parts = line.split("|")
                    let dateStr = parts[0]
                    if (dateStr) {
                            let dayMatch = dateStr.match(/-(\d{2})$/)
                            if (dayMatch) {
                                let day = parseInt(dayMatch[1])
                                if (!eventsMap[day]) eventsMap[day] = []
                                eventsMap[day].push(parts[1] || "Event")
                            }
                    }
                }
            }
            calendarWidget.monthEvents = eventsMap
            buffer = ""
            errBuffer = ""
        }
    }

    // Process to add new event
    Process {
        id: addEventProcess
        command: ["true"]

        property string errBuffer: ""

        stderr: SplitParser {
            splitMarker: ""
            onRead: data => addEventProcess.errBuffer += data
        }

        onExited: exitCode => {
            if (exitCode !== 0) {
                calendarWidget.backendReady = false
                calendarWidget.statusMessage = addEventProcess.errBuffer.trim() || "Failed to add event"
                notifyProcess.command = ["notify-send", "Calendar event failed", calendarWidget.statusMessage]
                notifyProcess.running = true
            } else {
                calendarWidget.backendReady = true
                calendarWidget.statusMessage = "Event added"
                notifyProcess.command = ["notify-send", "Calendar event added", formatDate(calendarWidget.selectedDate)]
                notifyProcess.running = true
                loadEventsForDate()
                loadMonthEvents()
            }
            addEventProcess.errBuffer = ""
        }
    }

    Process {
        id: notifyProcess
        command: ["true"]
    }

    // Jobs editor dialog (created on demand)
    Loader {
        id: jobsEditorLoader
        active: false
        anchors.fill: parent
        source: "JobsEditDialog.qml"
    }

    Component.onCompleted: loadMonthEvents()

    ColumnLayout {
        anchors {
            fill: parent
            margins: 14
        }
        spacing: 8

        // Header with month/year navigation + jobs editor button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            // Previous month
            Rectangle {
                width: 30
                height: 30
                radius: 4
                color: prevBtn.containsMouse ? calendarWidget.colorAccentDim : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf053"  // fa-chevron-left
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 13
                    color: calendarWidget.colorAccent
                }

                MouseArea {
                    id: prevBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarWidget.prevMonth()
                }
            }

            // Month/Year display
            Text {
                Layout.fillWidth: true
                text: calendarWidget.getMonthName(viewDate.getMonth()) + " " + viewDate.getFullYear()
                font.pixelSize: 16
                font.family: "JetBrains Mono"
                font.bold: true
                color: Theme.secondaryStrong
                horizontalAlignment: Text.AlignHCenter
            }

            // Next month
            Rectangle {
                width: 30
                height: 30
                radius: 4
                color: nextBtn.containsMouse ? calendarWidget.colorAccentDim : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf054"  // fa-chevron-right
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 13
                    color: calendarWidget.colorAccent
                }

                MouseArea {
                    id: nextBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarWidget.nextMonth()
                }
            }

            // Jobs editor (add/remove weekly jobs)
            Rectangle {
                width: 30
                height: 30
                radius: 4
                color: editJobsBtn.containsMouse ? calendarWidget.colorAccentDim : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "\uf013"  // fa-gear
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 13
                    color: calendarWidget.colorAccent
                }

                MouseArea {
                    id: editJobsBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: calendarWidget.openJobsEditor()
                }
            }
        }

        // Day headers
        RowLayout {
            Layout.fillWidth: true
            spacing: 2

            Repeater {
                model: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]

                Text {
                    Layout.fillWidth: true
                    text: modelData
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.muted
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        // Calendar grid (compact)
        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 216
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                id: daysRepeater
                model: 42  // 6 rows x 7 days

                Rectangle {
                    required property int index

                    property int dayOffset: index - calendarWidget.getFirstDayOfMonth(viewDate.getFullYear(), viewDate.getMonth())
                    property int dayNumber: dayOffset + 1
                    property bool isCurrentMonth: dayNumber >= 1 && dayNumber <= calendarWidget.getDaysInMonth(viewDate.getFullYear(), viewDate.getMonth())
                    property bool isToday: isCurrentMonth &&
                        dayNumber === WeeklyJobs.now.getDate() &&
                        viewDate.getMonth() === WeeklyJobs.now.getMonth() &&
                        viewDate.getFullYear() === WeeklyJobs.now.getFullYear()
                    property bool isSelected: isCurrentMonth &&
                        dayNumber === selectedDate.getDate() &&
                        viewDate.getMonth() === selectedDate.getMonth() &&
                        viewDate.getFullYear() === selectedDate.getFullYear()
                    // Weekly-job marker: day has jobs scheduled
                    property bool hasWeeklyJobs: isCurrentMonth && WeeklyJobs.jobsForDay(new Date(viewDate.getFullYear(), viewDate.getMonth(), dayNumber).getDay()).length > 0
                    property int weeklyJobsPending: {
                        if (!isCurrentMonth) return 0
                        var d = new Date(viewDate.getFullYear(), viewDate.getMonth(), dayNumber)
                        var isSameWeek = WeeklyJobs.weekKeyFor(d) === WeeklyJobs.weekKey
                        return WeeklyJobs.jobsForDay(d.getDay()).filter(function(j) { return !j.done || !isSameWeek }).length
                    }
                    property bool hasEvents: isCurrentMonth && calendarWidget.monthEvents[dayNumber] !== undefined

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 28
                    radius: 5
                    color: {
                        if (isSelected) return calendarWidget.colorSecondary
                        if (isToday) return calendarWidget.colorAccent
                        if (dayHover.containsMouse && isCurrentMonth) return Theme.border
                        return isCurrentMonth ? Theme.bg : Theme.surface2
                    }
                    border.width: isSelected || isToday || hasEvents || dayHover.containsMouse ? 1 : 0
                    border.color: isSelected ? calendarWidget.colorAccent : (isToday ? calendarWidget.colorMainLight : calendarWidget.colorAccentDim)
                    opacity: isCurrentMonth ? 1 : 0.35

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 0

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (isCurrentMonth) return dayNumber.toString()
                                let prevMonthDays = calendarWidget.getDaysInMonth(viewDate.getFullYear(), viewDate.getMonth() - 1)
                                if (dayNumber < 1) return String(prevMonthDays + dayNumber)
                                return String(dayNumber - calendarWidget.getDaysInMonth(viewDate.getFullYear(), viewDate.getMonth()))
                            }
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            font.bold: isToday || isSelected
                            color: {
                                if (isSelected) return Theme.onAccentText
                                if (isToday) return Theme.onAccentText
                                return isCurrentMonth ? Theme.accentStrong : Theme.muted2
                            }
                        }

                        // Pending weekly-jobs dot (amber; hollow once all finished)
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 4
                            height: 4
                            radius: 2
                            visible: hasWeeklyJobs
                            color: weeklyJobsPending > 0 ? calendarWidget.colorSecondary : "transparent"
                            border.width: weeklyJobsPending > 0 ? 0 : 1
                            border.color: calendarWidget.colorSecondary
                        }
                    }

                    MouseArea {
                        id: dayHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: isCurrentMonth ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: {
                            if (isCurrentMonth) {
                                calendarWidget.selectDate(dayNumber)
                            }
                        }
                    }
                }
            }
        }

        // Divider + tabs
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: calendarWidget.colorSecondary2
            opacity: 0.3
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            // Tab: today's jobs
            Rectangle {
                Layout.preferredWidth: tabTodayText.implicitWidth + 20
                Layout.preferredHeight: 26
                radius: 4
                color: calendarWidget.bottomTab === 0
                    ? (tabTodayMa.containsMouse ? calendarWidget.colorAccentDim : calendarWidget.colorMainLight)
                    : (tabTodayMa.containsMouse ? Theme.border : "transparent")
                border.width: calendarWidget.bottomTab === 0 ? 0 : 1
                border.color: Theme.border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: tabTodayText
                        text: "\uf0ae"  // fa-list-check
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 11
                        color: Theme.onAccentText
                        visible: calendarWidget.bottomTab === 0
                    }

                    Text {
                        text: {
                            var pending = calendarWidget.todayJobs.filter(function(j) { return !j.done }).length
                            var total = calendarWidget.todayJobs.length
                            return "Jobs " + (total - pending) + "/" + total
                        }
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: calendarWidget.bottomTab === 0 ? Theme.onAccentText : Theme.muted
                    }
                }

                MouseArea {
                    id: tabTodayMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calendarWidget.bottomTab = 0
                        calendarWidget.showEventView = false
                    }
                }
            }

            // Tab: events for selected date
            Rectangle {
                Layout.preferredWidth: tabEventsText.implicitWidth + 20
                Layout.preferredHeight: 26
                radius: 4
                color: calendarWidget.bottomTab === 1
                    ? (tabEventsMa.containsMouse ? calendarWidget.colorAccentDim : calendarWidget.colorMainLight)
                    : (tabEventsMa.containsMouse ? Theme.border : "transparent")
                border.width: calendarWidget.bottomTab === 1 ? 0 : 1
                border.color: Theme.border

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        id: tabEventsText
                        text: "\uf073"  // fa-calendar
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 11
                        color: Theme.onAccentText
                        visible: calendarWidget.bottomTab === 1
                    }

                    Text {
                        text: calendarWidget.showEventView
                            ? ("Events " + calendarWidget.formatDate(calendarWidget.selectedDate))
                            : "Events"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: calendarWidget.bottomTab === 1 ? Theme.onAccentText : Theme.muted
                    }
                }

                MouseArea {
                    id: tabEventsMa
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        calendarWidget.bottomTab = 1
                        if (!calendarWidget.showEventView) {
                            calendarWidget.selectedDate = new Date(WeeklyJobs.now)
                            calendarWidget.loadEventsForDate()
                            calendarWidget.showEventView = true
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.alignment: Qt.AlignVCenter
                text: "week " + WeeklyJobs.weekKey
                font.pixelSize: 10
                font.family: "JetBrains Mono"
                color: Theme.muted2
            }
        }

        // ================= Today's jobs list =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4
            visible: calendarWidget.bottomTab === 0

            // Empty state
            Text {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: "No jobs today 🌸"
                font.pixelSize: 12
                font.family: "JetBrains Mono"
                color: Theme.muted
                opacity: 0.5
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: calendarWidget.todayJobs.length === 0
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: calendarWidget.todayJobs.length > 0
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: calendarWidget.todayJobs

                        Rectangle {
                            required property var modelData
                            required property int index

                            readonly property bool isDone: modelData.done

                            Layout.fillWidth: true
                            Layout.preferredHeight: jobRow.implicitHeight + 10
                            radius: 4
                            color: jobItemHover.containsMouse ? calendarWidget.colorMainLight : Theme.surface
                            border.width: 1
                            border.color: modelData.done ? calendarWidget.colorAccentDim : calendarWidget.colorSecondary2
                            opacity: modelData.done ? 0.55 : 1

                            RowLayout {
                                id: jobRow
                                anchors {
                                    fill: parent
                                    leftMargin: 6
                                    rightMargin: 6
                                    topMargin: 5
                                    bottomMargin: 5
                                }
                                spacing: 8

                                // Completion checkbox (click = finished, stops notifications)
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: Theme.bg
                                    border.width: 1
                                    border.color: isDone ? calendarWidget.colorAccent : calendarWidget.colorSecondary2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00c"  // fa-check
                                        font.family: "Font Awesome 6 Free Solid"
                                        font.pixelSize: 10
                                        color: calendarWidget.colorAccent
                                        visible: isDone
                                    }
                                }

                                // Job info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.strikeout: isDone
                                        font.bold: !isDone
                                        color: isDone ? Theme.muted : Theme.accentStrong
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.detail + (modelData.url ? "  \uf08e" : "")
                                        font.pixelSize: 10
                                        font.family: "JetBrains Mono"
                                        color: Theme.muted
                                        elide: Text.ElideRight
                                        visible: modelData.detail.length > 0 || modelData.url.length > 0
                                    }
                                }

                                // Finished label
                                Text {
                                    text: isDone ? "done" : "pending"
                                    font.pixelSize: 9
                                    font.family: "JetBrains Mono"
                                    color: isDone ? calendarWidget.colorAccent : Theme.muted2
                                }
                            }

                            MouseArea {
                                id: jobItemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                // Left click toggles finished state; middle click opens URL if present
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton && modelData.url.length > 0) {
                                        urlProcess.command = ["xdg-open", modelData.url]
                                        urlProcess.running = true
                                    } else {
                                        WeeklyJobs.toggleJob(modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Hint row
            Text {
                Layout.fillWidth: true
                text: "click a job to mark finished · \uf013 to edit the week"
                font.pixelSize: 9
                font.family: "JetBrains Mono"
                color: Theme.muted2
                horizontalAlignment: Text.AlignHCenter
                visible: calendarWidget.todayJobs.length > 0
            }
        }

        Process {
            id: urlProcess
            command: ["true"]
        }

        // ================= Khal events view (per selected date) =================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8
            visible: calendarWidget.bottomTab === 1 && calendarWidget.showEventView

            // Selected date header with back button
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 26
                    height: 26
                    radius: 4
                    color: backBtn.containsMouse ? calendarWidget.colorAccentDim : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf060"  // fa-arrow-left
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 11
                        color: calendarWidget.colorAccent
                    }

                    MouseArea {
                        id: backBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendarWidget.showEventView = false
                    }
                }

                Text {
                    text: "\uf073"  // fa-calendar
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 13
                    color: Theme.secondaryStrong
                }

                Text {
                    Layout.fillWidth: true
                    text: calendarWidget.formatDate(selectedDate)
                    font.pixelSize: 13
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.secondaryStrong
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: statusText.implicitHeight + 10
                radius: 6
                color: calendarWidget.backendReady ? Theme.surface2 : Theme.secondary
                border.width: 1
                border.color: calendarWidget.backendReady ? Theme.border : Theme.secondaryStrong
                visible: calendarWidget.statusMessage.length > 0

                Text {
                    id: statusText
                    anchors.fill: parent
                    anchors.margins: 6
                    text: calendarWidget.statusMessage
                    font.pixelSize: 11
                    font.family: "JetBrains Mono"
                    color: calendarWidget.backendReady ? Theme.muted : "#000000"
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                }
            }

            // Add event input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 6
                color: calendarWidget.colorMain
                border.width: 1
                border.color: eventInput.activeFocus ? calendarWidget.colorAccent : calendarWidget.colorSecondary2

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 8
                        rightMargin: 8
                    }
                    spacing: 6

                    Text {
                        text: "\uf067"  // fa-plus
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 12
                        color: calendarWidget.colorAccent
                    }

                    TextInput {
                        id: eventInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        clip: true
                        activeFocusOnPress: true
                        selectByMouse: true

                        property string placeholderText: "Add event..."

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            text: eventInput.placeholderText
                            font: eventInput.font
                            color: Theme.muted
                            opacity: 0.5
                            visible: !eventInput.text && !eventInput.activeFocus
                        }

                        onAccepted: {
                            if (text.trim() !== "") {
                                calendarWidget.addEvent(text.trim(), recurrentCheck.checked, recurrenceInput.text)
                                text = ""
                            }
                        }
                    }

                    // Submit button
                    Rectangle {
                        width: 24
                        height: 24
                        radius: 4
                        color: addEventBtn.containsMouse ? calendarWidget.colorAccentDim : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: "\uf054"  // fa-chevron-right
                            font.family: "Font Awesome 6 Free Solid"
                            font.pixelSize: 10
                            color: calendarWidget.colorAccent
                        }

                        MouseArea {
                            id: addEventBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (eventInput.text.trim() !== "") {
                                    calendarWidget.addEvent(eventInput.text.trim(), recurrentCheck.checked, recurrenceInput.text)
                                    eventInput.text = ""
                                }
                            }
                        }
                    }
                }
            }

            // Recurrence options
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                CheckBox {
                    id: recurrentCheck

                    indicator: Rectangle {
                        width: 16
                        height: 16
                        radius: 3
                        color: calendarWidget.colorMain
                        border.width: 1
                        border.color: recurrentCheck.checked ? calendarWidget.colorAccent : calendarWidget.colorSecondary2

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"  // fa-check
                            font.family: "Font Awesome 6 Free Solid"
                            font.pixelSize: 10
                            color: calendarWidget.colorAccent
                            visible: recurrentCheck.checked
                        }
                    }

                    contentItem: Text {
                        leftPadding: 22
                        text: "Repeat"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.muted
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    radius: 4
                    color: calendarWidget.colorMain
                    border.width: 1
                    border.color: calendarWidget.colorSecondary2
                    visible: recurrentCheck.checked

                    TextInput {
                        id: recurrenceInput
                        anchors {
                            fill: parent
                            leftMargin: 6
                            rightMargin: 6
                        }
                        verticalAlignment: TextInput.AlignVCenter
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        text: "weekly"
                        activeFocusOnPress: true
                        selectByMouse: true
                    }
                }
            }

            // Events list
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                ColumnLayout {
                    width: parent.width
                    spacing: 4

                    // Empty state
                    Text {
                        Layout.fillWidth: true
                        text: "No events for this day 🌸"
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        color: Theme.muted
                        opacity: 0.5
                        horizontalAlignment: Text.AlignHCenter
                        visible: calendarWidget.events.length === 0
                    }

                    // Events
                    Repeater {
                        model: calendarWidget.events

                        Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: eventRow.implicitHeight + 14
                            radius: 4
                            color: eventItemHover.containsMouse ? calendarWidget.colorMainLight : calendarWidget.colorMain
                            border.width: 1
                            border.color: modelData.completed ? calendarWidget.colorAccentDim : calendarWidget.colorSecondary2

                            RowLayout {
                                id: eventRow
                                anchors {
                                    fill: parent
                                    margins: 7
                                }
                                spacing: 8

                                // Completion checkbox
                                Rectangle {
                                    width: 20
                                    height: 20
                                    radius: 4
                                    color: calendarWidget.colorMain
                                    border.width: 1
                                    border.color: modelData.completed ? calendarWidget.colorAccent : calendarWidget.colorSecondary2

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf00c"  // fa-check
                                        font.family: "Font Awesome 6 Free Solid"
                                        font.pixelSize: 10
                                        color: calendarWidget.colorAccent
                                        visible: modelData.completed
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let newEvents = calendarWidget.events.slice()
                                            newEvents[index].completed = !newEvents[index].completed
                                            calendarWidget.events = newEvents
                                        }
                                    }
                                }

                                // Event info
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.title
                                        font.pixelSize: 12
                                        font.family: "JetBrains Mono"
                                        font.strikeout: modelData.completed
                                        color: modelData.completed ? Theme.muted : Theme.accentStrong
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.startTime ? (modelData.startTime + (modelData.endTime ? " - " + modelData.endTime : "")) : "All day"
                                        font.pixelSize: 10
                                        font.family: "JetBrains Mono"
                                        color: Theme.muted
                                        visible: modelData.startTime !== ""
                                    }
                                }
                            }

                            MouseArea {
                                id: eventItemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }
}
