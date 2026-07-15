import SwiftUI

// MARK: - History Tab

struct HistoryView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showNewSemester = false

    var pastSemesters: [AppSemester] {
        dm.semesters.filter { !$0.isActive }
    }

    var body: some View {
        NavigationView {
            Group {
                if pastSemesters.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 64))
                            .foregroundColor(.indigo.opacity(0.35))
                        Text("Belum Ada Histori")
                            .font(.headline)
                        Text("Riwayat semester sebelumnya\nakan tersimpan di sini secara otomatis.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                } else {
                    List {
                        ForEach(pastSemesters) { sem in
                            NavigationLink {
                                SemesterArchiveView(semester: sem)
                            } label: {
                                PastSemesterRow(semester: sem)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Histori Semester")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewSemester = true
                    } label: {
                        Label("Semester Baru", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
        .sheet(isPresented: $showNewSemester) {
            NewSemesterSheet(isPresented: $showNewSemester)
        }
    }
}

// MARK: - Past Semester Row

struct PastSemesterRow: View {
    let semester: AppSemester

    var totalAttended: Int { semester.courses.reduce(0) { $0 + $1.attendedCount } }
    var totalAbsent  : Int { semester.courses.reduce(0) { $0 + $1.absentCount  } }
    var totalTasks   : Int { semester.courses.reduce(0) { $0 + $1.tasks.count   } }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(semester.name)
                .font(.headline)
            Text(semester.startDate, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 14) {
                Label("\(semester.courses.count) matkul", systemImage: "book.fill")
                Label("\(totalAttended) hadir", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Label("\(totalAbsent) absen", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Semester Archive Detail

struct SemesterArchiveView: View {
    let semester: AppSemester

    var totalAttended: Int { semester.courses.reduce(0) { $0 + $1.attendedCount } }
    var totalAbsent  : Int { semester.courses.reduce(0) { $0 + $1.absentCount  } }
    var totalIzin    : Int { semester.courses.reduce(0) { $0 + $1.izinCount     } }
    var totalSakit   : Int { semester.courses.reduce(0) { $0 + $1.sakitCount    } }
    var totalTasks   : Int { semester.courses.reduce(0) { $0 + $1.tasks.count   } }
    var doneTasks    : Int { semester.courses.reduce(0) { $0 + $1.tasks.filter { $0.status == .selesai }.count } }

    var body: some View {
        List {
            // Summary
            Section(header: Text("Ringkasan Semester")) {
                summaryRow("Mulai", text: semester.startDate.formatted(date: .long, time: .omitted))
                summaryRow("Total Mata Kuliah", text: "\(semester.courses.count)")
                summaryRow("Total Hadir",  text: "\(totalAttended)",  color: .green)
                summaryRow("Total Absen",  text: "\(totalAbsent)",    color: .red)
                summaryRow("Total Izin",   text: "\(totalIzin)",      color: .orange)
                summaryRow("Total Sakit",  text: "\(totalSakit)",     color: .blue)
                summaryRow("Tugas Selesai",
                           text: "\(doneTasks)/\(totalTasks)",
                           color: doneTasks == totalTasks && totalTasks > 0 ? .green : .primary)
            }

            // Per course
            Section(header: Text("Detail per Mata Kuliah")) {
                ForEach(semester.courses) { course in
                    archiveCourseRow(course)
                }
            }
        }
        .navigationTitle(semester.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    func summaryRow(_ label: String, text: String, color: Color = .primary) -> some View {
        HStack {
            Text(label).foregroundColor(.secondary)
            Spacer()
            Text(text).bold().foregroundColor(color)
        }
    }

    func archiveCourseRow(_ course: AppCourse) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(course.name).font(.subheadline.bold())
                Spacer()
                Text("\(course.sks) SKS")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.indigo.opacity(0.12))
                    .foregroundColor(.indigo)
                    .cornerRadius(6)
            }
            Text(course.lecturerName)
                .font(.caption).foregroundColor(.secondary)

            HStack(spacing: 12) {
                Label("\(course.attendedCount)", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Label("\(course.absentCount)",  systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
                Label("\(course.izinCount)",    systemImage: "exclamationmark.circle.fill")
                    .foregroundColor(.orange)
                Label("\(course.sakitCount)",   systemImage: "cross.circle.fill")
                    .foregroundColor(.blue)
            }
            .font(.caption)

            ProgressView(value: course.attendanceRate)
                .tint(course.statusColor)

            if course.isCritical {
                Label("Melebihi batas absen!", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption.bold()).foregroundColor(.red)
            }

            if !course.tasks.isEmpty {
                let done = course.tasks.filter { $0.status == .selesai }.count
                Label("\(done)/\(course.tasks.count) tugas selesai",
                      systemImage: "checklist")
                    .font(.caption)
                    .foregroundColor(done == course.tasks.count ? .green : .secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
