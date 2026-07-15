import SwiftUI

// MARK: - Courses List

struct CoursesView: View {
    @EnvironmentObject var dm: DataManager
    @State private var showAddCourse    = false
    @State private var showNewSemester  = false

    var si      : Int            { dm.activeSemesterIdx ?? 0 }
    var courses : [AppCourse]    { dm.activeSemester?.courses ?? [] }

    var body: some View {
        NavigationView {
            Group {
                if courses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "books.vertical.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.indigo.opacity(0.4))
                        Text("Belum Ada Mata Kuliah")
                            .font(.headline)
                        Text("Tambahkan mata kuliah untuk mulai\nmencatat kehadiran.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button {
                            showAddCourse = true
                        } label: {
                            Label("Tambah Mata Kuliah", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                    }
                    .padding()
                } else {
                    List {
                        ForEach(Array(courses.enumerated()), id: \.element.id) { ci, course in
                            NavigationLink {
                                CourseDetailView(si: si, ci: ci)
                            } label: {
                                CourseListRow(course: course)
                            }
                        }
                        .onDelete { idx in
                            idx.forEach { dm.deleteCourse(si: si, ci: $0) }
                        }
                    }
                }
            }
            .navigationTitle(dm.activeSemester?.name ?? "Mata Kuliah")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { showNewSemester = true } label: {
                        Image(systemName: "calendar.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddCourse = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showAddCourse) {
            AddEditCourseView(si: si, existingCourse: nil, isPresented: $showAddCourse)
        }
        .sheet(isPresented: $showNewSemester) {
            NewSemesterSheet(isPresented: $showNewSemester)
        }
    }
}

// MARK: - Course List Row

struct CourseListRow: View {
    let course: AppCourse

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(course.statusColor.opacity(0.15))
                    .frame(width: 46, height: 46)
                Text("\(course.sks)")
                    .font(.title3.bold())
                    .foregroundColor(course.statusColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(course.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                Text("\(course.lecturerName)  ·  \(course.dayOfWeek) \(course.classTime)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(spacing: 6) {
                    Label("\(course.attendedCount)/\(course.totalMeetings)",
                          systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    if course.absentCount > 0 {
                        Label("\(course.absentCount) absen",
                              systemImage: "xmark.circle.fill")
                            .foregroundColor(
                                course.isCritical ? .red
                                : (course.isAtRisk ? .orange : .secondary))
                    }
                }
                .font(.caption)
            }

            Spacer()

            if course.isCritical {
                Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            } else if course.isAtRisk {
                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.orange)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Course Detail

struct CourseDetailView: View {
    @EnvironmentObject var dm: DataManager
    let si: Int
    let ci: Int
    @State private var showEdit = false

    var course  : AppCourse  { dm.semesters[si].courses[ci] }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                lecturerCard
                attendanceSummary

                // Meetings
                VStack(alignment: .leading, spacing: 10) {
                    Text("Daftar Pertemuan")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(Array(course.meetings.enumerated()), id: \.element.id) { mi, meeting in
                        NavigationLink {
                            MeetingDetailView(si: si, ci: ci, mi: mi)
                        } label: {
                            MeetingRow(meeting: meeting)
                                .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 24)
            }
            .padding(.top)
        }
        .navigationTitle(course.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .sheet(isPresented: $showEdit) {
            AddEditCourseView(si: si, existingCourse: course, isPresented: $showEdit)
        }
    }

    // ── Lecturer card ──
    var lecturerCard: some View {
        HStack(spacing: 14) {
            Group {
                if let img = dm.loadPhoto(course.lecturerPhotoFilename) {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                } else {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.indigo.opacity(0.4))
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.indigo.opacity(0.3), lineWidth: 1.5))

            VStack(alignment: .leading, spacing: 4) {
                Text(course.lecturerName).font(.headline)
                Label("\(course.dayOfWeek), \(course.classTime)",
                      systemImage: "clock")
                    .font(.subheadline).foregroundColor(.secondary)
                if !course.lecturerPhone.isEmpty {
                    Button {
                        if let url = URL(string: "tel://\(course.lecturerPhone)") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label(course.lecturerPhone, systemImage: "phone.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
                Text("\(course.sks) SKS  ·  \(course.totalMeetings) Pertemuan")
                    .font(.caption).foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // ── Attendance summary ──
    var attendanceSummary: some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                summaryItem(course.attendedCount, "Hadir",  .green)
                Divider().frame(height: 40)
                summaryItem(course.absentCount,   "Absen",  .red)
                Divider().frame(height: 40)
                summaryItem(course.izinCount,     "Izin",   .orange)
                Divider().frame(height: 40)
                summaryItem(course.sakitCount,    "Sakit",  .blue)
            }
            .padding(.vertical, 8)

            if course.isAtRisk || course.isCritical {
                Label(
                    course.isCritical
                        ? "Batas maksimal ketidakhadiran tercapai!"
                        : "Hati-hati! Sisa 1 absen lagi.",
                    systemImage: course.isCritical
                        ? "exclamationmark.triangle.fill"
                        : "exclamationmark.circle.fill"
                )
                .font(.caption.bold())
                .foregroundColor(course.isCritical ? .red : .orange)
                .padding(.bottom, 6)
            }
        }
        .background(Color(.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(course.statusColor.opacity(
                    (course.isAtRisk || course.isCritical) ? 0.5 : 0), lineWidth: 2)
        )
        .cornerRadius(14)
        .padding(.horizontal)
    }

    func summaryItem(_ count: Int, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)").font(.title2.bold()).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meeting Row (card style)

struct MeetingRow: View {
    let meeting: AppMeeting

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(meeting.status.color.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: meeting.status.icon)
                    .foregroundColor(meeting.status.color)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Pertemuan \(meeting.number)")
                        .font(.subheadline.bold())
                    if meeting.hasTask {
                        Image(systemName: "doc.fill")
                            .font(.caption2).foregroundColor(.blue)
                    }
                    if meeting.proofPhotoFilename != nil {
                        Image(systemName: "camera.fill")
                            .font(.caption2).foregroundColor(.green)
                    }
                }
                Text(meeting.notes.isEmpty
                     ? (meeting.status == .belumDiisi ? "Belum diisi" : "Tidak ada catatan")
                     : meeting.notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                if let d = meeting.date {
                    Text(d, style: .date)
                        .font(.caption2).foregroundColor(.secondary)
                }
            }

            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption).foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(11)
    }
}

// MARK: - Add / Edit Course

struct AddEditCourseView: View {
    @EnvironmentObject var dm: DataManager
    let si              : Int
    let existingCourse  : AppCourse?
    @Binding var isPresented: Bool

    @State private var name              = ""
    @State private var sks               = 2
    @State private var lecturerName      = ""
    @State private var lecturerPhone     = ""
    @State private var classTime         = ""
    @State private var dayOfWeek         = "Senin"
    @State private var lecturerPhoto     : UIImage?
    @State private var existingPhotoFile : String?
    @State private var showCamera        = false
    @State private var showSKSWarning    = false

    let days = ["Senin","Selasa","Rabu","Kamis","Jumat","Sabtu"]
    var isEditing: Bool { existingCourse != nil }

    var ci: Int? {
        guard let c = existingCourse else { return nil }
        return dm.semesters[si].courses.firstIndex { $0.id == c.id }
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Info Mata Kuliah")) {
                    TextField("Nama Mata Kuliah", text: $name)
                    Picker("SKS", selection: $sks) {
                        Text("2 SKS — 14 Pertemuan").tag(2)
                        Text("3 SKS — 21 Pertemuan").tag(3)
                    }
                    Picker("Hari Kuliah", selection: $dayOfWeek) {
                        ForEach(days, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Jam Mulai (cth: 08:00)", text: $classTime)
                        .keyboardType(.numbersAndPunctuation)
                }

                Section(header: Text("Info Dosen")) {
                    TextField("Nama Dosen", text: $lecturerName)
                    TextField("No. HP Dosen (opsional)", text: $lecturerPhone)
                        .keyboardType(.phonePad)

                    Button { showCamera = true } label: {
                        HStack(spacing: 12) {
                            photoPreview
                            Text(hasPhoto ? "Ganti Foto Dosen" : "Tambah Foto Dosen (Opsional)")
                                .foregroundColor(.indigo)
                        }
                    }
                }

                if isEditing && sks != (existingCourse?.sks ?? 2) {
                    Section {
                        Label(
                            "Mengubah SKS akan mereset semua data pertemuan!",
                            systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Mata Kuliah" : "Tambah Mata Kuliah")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Simpan") { save() }
                        .bold()
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty
                                  || lecturerName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraView(image: $lecturerPhoto)
        }
        .onAppear { loadExisting() }
    }

    var hasPhoto: Bool { lecturerPhoto != nil || existingPhotoFile != nil }

    @ViewBuilder
    var photoPreview: some View {
        let img: UIImage? = lecturerPhoto ?? dm.loadPhoto(existingPhotoFile)
        if let img {
            Image(uiImage: img)
                .resizable().scaledToFill()
                .frame(width: 46, height: 46).clipShape(Circle())
        } else {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 46, height: 46)
                .foregroundColor(.indigo.opacity(0.4))
        }
    }

    func loadExisting() {
        guard let c = existingCourse else { return }
        name              = c.name
        sks               = c.sks
        lecturerName      = c.lecturerName
        lecturerPhone     = c.lecturerPhone
        classTime         = c.classTime
        dayOfWeek         = c.dayOfWeek
        existingPhotoFile = c.lecturerPhotoFilename
    }

    func save() {
        var photoFile = existingPhotoFile
        if let img = lecturerPhoto {
            photoFile = dm.savePhoto(img, prefix: "lecturer")
        }

        let updated = AppCourse(
            id:                    existingCourse?.id ?? UUID(),
            name:                  name.trimmingCharacters(in: .whitespaces),
            sks:                   sks,
            lecturerName:          lecturerName.trimmingCharacters(in: .whitespaces),
            lecturerPhone:         lecturerPhone,
            lecturerPhotoFilename: photoFile,
            classTime:             classTime,
            dayOfWeek:             dayOfWeek,
            meetings:              existingCourse?.meetings ?? [],
            tasks:                 existingCourse?.tasks    ?? []
        )

        if isEditing, let ci {
            dm.updateCourse(updated, si: si, ci: ci)
        } else {
            dm.addCourse(updated)
        }
        isPresented = false
    }
}
