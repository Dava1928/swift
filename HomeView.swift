import SwiftUI

struct HomeView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showNewSemester = false

    var semester: AppSemester? { dm.activeSemester }

    var body: some View {
        NavigationView {
            Group {
                if let sem = semester {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {

                            // ── Semester header card ──
                            semesterHeader(sem)

                            // ── At-risk warning ──
                            let atRisk = sem.courses.filter { $0.isAtRisk || $0.isCritical }
                            if !atRisk.isEmpty {
                                warningBanner(atRisk)
                            }

                            // ── Course progress ──
                            if !sem.courses.isEmpty {
                                sectionTitle("Kehadiran per Mata Kuliah")
                                ForEach(sem.courses) { course in
                                    CourseProgressCard(course: course)
                                }
                            } else {
                                emptyCourseHint
                            }

                            // ── Upcoming tasks ──
                            let upcoming = dm.pendingTasks.prefix(5)
                            if !upcoming.isEmpty {
                                sectionTitle("Tugas Mendatang")
                                ForEach(Array(upcoming)) { task in
                                    upcomingTaskRow(task)
                                }
                            }

                            Spacer(minLength: 24)
                        }
                        .padding()
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "tray.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Belum ada semester aktif")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Beranda")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showNewSemester = true } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showNewSemester) {
            NewSemesterSheet(isPresented: $showNewSemester)
        }
    }

    // MARK: Sub-views

    func semesterHeader(_ sem: AppSemester) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.indigo)
                Text(sem.name)
                    .font(.headline)
                    .foregroundColor(.indigo)
                Spacer()
                Text("Aktif")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.indigo.opacity(0.15))
                    .foregroundColor(.indigo)
                    .cornerRadius(8)
            }
            Divider()
            HStack(spacing: 0) {
                statCol("\(sem.courses.count)", "Matkul", .indigo)
                Divider().frame(height: 36)
                statCol(
                    "\(sem.courses.reduce(0) { $0 + $1.attendedCount })",
                    "Total Hadir", .green)
                Divider().frame(height: 36)
                statCol(
                    "\(sem.courses.reduce(0) { $0 + $1.absentCount })",
                    "Total Absen", .red)
                Divider().frame(height: 36)
                statCol(
                    "\(sem.courses.reduce(0) { $0 + $1.tasks.count })",
                    "Tugas", .blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
    }

    func statCol(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    func warningBanner(_ courses: [AppCourse]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Perlu Perhatian!", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.bold())
                .foregroundColor(.orange)

            ForEach(courses) { c in
                HStack(spacing: 10) {
                    Image(systemName: c.isCritical
                          ? "xmark.circle.fill"
                          : "exclamationmark.circle.fill")
                        .foregroundColor(c.isCritical ? .red : .orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(c.name).font(.subheadline.bold())
                        Text(c.isCritical
                             ? "Batas maksimal absen tercapai!"
                             : "Sisa 1 absen lagi — hati-hati!")
                            .font(.caption)
                            .foregroundColor(c.isCritical ? .red : .orange)
                    }
                    Spacer()
                    Text("\(c.absentCount)/3")
                        .font(.caption.bold())
                        .foregroundColor(c.isCritical ? .red : .orange)
                }
                .padding(10)
                .background((c.isCritical ? Color.red : Color.orange).opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.07))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.orange.opacity(0.3), lineWidth: 1))
        .cornerRadius(14)
    }

    var emptyCourseHint: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.indigo)
            Text("Belum ada mata kuliah. Tambahkan di tab Mata Kuliah.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }

    func upcomingTaskRow(_ task: AppTask) -> some View {
        HStack(spacing: 12) {
            Image(systemName: task.status.icon)
                .foregroundColor(task.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(task.courseName) · Pertemuan \(task.meetingNumber)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Text(task.deadlineText)
                .font(.caption.bold())
                .foregroundColor(task.urgencyColor)
        }
        .padding(10)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }

    func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
    }
}

// MARK: - Course Progress Card (shared)

struct CourseProgressCard: View {
    let course: AppCourse

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(course.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Spacer()
                Text("\(course.filledCount)/\(course.totalMeetings)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ProgressView(value: Double(course.filledCount),
                         total: Double(course.totalMeetings))
                .tint(course.statusColor)

            HStack(spacing: 10) {
                statusBadge(course.attendedCount, "Hadir",  .green,   "checkmark.circle.fill")
                statusBadge(course.absentCount,   "Absen",  .red,     "xmark.circle.fill")
                if course.izinCount > 0 {
                    statusBadge(course.izinCount, "Izin", .orange, "exclamationmark.circle.fill")
                }
                if course.sakitCount > 0 {
                    statusBadge(course.sakitCount, "Sakit", .blue, "cross.circle.fill")
                }
                Spacer()
                if course.isCritical {
                    Label("BATAS!", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.red)
                } else if course.isAtRisk {
                    Label("Risiko", systemImage: "exclamationmark.circle.fill")
                        .font(.caption.bold())
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(
            course.isCritical
                ? Color.red.opacity(0.06)
                : (course.isAtRisk ? Color.orange.opacity(0.06) : Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((course.isAtRisk || course.isCritical)
                        ? course.statusColor.opacity(0.4)
                        : Color.clear,
                        lineWidth: 1.5)
        )
        .cornerRadius(12)
    }

    func statusBadge(_ count: Int, _ label: String,
                     _ color: Color, _ icon: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon).foregroundColor(color)
            Text("\(count) \(label)").foregroundColor(color)
        }
        .font(.caption)
    }
}
