# 📱 AbsensiKuliah — Panduan Setup Lengkap

Aplikasi absensi kuliah pribadi untuk iOS.  
Build via **Codemagic** → install ke iPhone via **KSign**.

---

## 📁 File Swift yang Ada

| File | Isi |
|------|-----|
| `Models.swift` | Semua data model (Semester, Course, Meeting, Task) |
| `DataManager.swift` | Logika bisnis, simpan data, notifikasi |
| `AbsensiKuliahApp.swift` | Entry point, RootView, WelcomeView, TabView |
| `HomeView.swift` | Dashboard semester aktif |
| `CourseViews.swift` | List matkul, detail matkul, form tambah/edit |
| `MeetingDetailView.swift` | Input absensi per pertemuan + kamera |
| `TaskViews.swift` | Daftar tugas + tambah tugas |
| `HistoryView.swift` | Arsip semester lalu |
| `CameraView.swift` | Wrapper kamera (hanya kamera, bukan galeri) |
| `codemagic.yaml` | Config build CI/CD |
| `exportOptions.plist` | Config export IPA |

---

## 🔧 Langkah Setup Xcode Project

Karena kamu tidak punya Mac, gunakan cara ini:

### Cara 1 — Pakai Codemagic Starter (Paling Mudah)

1. Buat akun di [codemagic.io](https://codemagic.io)
2. Klik **"Add application"** → pilih **iOS App** → pilih **SwiftUI** template
3. Codemagic akan membuat repo GitHub + project Xcode otomatis
4. **Hapus** semua file `.swift` bawaan di repo, lalu **upload** semua file dari folder ini
5. **Tambah** `codemagic.yaml` dan `exportOptions.plist` ke root repo

### Cara 2 — Fork Template GitHub

1. Cari repo template SwiftUI kosong di GitHub, misalnya:  
   `https://github.com/nicklockwood/SwiftUI-App-Template` atau buat sendiri
2. Replace isi dengan file-file di sini
3. Hubungkan repo ke Codemagic

---

## ⚙️ Konfigurasi Info.plist

Di Xcode project, buka `Info.plist` dan tambahkan key berikut
(atau tambahkan langsung ke target → Info):

```xml
<key>NSCameraUsageDescription</key>
<string>Diperlukan untuk mengambil foto bukti kehadiran di kelas.</string>

<key>NSUserNotificationsUsageDescription</key>
<string>Untuk mengirim peringatan ketidakhadiran dan pengingat deadline tugas.</string>
```

Tanpa ini, app akan crash saat membuka kamera.

---

## 🔐 Signing di Codemagic

### Pakai Apple ID Gratis (untuk KSign / sideload)
1. Di Codemagic → **Teams** → **Code signing** → **iOS certificates**
2. Upload **Development certificate** (.p12) dari Apple ID kamu
3. Upload **Provisioning profile** (wildcard atau untuk bundle ID kamu)
4. Di `codemagic.yaml`, ubah `distribution_type: development`
5. Di `exportOptions.plist`, ubah method ke `development`

### Bundle ID
Ubah `com.yourname.AbsensiKuliah` di:
- `codemagic.yaml`
- Xcode project → Target → General → Bundle Identifier

---

## 📲 Cara Install via KSign

1. Setelah Codemagic selesai build, download file `.ipa` dari hasilnya
2. Buka **KSign** di iPhone
3. Pilih file `.ipa` yang sudah didownload
4. Sign dan install
5. Pergi ke **Settings → General → VPN & Device Management** → trust sertifikat

---

## ✨ Fitur Lengkap

### 🏠 Beranda
- Ringkasan semester aktif (total matkul, hadir, absen, tugas)
- Banner peringatan untuk matkul berisiko
- Progress kehadiran per matkul
- 5 tugas mendatang

### 📚 Mata Kuliah
- Tambah/edit/hapus mata kuliah
- Input: nama, SKS (2/3), hari, jam, nama dosen, HP dosen, foto dosen
- 2 SKS → 14 pertemuan | 3 SKS → 21 pertemuan
- Tap matkul → lihat semua pertemuan

### ✅ Per Pertemuan
- Status: Hadir / Tidak Hadir / Izin / Sakit
- Catatan materi kuliah
- Foto bukti hadir (wajib dari kamera langsung)
- Tambah tugas dari pertemuan ini

### ⚠️ Sistem Peringatan
- **Absen ke-2** → Pop-up in-app + Push Notification: peringatan jangan bolos
- **Absen ke-3** → Pop-up merah kritis + Push Notification: batas maksimal

### 📝 Tugas
- Input per pertemuan: judul, deskripsi, deadline
- Status: Belum / Sedang / Selesai
- Pengingat otomatis **H-3** dan **H-1** via Push Notification
- Filter tugas by status

### 🗂️ Histori
- Semua semester tersimpan permanen
- Rekap lengkap kehadiran & tugas per semester

---

## 🐛 Troubleshooting

| Masalah | Solusi |
|---------|--------|
| Kamera tidak muncul | Pastikan `NSCameraUsageDescription` ada di Info.plist |
| Notifikasi tidak muncul | Izinkan notifikasi saat pertama buka app |
| Build gagal di Codemagic | Cek bundle ID dan signing certificate sudah benar |
| Data hilang | Data disimpan di UserDefaults, jangan uninstall tanpa backup |
