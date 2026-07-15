import SwiftUI

struct MeetingDetailView: View {
    @EnvironmentObject var dm: DataManager
    let si: Int
    let ci: Int
    let mi: Int

    // Local editable state
    @State private var status             : AttendanceStatus = .belumDiisi
    @State private var notes              : String           = ""
    @State private var selectedDate       : Date             = Date()
    @State private var proofPhoto         : UIImage?
    @State private var existingPhotoFile  : String?

    // Sheet/navigation flags
    @State private var showCamera         = false
    @State private var showAddTask        = false
    @State private var showFullPhoto      = false
    @State private var saveSuccess        = false

    var meeting     : AppMeeting  { dm.semesters[si].courses[ci].meetings[mi] }
    var course      : AppCourse   { dm.semesters[si].courses[ci] }
    var meetingTasks: [AppTask]   {
        course.tasks.filter { $0.meetingNumber == meeting.number }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                // ── Status buttons ──
                statusSection

                // ── Date picker ──
                cardSection("Tanggal Pertemuan") {
                    DatePicker("", selection: $selectedDate,
                               displayedComponents: .date)
                        .labelsHidden()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // ── Notes ──
                cardSection("Catatan Materi") {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 90)
                        if notes.isEmpty {
                            Text("Tulis ringkasan materi pertemuan ini…")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.horizontal, 5)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }

                // ── Proof photo (only when Hadir) ──
                if status == .hadir {
                    photoSection
                }

                // ── Tasks ──
                tasksSection

                // ── Save ──
                Button(action: saveMeeting) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Simpan Kehadiran")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(14)
                }
                .padding(.horizontal)

                if saveSuccess {
                    Label("Tersimpan!", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.subheadline)
                }

                Spacer(minLength: 32)
            }
            .padding(.top)
        }
        .navigationTitle("Pertemuan \(meeting.number)")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCamera) {
            CameraView(image: $proofPhoto)
        }
        .sheet(isPresented: $showAddTask) {
            AddTaskView(si: si, ci: ci,
                        meetingNumber: meeting.number,
                        isPresented: $showAddTask)
        }
        .sheet(isPresented: $showFullPhoto) {
            if let img = proofPhoto ?? dm.loadPhoto(existingPhotoFile) {
                FullPhotoView(image: img)
            }
        }
        .onAppear(perform: loadMeeting)
    }

    // MARK: - Status Section
    var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status Kehadiran")
                .font(.headline)
                .padding(.horizontal)

            HStack(spacing: 8) {
                ForEach(AttendanceStatus.allCases, id: \.self) { s in
                    if s != .belumDiisi {
                        Button { withAnimation { status = s } } label: {
                            VStack(spacing: 5) {
                                Image(systemName: s.icon)
                                    .font(.title3)
                                Text(s.rawValue)
                                    .font(.caption2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(status == s
                                        ? s.color.opacity(0.18)
                                        : Color(.secondarySystemBackground))
                            .foregroundColor(status == s ? s.color : .secondary)
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(status == s ? s.color : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Photo Section
    var photoSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bukti Kehadiran")
                    .font(.headline)
                Spacer()
                Text("Wajib dari kamera")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let photo = proofPhoto ?? dm.loadPhoto(existingPhotoFile) {
                Button { showFullPhoto = true } label: {
                    Image(uiImage: photo)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.green.opacity(0.4), lineWidth: 1.5))
                }
                .buttonStyle(.plain)

                Button { showCamera = true } label: {
                    Label("Foto Ulang", systemImage: "camera.fill")
                        .font(.subheadline)
                        .foregroundColor(.indigo)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Button { showCamera = true } label: {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Ambil Foto Bukti Hadir")
                    }
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)

                Text("Foto diambil langsung dari kamera (tidak bisa dari galeri)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Tasks Section
    var tasksSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Tugas Pertemuan \(meeting.number)")
                    .font(.headline)
                Spacer()
                Button { showAddTask = true } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.indigo)
                        .font(.title3)
                }
            }

            if meetingTasks.isEmpty {
                Label("Belum ada tugas untuk pertemuan ini",
                      systemImage: "tray")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                ForEach(meetingTasks) { task in
                    taskCard(task)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    func taskCard(_ task: AppTask) -> some View {
        HStack(spacing: 10) {
            Image(systemName: task.status.icon)
                .foregroundColor(task.status.color)
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline)
                    .strikethrough(task.status == .selesai)
                Text(task.deadlineText)
                    .font(.caption)
                    .foregroundColor(task.urgencyColor)
            }
            Spacer()
        }
        .padding(8)
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(8)
    }

    // MARK: - Helpers
    func cardSection<Content: View>(_ title: String,
                                    @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            content()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    func loadMeeting() {
        let m         = dm.semesters[si].courses[ci].meetings[mi]
        status        = m.status
        notes         = m.notes
        selectedDate  = m.date ?? Date()
        existingPhotoFile = m.proofPhotoFilename
        if let fn = m.proofPhotoFilename {
            proofPhoto = dm.loadPhoto(fn)
        }
    }

    func saveMeeting() {
        var updated       = meeting
        updated.status    = status
        updated.notes     = notes
        updated.date      = selectedDate

        // Save new proof photo if taken
        if let newPhoto = proofPhoto, existingPhotoFile == nil {
            updated.proofPhotoFilename = dm.savePhoto(newPhoto, prefix: "proof")
        } else if proofPhoto != nil, existingPhotoFile != nil {
            // User re-took photo — save new one and delete old
            if let old = existingPhotoFile { dm.deletePhoto(old) }
            updated.proofPhotoFilename = dm.savePhoto(proofPhoto!, prefix: "proof")
            existingPhotoFile = updated.proofPhotoFilename
        }

        dm.updateMeeting(updated, si: si, ci: ci, mi: mi)

        withAnimation {
            saveSuccess = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            saveSuccess = false
        }
    }
}

// MARK: - Full Photo Viewer

struct FullPhotoView: View {
    let image: UIImage
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .navigationTitle("Bukti Hadir")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Tutup") { dismiss() }
                    }
                }
        }
    }
}
