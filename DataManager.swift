import Foundation
import SwiftUI
import UserNotifications

class DataManager: ObservableObject {

    // MARK: - Warning Model
    struct AbsenceWarningData: Identifiable {
        let id         = UUID()
        let title      : String
        let message    : String
        let isCritical : Bool
    }

    // MARK: - Published
    @Published var semesters       : [AppSemester]       = []
    @Published var absenceWarning  : AbsenceWarningData? = nil

    // MARK: - Private
    private let saveKey : String = "AbsensiKuliah_v1"
    private let docsDir : URL

    // MARK: - Computed
    var activeSemester    : AppSemester? { semesters.first { $0.isActive } }
    var activeSemesterIdx : Int?         { semesters.firstIndex { $0.isActive } }

    var allActiveTasks: [AppTask] {
        (activeSemester?.courses ?? [])
            .flatMap { $0.tasks }
            .sorted { $0.deadline < $1.deadline }
    }

    var pendingTasks: [AppTask] {
        allActiveTasks.filter { $0.status != .selesai }
    }

    // MARK: - Init
    init() {
        docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        load()
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]) { _, _ in }
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(semesters) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func load() {
        guard
            let data    = UserDefaults.standard.data(forKey: saveKey),
            let decoded = try? JSONDecoder().decode([AppSemester].self, from: data)
        else { return }
        semesters = decoded
    }

    // MARK: - Semester
    func createSemester(name: String) {
        for i in semesters.indices { semesters[i].isActive = false }
        semesters.insert(AppSemester(name: name, startDate: Date(), isActive: true), at: 0)
        save()
    }

    // MARK: - Course
    func addCourse(_ course: AppCourse) {
        guard let si = activeSemesterIdx else { return }
        var c = course
        c.setupMeetings()
        semesters[si].courses.append(c)
        save()
    }

    func updateCourse(_ course: AppCourse, si: Int, ci: Int) {
        let prev = semesters[si].courses[ci]
        semesters[si].courses[ci] = course
        if course.sks == prev.sks {
            semesters[si].courses[ci].meetings = prev.meetings
            semesters[si].courses[ci].tasks    = prev.tasks
        } else {
            semesters[si].courses[ci].meetings = []
            semesters[si].courses[ci].setupMeetings()
            semesters[si].courses[ci].tasks = prev.tasks
        }
        save()
    }

    func deleteCourse(si: Int, ci: Int) {
        semesters[si].courses.remove(at: ci)
        save()
    }

    // MARK: - Meeting
    func updateMeeting(_ meeting: AppMeeting, si: Int, ci: Int, mi: Int) {
        let prevAbsent = semesters[si].courses[ci].absentCount
        semesters[si].courses[ci].meetings[mi] = meeting
        save()
        let newAbsent  = semesters[si].courses[ci].absentCount
        let courseName = semesters[si].courses[ci].name
        if newAbsent > prevAbsent {
            DispatchQueue.main.async {
                self.triggerAbsenceAlert(name: courseName, count: newAbsent)
            }
        }
    }

    private func triggerAbsenceAlert(name: String, count: Int) {
        if count == 2 {
            sendNotif(
                title: "⚠️ Peringatan Ketidakhadiran",
                body:  "Kamu sudah 2x tidak hadir di \(name). Jangan bolos lagi!")
            absenceWarning = AbsenceWarningData(
                title: "⚠️ Peringatan Kehadiran",
                message: """
                Kamu sudah 2x tidak hadir di mata kuliah \(name).

                Satu ketidakhadiran lagi dan kamu berisiko TIDAK DAPAT mengikuti ujian semester ini!

                ❌ Jangan bolos lagi!
                """,
                isCritical: false)
        } else if count >= 3 {
            sendNotif(
                title: "🚨 Batas Maksimal Tercapai!",
                body:  "3x tidak hadir di \(name). Kamu berisiko tidak bisa ujian!")
            absenceWarning = AbsenceWarningData(
                title: "🚨 Batas Maksimal!",
                message: """
                Kamu sudah 3x tidak hadir di mata kuliah \(name).

                Kamu telah mencapai BATAS MAKSIMAL ketidakhadiran!

                ⛔ Segera konsultasikan dengan dosen atau bagian akademik.
                """,
                isCritical: true)
        }
    }

    // MARK: - Task
    func addTask(_ task: AppTask, si: Int, ci: Int) {
        semesters[si].courses[ci].tasks.append(task)
        if let mi = semesters[si].courses[ci].meetings
            .firstIndex(where: { $0.number == task.meetingNumber }) {
            semesters[si].courses[ci].meetings[mi].hasTask = true
        }
        save()
        scheduleTaskNotifs(task)
    }

    func updateTask(_ task: AppTask, si: Int, ci: Int, ti: Int) {
        semesters[si].courses[ci].tasks[ti] = task
        save()
    }

    func deleteTask(si: Int, ci: Int, ti: Int) {
        let tid = semesters[si].courses[ci].tasks[ti].id.uuidString
        semesters[si].courses[ci].tasks.remove(at: ti)
        save()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["task_\(tid)_3d", "task_\(tid)_1d"])
    }

    func updateTaskStatus(taskId: UUID, newStatus: TaskStatus) {
        for si in semesters.indices {
            for ci in semesters[si].courses.indices {
                if let ti = semesters[si].courses[ci].tasks
                    .firstIndex(where: { $0.id == taskId }) {
                    semesters[si].courses[ci].tasks[ti].status = newStatus
                    save()
                    return
                }
            }
        }
    }

    // MARK: - Photos
    func savePhoto(_ image: UIImage, prefix: String) -> String? {
        let fn = "\(prefix)_\(UUID().uuidString).jpg"
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        try? data.write(to: docsDir.appendingPathComponent(fn))
        return fn
    }

    func loadPhoto(_ filename: String?) -> UIImage? {
        guard let fn = filename else { return nil }
        return UIImage(contentsOfFile: docsDir.appendingPathComponent(fn).path)
    }

    func deletePhoto(_ filename: String?) {
        guard let fn = filename else { return }
        try? FileManager.default.removeItem(at: docsDir.appendingPathComponent(fn))
    }

    // MARK: - Notifications
    private func sendNotif(title: String, body: String) {
        let c       = UNMutableNotificationContent()
        c.title     = title
        c.body      = body
        c.sound     = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let req     = UNNotificationRequest(
            identifier: UUID().uuidString, content: c, trigger: trigger)
        UNUserNotificationCenter.current().add(req)
    }

    private func scheduleTaskNotifs(_ task: AppTask) {
        for days in [3, 1] {
            guard
                let date = Calendar.current.date(
                    byAdding: .day, value: -days, to: task.deadline),
                date > Date()
            else { continue }

            let c       = UNMutableNotificationContent()
            c.title     = "📝 Deadline Tugas H-\(days)"
            c.body      = "\(task.title) (\(task.courseName)) — \(days) hari lagi!"
            c.sound     = .default

            var comps   = Calendar.current.dateComponents([.year, .month, .day], from: date)
            comps.hour  = 8
            comps.minute = 0

            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let req     = UNNotificationRequest(
                identifier: "task_\(task.id)_\(days)d", content: c, trigger: trigger)
            UNUserNotificationCenter.current().add(req)
        }
    }
}
