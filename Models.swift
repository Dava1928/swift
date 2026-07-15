import Foundation
import SwiftUI

// MARK: - Enums

enum AttendanceStatus: String, Codable, CaseIterable {
    case belumDiisi  = "Belum Diisi"
    case hadir       = "Hadir"
    case tidakHadir  = "Tidak Hadir"
    case izin        = "Izin"
    case sakit       = "Sakit"

    var color: Color {
        switch self {
        case .belumDiisi:  return Color(.systemGray)
        case .hadir:       return .green
        case .tidakHadir:  return .red
        case .izin:        return .orange
        case .sakit:       return .blue
        }
    }

    var icon: String {
        switch self {
        case .belumDiisi:  return "circle"
        case .hadir:       return "checkmark.circle.fill"
        case .tidakHadir:  return "xmark.circle.fill"
        case .izin:        return "exclamationmark.circle.fill"
        case .sakit:       return "cross.circle.fill"
        }
    }
}

enum TaskStatus: String, Codable, CaseIterable {
    case belumDikerjakan  = "Belum"
    case sedangDikerjakan = "Dikerjakan"
    case selesai          = "Selesai"

    var color: Color {
        switch self {
        case .belumDikerjakan:  return .red
        case .sedangDikerjakan: return .orange
        case .selesai:          return .green
        }
    }

    var icon: String {
        switch self {
        case .belumDikerjakan:  return "circle"
        case .sedangDikerjakan: return "clock.fill"
        case .selesai:          return "checkmark.circle.fill"
        }
    }
}

// MARK: - Data Models

struct AppSemester: Identifiable, Codable {
    var id        = UUID()
    var name      : String
    var startDate : Date
    var isActive  : Bool        = true
    var courses   : [AppCourse] = []
}

struct AppCourse: Identifiable, Codable {
    var id                    = UUID()
    var name                  : String
    var sks                   : Int        // 2 or 3
    var lecturerName          : String
    var lecturerPhone         : String
    var lecturerPhotoFilename : String?
    var classTime             : String     // e.g. "08:00"
    var dayOfWeek             : String     // e.g. "Senin"
    var meetings              : [AppMeeting] = []
    var tasks                 : [AppTask]    = []

    var totalMeetings  : Int { sks == 2 ? 14 : 21 }
    var attendedCount  : Int { meetings.filter { $0.status == .hadir }.count }
    var absentCount    : Int { meetings.filter { $0.status == .tidakHadir }.count }
    var izinCount      : Int { meetings.filter { $0.status == .izin }.count }
    var sakitCount     : Int { meetings.filter { $0.status == .sakit }.count }
    var filledCount    : Int { meetings.filter { $0.status != .belumDiisi }.count }
    var remainingMeetings : Int { totalMeetings - filledCount }

    var attendanceRate : Double {
        guard filledCount > 0 else { return 1.0 }
        return Double(attendedCount + izinCount + sakitCount) / Double(filledCount)
    }

    var isAtRisk   : Bool  { absentCount == 2 }
    var isCritical : Bool  { absentCount >= 3 }

    var statusColor: Color {
        isCritical ? .red : (isAtRisk ? .orange : .green)
    }

    mutating func setupMeetings() {
        guard meetings.isEmpty else { return }
        meetings = (1...totalMeetings).map { AppMeeting(number: $0) }
    }
}

struct AppMeeting: Identifiable, Codable {
    var id                  = UUID()
    var number              : Int
    var date                : Date?
    var status              : AttendanceStatus = .belumDiisi
    var notes               : String           = ""
    var proofPhotoFilename  : String?
    var hasTask             : Bool             = false
}

struct AppTask: Identifiable, Codable {
    var id              = UUID()
    var courseId        : UUID
    var courseName      : String
    var meetingNumber   : Int
    var title           : String
    var taskDescription : String
    var deadline        : Date
    var status          : TaskStatus = .belumDikerjakan
    var createdAt       : Date       = Date()

    var isOverdue: Bool {
        status != .selesai && deadline < Date()
    }

    var daysUntilDeadline: Int {
        let cal = Calendar.current
        return cal.dateComponents(
            [.day],
            from: cal.startOfDay(for: Date()),
            to:   cal.startOfDay(for: deadline)
        ).day ?? 0
    }

    var deadlineText: String {
        if status == .selesai { return "Selesai ✓" }
        let d = daysUntilDeadline
        if d < 0  { return "Terlambat \(abs(d)) hari" }
        if d == 0 { return "Hari ini!" }
        if d == 1 { return "Besok!" }
        return "H-\(d)"
    }

    var urgencyColor: Color {
        if status == .selesai { return .green }
        let d = daysUntilDeadline
        if d < 0  { return .red }
        if d <= 1 { return .red }
        if d <= 3 { return .orange }
        return .blue
    }
}
