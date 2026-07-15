import SwiftUI

@main
struct AbsensiKuliahApp: App {
    @StateObject var dm = DataManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dm)
        }
    }
}

// MARK: - Root View

struct RootView: View {
    @EnvironmentObject var dm: DataManager

    var body: some View {
        Group {
            if dm.semesters.isEmpty {
                WelcomeView()
            } else {
                ContentView()
            }
        }
        // Global absence warning alert
        .alert(
            dm.absenceWarning?.title ?? "Peringatan",
            isPresented: Binding(
                get: { dm.absenceWarning != nil },
                set: { if !$0 { dm.absenceWarning = nil } }
            )
        ) {
            Button("Mengerti", role: .cancel) { dm.absenceWarning = nil }
        } message: {
            if let w = dm.absenceWarning {
                Text(w.message)
            }
        }
    }
}

// MARK: - Welcome View (first launch)

struct WelcomeView: View {
    @State private var showCreate = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 90))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing))

            VStack(spacing: 8) {
                Text("Absensi Kuliah")
                    .font(.largeTitle.bold())
                Text("Pantau kehadiran & tugas kuliah\nkamu setiap semester.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button {
                showCreate = true
            } label: {
                Label("Mulai — Buat Semester Baru", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.indigo)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
        }
        .sheet(isPresented: $showCreate) {
            NewSemesterSheet(isPresented: $showCreate)
        }
    }
}

// MARK: - New Semester Sheet (reused from multiple screens)

struct NewSemesterSheet: View {
    @EnvironmentObject var dm: DataManager
    @Binding var isPresented: Bool
    @State private var name = ""

    let suggestions = [
        "Semester Ganjil 2025/2026",
        "Semester Genap 2025/2026",
        "Semester Ganjil 2026/2027"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nama Semester")) {
                    TextField("cth: Semester Ganjil 2025/2026", text: $name)
                }
                Section(header: Text("Saran Cepat")) {
                    ForEach(suggestions, id: \.self) { s in
                        Button(s) { name = s }
                            .foregroundColor(.indigo)
                    }
                }
                Section(footer: Text("Semester sebelumnya akan tetap tersimpan di Histori.")) {
                    EmptyView()
                }
            }
            .navigationTitle("Semester Baru")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Batal") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Buat") {
                        let trimmed = name.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        dm.createSemester(name: trimmed)
                        isPresented = false
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .bold()
                }
            }
        }
    }
}

// MARK: - Main Tab View

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Beranda", systemImage: "house.fill") }

            CoursesView()
                .tabItem { Label("Mata Kuliah", systemImage: "book.fill") }

            TasksView()
                .tabItem { Label("Tugas", systemImage: "checklist") }

            HistoryView()
                .tabItem { Label("Histori", systemImage: "clock.fill") }
        }
        .tint(.indigo)
    }
}
