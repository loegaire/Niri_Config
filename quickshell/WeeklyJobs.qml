// WeeklyJobs.qml
// Singleton: weekly-recurring job store + notification engine.
//
// - Jobs are hardwired by default (seeded on first run) and persisted as JSON
//   in ~/.local/state/quickshell/weekly-jobs.json so they survive reloads.
// - Every job belongs to a weekday (0=Sun .. 6=Sat).
// - Completion state ("done") resets automatically when the ISO week changes,
//   so the same job keeps prompting every week.
// - A 10-minute timer fires notifications for every pending job of the
//   current weekday. A job stops notifying once it is marked finished
//   (click on the calendar widget or `qs ipc call jobs finish <id>`).
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: store

    // ------------------------------------------------------------------
    // Constants
    // ------------------------------------------------------------------
    readonly property var dayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    readonly property var dayNamesLong: ["Sunday", "Monday", "Tuesday", "Wednesday",
                                         "Thursday", "Friday", "Saturday"]
    readonly property string dataPath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state")
                                       + "/quickshell/weekly-jobs.json"
    readonly property int notifyIntervalMs: 10 * 60 * 1000  // 10 minutes
    readonly property int maxJobsPerDay: 64

    // ------------------------------------------------------------------
    // Hardwired defaults (seeded when no file exists)
    // ------------------------------------------------------------------
    readonly property var defaultJobs: [
        // Friday = 5
        { id: "sun-pttk", day: 5, title: "PTTK Hệ Thống (IT3120 - 172888)", detail: "Check Teams for homework" },
        { id: "sun-pttk-project", day: 5, title: "PTTK Hệ Thống (IT3120)", detail: "Project + weekly report" },
        { id: "sun-hpt", day: 5, title: "Hệ Phân Tán (IT4611 - 172923)", detail: "Check Teams for homework" },
        { id: "sun-hpt-project", day: 5, title: "Hệ Phân Tán (IT4611)", detail: "Project + weekly report" },
        { id: "sun-hpt-lms", day: 5, title: "Hệ Phân Tán (IT4611)", detail: "Check blearning (lms) every week", url: "https://lms.hust.edu.vn/my/courses.php" },
        // Sunday = 0
        { id: "tue-web", day: 0, title: "Công nghệ web và dịch vụ trực tuyến (IT4409 - 172920)", detail: "Check teams for homework" },
        { id: "tue-web-project", day: 0, title: "Công nghệ web (IT4409)", detail: "Project work + weekly report" },
        // Monday = 1
        { id: "wed-mobile", day: 1, title: "Phát triển ứng dụng cho thiết bị di động (IT4785 - 172925)", detail: "Check teams for homework" },
        { id: "wed-mobile-project", day: 1, title: "Phát triển ứng dụng di động (IT4785)", detail: "Project work + weekly report" },
        { id: "wed-pp", day: 1, title: "Phương pháp tính (MI2010 - 173766)", detail: "Sohoa quizzes", url: "https://fami.hust.edu.vn/sohoa/phong-hoc" },
        // Wednesday = 3
        { id: "fri-qtdc", day: 3, title: "Quản trị học đại cương (EM1010 - 175030)", detail: "Check blearning (lms) every week", url: "https://lms.hust.edu.vn/my/courses.php" },
        { id: "fri-nmn", day: 3, title: "Nhập môn công nghệ phần mềm (IT3180 - 172881)", detail: "Check teams for homework" },
        { id: "fri-nmn-lms", day: 3, title: "Nhập môn công nghệ phần mềm (IT3180)", detail: "Check blearning (lms) every week", url: "https://lms.hust.edu.vn/my/courses.php" }
    ]

    // ------------------------------------------------------------------
    // Runtime state
    // ------------------------------------------------------------------
    property var jobs: []          // [{id, day, title, detail, url, done}]
    property string weekKey: ""    // ISO week the `done` flags belong to
    property bool loaded: false
    property date now: new Date()
    property string lastToast: ""

    // ------------------------------------------------------------------
    // Helpers
    // ------------------------------------------------------------------
    function pad2(n: int): string { return (n < 10 ? "0" : "") + n }

    // ISO-8601 week key, e.g. "2026-W37" (matches `date +%G-W%V`).
    function weekKeyFor(d: date): string {
        var t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()))
        var day = t.getUTCDay() || 7          // Mon=1..Sun=7
        t.setUTCDate(t.getUTCDate() + 4 - day)   // nearest Thursday
        var year = t.getUTCFullYear()
        var jan1 = new Date(Date.UTC(year, 0, 1))
        var week = Math.ceil(((t - jan1) / 86400000 + 1) / 7)
        return year + "-W" + pad2(week)
    }

    function dayOfWeek(d: date): int { return d.getDay() }

    function jobsForDay(day: int): var {
        return jobs.filter(function(j) { return j.day === day })
    }

    function pendingToday(): var {
        var day = dayOfWeek(now)
        return jobs.filter(function(j) { return j.day === day && !j.done })
    }

    function jobById(id: string): var {
        for (var i = 0; i < jobs.length; i++) {
            if (jobs[i].id === id) return jobs[i]
        }
        return null
    }

    function nextId(): string {
        var i = 1
        while (jobById("job-" + i) !== null) i++
        return "job-" + i
    }

    // Deep-copy helper (spread syntax is not supported by the QML JS parser).
    function copyJob(j: var): var {
        return {
            id: j.id,
            day: j.day,
            title: j.title,
            detail: typeof j.detail === "string" ? j.detail : "",
            url: typeof j.url === "string" ? j.url : "",
            done: j.done === true
        }
    }

    function seedJobs(): var {
        return defaultJobs.map(function(j) { return copyJob(j) })
    }

    function isUrl(s: string): bool {
        return /^https?:\/\/\S+$/.test(s)
    }

    // ------------------------------------------------------------------
    // Persistence (FileView as plain text JSON; atomic writes)
    // ------------------------------------------------------------------
    function serialize(): string {
        return JSON.stringify({
            schemaVersion: 1,
            weekKey: weekKey,
            jobs: jobs
        }, null, 2)
    }

    function save() {
        file.setText(serialize())
    }

    function applyDiskState(text: string): void {
        try {
            var parsed = JSON.parse(text)
            if (!parsed || !Array.isArray(parsed.jobs)) throw new Error("bad schema")
            var loadedJobs = parsed.jobs.filter(function(j) { return j && typeof j.id === "string"
                                                    && j.day >= 0 && j.day <= 6
                                                    && typeof j.title === "string" && j.title.length > 0 })
            if (loadedJobs.length === 0 && parsed.jobs.length > 0) throw new Error("no valid jobs")
            jobs = loadedJobs.map(function(j) { return {
                id: j.id,
                day: j.day,
                title: j.title,
                detail: typeof j.detail === "string" ? j.detail : "",
                url: typeof j.url === "string" ? j.url : "",
                done: j.done === true
            }})
            weekKey = typeof parsed.weekKey === "string" ? parsed.weekKey : weekKeyFor(new Date())
        } catch (e) {
            console.warn("[WeeklyJobs] could not parse " + dataPath + " (" + e + "), using defaults")
            jobs = seedJobs()
            weekKey = weekKeyFor(new Date())
        }
        loaded = true
        resetIfNewWeek()
        // Keep file in sync with whatever we ended up with (also creates it on first run).
        var want = serialize()
        if (text !== want) file.setText(want)
    }

    FileView {
        id: file
        path: store.dataPath
        atomicWrites: true
        watchChanges: false
        printErrors: true
        preload: true

        onLoaded: applyDiskState(text())
        onLoadFailed: {
            // First run: file doesn't exist yet -> seed with hardwired defaults.
            console.log("[WeeklyJobs] no state file, seeding defaults")
            store.jobs = store.seedJobs()
            store.weekKey = store.weekKeyFor(new Date())
            store.loaded = true
            file.setText(store.serialize())
        }
        onSaved: store.statePersisted()
        onSaveFailed: err => console.warn("[WeeklyJobs] save failed: " + err)
    }

    signal statePersisted()

    // ------------------------------------------------------------------
    // Weekly reset
    // ------------------------------------------------------------------
    // Called on load, at midnight, and before every notify sweep.
    function resetIfNewWeek(): void {
        var key = weekKeyFor(now)
        if (weekKey === "" || weekKey !== key) {
            var changed = false
            var fresh = jobs.map(function(j) {
                if (j.done) changed = true
                var c = copyJob(j)
                c.done = false
                return c
            })
            if (changed || weekKey === "") {
                jobs = fresh
                weekKey = key
                if (loaded) save()
                console.log("[WeeklyJobs] new week " + key + " - completion state reset")
            } else {
                weekKey = key
                if (loaded) save()
            }
        }
    }

    // ------------------------------------------------------------------
    // Mutations (all persist immediately)
    // ------------------------------------------------------------------
    // Mutations reassign a fresh array (new reference) so QML bindings
    // (Repeater/ListElement models watching `jobs`) re-render reliably.
    function finishJob(id: string): void {
        var idx = jobs.findIndex(function(j) { return j.id === id })
        if (idx === -1 || jobs[idx].done) return
        var copy = jobs.slice()
        var j = copyJob(copy[idx])
        j.done = true
        copy[idx] = j
        jobs = copy
        save()
        // If that was the last pending job of today, celebrate + clear reminder.
        if (loaded && pendingToday().length === 0) sendAllDone()
    }

    function unfinishJob(id: string): void {
        var idx = jobs.findIndex(function(j) { return j.id === id })
        if (idx === -1 || !jobs[idx].done) return
        var copy = jobs.slice()
        var j = copyJob(copy[idx])
        j.done = false
        copy[idx] = j
        jobs = copy
        save()
    }

    function toggleJob(id: string): void {
        var j = jobById(id)
        if (!j) return
        if (j.done) unfinishJob(id)
        else finishJob(id)
    }

    function addJob(day: int, title: string, detail: string, url: string): string {
        title = title.trim()
        if (title.length === 0 || day < 0 || day > 6) return ""
        detail = (detail || "").trim()
        url = (url || "").trim()
        if (url.length > 0 && !isUrl(url)) return ""
        var job = { id: nextId(), day: day, title: title, detail: detail, url: url, done: false }
        jobs = jobs.concat([job])
        save()
        return job.id
    }

    function removeJob(id: string): void {
        var idx = jobs.findIndex(function(j) { return j.id === id })
        if (idx === -1) return
        var copy = jobs.slice()
        copy.splice(idx, 1)
        jobs = copy
        save()
        // Clear the standing reminder if today's last pending job was removed.
        if (loaded && pendingToday().length === 0 && notifyReplaceId !== "") {
            sendAllDone()
        }
    }

    // Replace the entire job list in one shot (used by the edit dialog).
    function replaceAllJobs(newJobs: var): void {
        var cleaned = []
        var seen = {}
        for (var i = 0; i < newJobs.length; i++) {
            var j = newJobs[i]
            if (!j || typeof j.title !== "string" || j.title.trim().length === 0) continue
            if (j.day < 0 || j.day > 6) continue
            var id = (typeof j.id === "string" && j.id.length > 0 && !seen[j.id]) ? j.id : nextId()
            seen[id] = true
            cleaned.push({
                id: id,
                day: j.day,
                title: j.title.trim(),
                detail: typeof j.detail === "string" ? j.detail.trim() : "",
                url: (typeof j.url === "string" && isUrl(j.url.trim())) ? j.url.trim() : "",
                done: j.done === true
            })
        }
        jobs = cleaned
        save()
        // If today's jobs were removed via the editor and none remain pending,
        // clear the standing reminder (same path as finishing the last job).
        if (loaded && pendingToday().length === 0 && notifyReplaceId !== "") {
            sendAllDone()
        }
    }

    function restoreDefaults(): void {
        jobs = seedJobs()
        weekKey = weekKeyFor(now)
        save()
    }

    // ------------------------------------------------------------------
    // Notification engine
    // ------------------------------------------------------------------
    // One standing notification is kept (replaced on each sweep) so mako
    // doesn't accumulate one popup per 10-minute interval.
    property string notifySummary: "Weekly jobs"
    property string notifyReplaceId: ""   // empty = post a fresh notification

    function pendingBody(): string {
        var pending = pendingToday()
        if (pending.length === 0) return ""
        var dayName = dayNamesLong[dayOfWeek(now)]
        var lines = pending.slice(0, 5).map(function(j) { return "- " + j.title + (j.detail ? " - " + j.detail : "") })
        var body = dayName + ": " + pending.length + " job" + (pending.length > 1 ? "s" : "") + " pending\n"
            + lines.join("\n")
        if (pending.length > 5) body += "\n- +" + (pending.length - 5) + " more..."
        body += "\n(click a job in the calendar to mark it finished)"
        return body
    }

    function sendNotification(body: string): void {
        // First sweep prints the notification id (captured) and replaces later ones.
        var cmd = ["notify-send",
                     "-a", "Calendar Jobs",
                     "-i", "x-office-calendar",
                     "-t", "0",
                     "-u", "normal"]
        if (notifyReplaceId !== "") cmd.push("-r", notifyReplaceId)
        cmd.push("-p", notifySummary, body)
        notifyProcess.command = cmd
        notifyProcess.running = true
    }

    function sendAllDone(): void {
        // Replace the standing reminder with a short-lived confirmation.
        var cmd = ["notify-send",
                     "-a", "Calendar Jobs",
                     "-i", "object-select-symbolic",
                     "-t", "4000",
                     "-u", "low"]
        if (notifyReplaceId !== "") cmd.push("-r", notifyReplaceId)
        cmd.push("-p", notifySummary, "All jobs for " + dayNamesLong[dayOfWeek(now)] + " finished")
        notifyProcess.command = cmd
        notifyProcess.running = true
    }

    // Sweep: refresh the reminder for pending jobs of today.
    function sweep(reason: string): void {
        resetIfNewWeek()
        var body = pendingBody()
        if (body.length === 0) return
        sendNotification(body)
        console.log("[WeeklyJobs] sweep(" + reason + "): " + pendingToday().length + " pending")
    }

    Process {
        id: notifyProcess
        command: ["true"]

        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                var id = data.trim()
                if (id.length > 0 && !isNaN(parseInt(id))) store.notifyReplaceId = id
            }
        }
    }

    // Track date changes (midnight rollover + fresh week detection).
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        onDateChanged: {
            store.now = clock.date
            if (store.loaded) store.resetIfNewWeek()
        }
    }

    Component.onCompleted: {
        now = clock.date
    }

    // One-shot: first sweep shortly after load (lets the shell settle).
    Timer {
        id: firstSweepTimer
        interval: 4000
        repeat: false
        running: false
        onTriggered: store.sweep("startup")
    }

    // Repeating: every 10 minutes while the shell runs.
    Timer {
        id: sweepTimer
        interval: store.notifyIntervalMs
        repeat: true
        running: false
        onTriggered: store.sweep("timer")
    }

    onLoadedChanged: {
        if (loaded) {
            firstSweepTimer.start()
            sweepTimer.start()
        }
    }

    // ------------------------------------------------------------------
    // IPC surface (qs ipc call jobs <fn> [args]) - used by tests/CLI.
    // ------------------------------------------------------------------
    IpcHandler {
        target: "jobs"
        function list(): string {
            return store.jobs.map(function(j) { return j.id + " day=" + j.day
                                  + " done=" + j.done
                                  + " title=" + j.title
                                  + (j.detail ? " detail=" + j.detail : "")
                                  + (j.url ? " url=" + j.url : "") }).join("\n")
        }

        function pending(): string {
            return store.pendingToday().map(function(j) { return j.id }).join("\n")
        }

        function finish(id: string): void { store.finishJob(id) }

        function unfinish(id: string): void { store.unfinishJob(id) }

        function toggle(id: string): void { store.toggleJob(id) }

        function add(day: int, title: string): string { return store.addJob(day, title, "", "") }

        function addFull(day: int, title: string, detail: string, url: string): string {
            return store.addJob(day, title, detail, url)
        }

        function remove(id: string): void { store.removeJob(id) }

        function restoreDefaults(): void { store.restoreDefaults() }

        function triggerSweep(): void { store.sweep("ipc") }

        function setWeekKey(key: string): void {
            // Test hook: pretend state belongs to another week, then reset.
            store.weekKey = key
            store.resetIfNewWeek()
        }

        function reload(): void { file.reload() }

        function stateJson(): string { return store.serialize() }
    }
}
