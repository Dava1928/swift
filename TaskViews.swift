import SwiftUI

// MARK: - Tasks Tab

struct TasksView: View {
    @EnvironmentObject var dm: DataManager
    @State private var selectedFilter: TaskStatus? = nil

    var filtered: [AppTask] {
        let all = dm.allActiveTasks
        guard let f = selectedFilter else { return all }
        return all.filter { $0.status == f }
    }

    var body: some View {
        NavigationView {
            Group {
                if dm.allActiveTasks.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "checklist")
                            .font(.system(size: 64))
                            .foregroundColor(.indigo.opacity(0.35))
                        Text("Belum Ada Tugas")
                            .font(.headline)
                        Text("Tambahkan tugas dari halaman\ndetail pertemuan mata kuliah.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        // Filter chips
                        filterBar
                        
                        if filtered.isEmpty {
                            Spacer()
                            Text("Tidak ada tugas dengan filter ini")
                                .foregroundColor(.secondary)
                            Spacer()
                        } else {
                            List {
                                ForEach(filtered) { task in
                                    TaskDetailRow(task: task)
                                        .listRowInsets(EdgeInsets(
                                            top: 6, leading: 16,
                                            bottom: 6, trailing: 16))
                                }
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Tugas")
        }
    }

    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterPill(label: "Semua",
                           count: dm.allActiveTasks.count,
                           isSelected: selectedFilter == nil) {
                    selectedFilter = nil
                }
                ForEach(TaskStatus.allCases, id: \.self) { s in
                    FilterPill(
                        label: s.rawValue,
                        count: dm.allActiveTasks.filter { $0.status == s }.count,
                        isSelected: selectedFilter == s) {
                        selectedFilter = selectedFilter == s ? nil : s
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        Divider()
    }
}

struct FilterPill: View {
    let label      : String
    let count      : Int
    let isSelected : Bool
    let action     : () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(label)
                Text("\(count)")
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1)
                    .background(isSelected
                                ? Color.white.opacity(0.25)
                                : Color(.systemGray5))
                    .cornerRadius(8)
            }
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.indigo : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Task Detail Row

struct TaskDetailRow: View {
    @EnvironmentObject var dm: DataManager
    let task: AppTask

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(task.title)
                        .font(.subheadline.bold())
                        .strikethrough(task.status == .selesai)
                        .lineLimit(2)
                    Text("\(task.courseName)  ·  Pertemuan \(task.meetingNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if !task.taskDescription.isEmpty {
                        Text(task.taskDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text(task.deadlineText)
                        .font(.caption.bold())
                        .foregroundColor(task.urgencyColor)
                    Text(task.deadline, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Status Picker
            Picker("", selection: statusBinding) {
                ForEach(TaskStatus.allCases, id: \.self) { s in
                    Text(s.rawValue).tag(s)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(.vertical, 4)
    }

    var statusBinding: Binding<TaskStatus> {
        Binding(
            get: { task.status },
            set: { dm.updateTaskStatus(taskId: task.id, newStatus: $0) }
        )
    }
}

// MARK: - Add Task Sheet

struct AddTaskView: View {
    @EnvironmentObject var dm: DataManager
    let si            : Int
    let ci            : Int
    let meetingNumber : Int
    @Binding var isPresented: Bool

    @State private var title       = ""
    @State private var description = ""
    @State private var deadline    = Date().addingTimeInterval(7 * 86_400)

    var courseName: String { dm.semesters[si].courses[ci].name }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detail Tugas")) {
                    TextField("Judul Tugas", text: $title)
                    TextField("Deskripsi (opsional)", text: $description, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section(header: Text("Deadline")) {
                    DatePicker(
                        "Batas Waktu",
                        selection: $deadline,
                        minimumDate: Date(),
                        displayedComponents: [.date, .hourAndMinute])
                }

                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.indigo)
                        Text("Pengingat otomatis dikirim H-3 dan H-1 sebelum deadline.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Tambah Tugas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tambah") { add() }
                        .bold()
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    func add() {
        let task = AppTask(
            courseId:        dm.semesters[si].courses[ci].id,
            courseName:      courseName,
            meetingNumber:   meetingNumber,
            title:           title.trimmingCharacters(in: .whitespaces),
            taskDescription: description,
            deadline:        deadline
        )
        dm.addTask(task, si: si, ci: ci)
        isPresented = false
    }
}
