

---

# 📝 TodoList App - Flutter & Laravel API

TodoList adalah aplikasi manajemen tugas harian yang dibangun menggunakan **Flutter** (untuk mobile) dan **Laravel** (sebagai backend RESTful API). Aplikasi ini memudahkan pengguna dalam mencatat, mengelola, dan menyaring tugas berdasarkan prioritas. Cocok untuk keperluan pribadi maupun profesional.

## 🚀 Fitur Aplikasi

* 🔐 Login & Register: Autentikasi pengguna dengan Laravel Sanctum.
* ➕ Tambah Tugas: Buat to-do baru dengan deskripsi dan prioritas.
* 🗑️ Hapus Tugas: Hapus to-do berdasarkan ID.
* ✏️ Update Tugas: Edit deskripsi dan prioritas dari to-do.
* ✅ Checklist: Tandai tugas yang sudah selesai.
* 🔍 Filter Prioritas: Saring daftar tugas berdasarkan tingkat prioritas (tinggi, sedang, rendah).
* 💾 Session Storage: Menggunakan `SharedPreferences` untuk menyimpan token user di sisi mobile.

## ⚙️ Cara Kerja Aplikasi

1. Pengguna melakukan register atau login melalui Flutter UI.
2. Flutter mengirim permintaan ke API Laravel menggunakan HTTP request.
3. Setelah berhasil login, token disimpan menggunakan `SharedPreferences`.
4. Semua permintaan selanjutnya akan menggunakan token tersebut pada header (Bearer Token).
5. Pengguna dapat menambahkan, melihat, menghapus, memperbarui, dan menyaring daftar tugas.
6. Laravel menangani semua logika bisnis dan menyimpan data ke MySQL.

## 🛠️ Instalasi

### 🔧 Backend (Laravel API)

1. Clone repository backend:
   git clone [https://github.com/username/backend-todolist.git](https://github.com/username/backend-todolist.git)
   cd backend-todolist

2. Install dependencies:
   composer install

3. Copy file konfigurasi:
   cp .env.example .env
   php artisan key\:generate

4. Atur konfigurasi database di file `.env`, lalu:
   php artisan migrate
   php artisan install\:api

5. Jalankan server lokal:
   php artisan serve

### 📱 Frontend (Flutter App)

1. Clone repository frontend:
   git clone [https://github.com/username/flutter-todolist.git](https://github.com/username/flutter-todolist.git)
   cd flutter-todolist

2. Install dependencies:
   flutter pub get

3. Jalankan aplikasi:
   flutter run

## 📦 Dependencies & Plugin Flutter

dependencies:
flutter:
sdk: flutter
http: ^1.1.0
shared\_preferences: ^2.2.2
intl: ^0.18.1

dev\_dependencies:
flutter\_test:
sdk: flutter
flutter\_lints: ^5.0.0
flutter\_native\_splash: ^2.3.10

## 🧠 Catatan Tambahan

* Pastikan backend Laravel berjalan di URL yang sama dengan yang digunakan di Flutter (ubah endpoint jika diperlukan).
* Gunakan emulator atau perangkat fisik dengan koneksi ke localhost yang benar (gunakan IP 10.0.2.2 di Android emulator untuk mengakses localhost).

## 📄 Identitas Pembuat

Nama: Rama Fitrian Handoko
No Absen : 27


