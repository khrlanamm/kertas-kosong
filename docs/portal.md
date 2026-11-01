# Portal Bimbel

Aplikasi Flutter di `apps/portal`, versi web dulu, lalu Android dari kode yang sama. Backend-nya Firebase: Authentication, Firestore, Cloud Functions (`functions/`), dan Storage.

## Fitur tahap ini

**Akun**
- Masuk dengan Google atau email dan kata sandi, termasuk daftar akun dan lupa kata sandi.
- Pengguna baru wajib melengkapi profil: nama, asal sekolah, kelas atau status, kota, nomor WhatsApp (opsional), dan persetujuan penggunaan data.
- Dua peran, yaitu **siswa** dan **admin**, disimpan di `pengguna/{uid}.peran`. Semua akun baru otomatis menjadi siswa.

**Admin**
- Membuat tryout dari template UTBK-SNBT 2026 atau dari nol.
- Mengatur status draf/terbit, jadwal buka dan tutup dalam WIB, serta aturan pengerjaan:
  - acak urutan soal;
  - acak urutan pilihan jawaban;
  - urutan subtes tetap atau bebas;
  - hasil langsung tampil atau baru setelah tryout ditutup;
  - pembahasan dibuka setelah tryout ditutup.
- Mengelola subtes: nama, durasi (boleh desimal, misalnya 42,5 menit), target jumlah soal, dan urutan.
- Menyusun soal dalam empat tipe (lihat di bawah).
- Membuat bacaan atau stimulus yang dipakai beberapa soal sekaligus.
- Editor soal mendukung Markdown, tabel, rumus LaTeX, dan unggah gambar, dengan pratinjau langsung beserta kuncinya.
- Tab Hasil:
  - jumlah benar per subtes;
  - hitung skor berbobot;
  - hitung ulang setelah kunci diperbaiki;
  - unduh CSV.
- Mengatur peran pengguna.
- Mencoba tryout sebagai peserta kapan saja. Percobaan admin tidak ikut dinilai.

**Siswa**
- Daftar tryout dengan statusnya: akan dibuka, bisa dikerjakan, sedang dikerjakan, selesai, atau ditutup.
- Halaman pengerjaan bergaya CBT UTBK:
  - hitung mundur berdasarkan jam server;
  - bacaan di samping soal (di HP bisa dilipat);
  - daftar nomor soal;
  - tanda ragu-ragu;
  - jawaban tersimpan otomatis;
  - pengumpulan otomatis saat waktu habis.
- Subtes dikerjakan berurutan. Jika koneksi putus, peserta bisa melanjutkan dengan sisa waktu yang tetap berjalan.
- Hasil per subtes dan halaman pembahasan: jawaban peserta, kunci, dan penjelasan.

## Tipe soal

Format UTBK-SNBT 2026 memakai tiga bentuk soal: pilihan ganda lima opsi, pilihan majemuk kompleks dalam bentuk tabel dua pilihan, dan isian singkat. Portal mendukung ketiganya, ditambah pilihan ganda kompleks berbentuk centang yang banyak dipakai di latihan soal.

| Tipe | Cara menjawab | Dinilai benar jika |
|---|---|---|
| Pilihan ganda | Pilih satu dari A-E | Sama dengan kunci |
| Pilihan ganda kompleks | Centang semua yang benar | Semua pilihan tepat, tidak kurang dan tidak lebih |
| Tabel benar/salah | Setiap pernyataan dijawab dengan salah satu dari dua kolom. Label kolom bisa Benar/Salah, Ya/Tidak, Sesuai/Tidak Sesuai, Mendukung/Tidak Mendukung, atau Fakta/Opini | Semua baris tepat |
| Isian singkat | Ketik angka, kata, atau frasa | Cocok dengan salah satu jawaban yang diterima |

Untuk isian angka:
- "2,5", "2.5", dan "5/2" dianggap sama;
- admin bisa memberi toleransi, misalnya ±0,01;
- admin bisa memasukkan beberapa jawaban yang diterima.

Untuk isian teks, huruf besar/kecil dan spasi berlebih diabaikan.

Seperti UTBK, setiap soal bernilai 1 atau 0 tanpa nilai minus.

Template UTBK-SNBT 2026 (160 soal, 195 menit, tanpa jeda):

| Subtes | Soal | Waktu |
|---|---|---|
| Penalaran Umum (PU) | 30 | 30 menit |
| Pengetahuan dan Pemahaman Umum (PPU) | 20 | 15 menit |
| Pemahaman Bacaan dan Menulis (PBM) | 20 | 25 menit |
| Pengetahuan Kuantitatif (PK) | 20 | 20 menit |
| Literasi dalam Bahasa Indonesia | 30 | 42,5 menit |
| Literasi dalam Bahasa Inggris | 20 | 20 menit |
| Penalaran Matematika | 20 | 42,5 menit |

Pada 2026, PU dibagi lagi menjadi penalaran induktif, deduktif, dan kuantitatif (masing-masing 10 soal, 10 menit). Pembagian ini bisa dibuat sebagai tiga subtes terpisah jika diperlukan.

### Skor

Jumlah benar dihitung saat subtes dikumpulkan. Setelah tryout ditutup, admin menekan **Hitung skor** untuk mendapatkan skor berbobot pada skala 200-1000.

Cara menghitung bobot setiap soal: `bobot = 0,1 + 0,9 × (1 - p)`, dengan `p` adalah proporsi peserta yang menjawab benar. Soal yang jarang dijawab benar bernilai lebih tinggi. Ini perkiraan bergaya IRT, bukan IRT resmi SNPMB.

## Keamanan

- Soal, kunci, dan bacaan hanya bisa dibaca admin (`firestore.rules`).
- Peserta menerima soal tanpa kunci lewat Cloud Function `mulaiSubtes`, dan hanya saat subtesnya berjalan.
- Waktu mulai dan batas waktu ditentukan server. Rules menolak jawaban setelah batas waktu (dengan tenggang 5 detik) dan menolak jawaban untuk soal di luar sesinya.
- Jawaban dinilai di server (`kumpulkanSubtes`, `hitungSkor`). Kunci baru dikirim ke peserta lewat `pembahasan` setelah tryout ditutup, dan hanya jika admin mengizinkan.

Tes otomatisnya ada di `functions/test`:

| Tes | Isi | Perintah |
|---|---|---|
| Penilaian | Logika penilaian (unit test) | `npm test` |
| Rules dan alur | Rules Firestore dan alur ujian lengkap di emulator | `npm run test:emulator` |

## Menjalankan di komputer

Kebutuhan:
- Node.js 22;
- Flutter 3.47 atau lebih baru;
- Java (untuk emulator Firestore);
- Firebase CLI.

```sh
cd functions && npm install && cd ..
firebase emulators:start --project demo-kertas-kosong
```

Di terminal lain:

```sh
cd apps/portal
flutter run -d chrome --dart-define-from-file=env/emulator.json
```

Alamat emulator:

| Layanan | Alamat |
|---|---|
| Emulator UI (data, akun) | http://127.0.0.1:4000 |
| Website | http://127.0.0.1:5002 |
| Portal hasil `flutter build web` | http://127.0.0.1:5007 |

Untuk mencoba sebagai admin:
1. Daftar akun di portal.
2. Buka Emulator UI → Firestore → `pengguna/<uid>`.
3. Ubah `peran` menjadi `admin`.

## Menayangkan

1. Pastikan project sudah Blaze. Cloud Functions membutuhkannya.
2. Authentication → Sign-in method → aktifkan **Google** dan **Email/Password**.
3. Storage → Get started. Ini untuk gambar soal.
4. Buat situs hosting kedua untuk portal:
   ```sh
   firebase hosting:sites:create kertas-kosong-portal
   ```
   Jika nama situs ini sudah dipakai orang lain, ganti `site` di `firebase.json`.
5. Authentication → Settings → Authorized domains → tambahkan `kertas-kosong-portal.web.app`, juga domain sendiri jika ada.
6. Salin konfigurasi web app:
   - salin `apps/portal/env/produksi.contoh.json` menjadi `apps/portal/env/produksi.json`;
   - isi nilainya dari Project settings → Your apps → Web app (nilainya sama dengan `VITE_FIREBASE_*` di `.env` portal lama).
   - Berkas ini tidak masuk git.
7. Deploy:
   ```sh
   firebase deploy --only functions,firestore,storage,hosting:kertas-kosong-portal
   ```
8. Masuk ke portal dengan akunmu.
9. Di Firebase Console → Firestore → `pengguna/<uid kamu>`, ubah `peran` menjadi `admin`. Setelah itu admin lain bisa diatur dari menu Pengguna di portal.

Jika gambar soal tidak tampil, portal sudah memuatnya lewat elemen `<img>` sebagai cadangan. Untuk performa terbaik, atur CORS bucket Storage seperti dijelaskan di [dokumentasi Firebase](https://firebase.google.com/docs/storage/web/download-files#cors_configuration).

## Eksplorasi: pendaftaran bimbel dan seminar

Selama ini pendaftaran memakai Google Form, dan datanya tersimpan di Drive. Catatan tim menemukan folder pendaftaran 2025 dan 2026 (foto diri, kartu pelajar, kartu UTBK) bisa dibuka siapa saja yang punya tautan. Pindah ke portal sekaligus menyelesaikan masalah itu.

### Pilihan

**A. Program dikelola admin di portal (disarankan)**

- **Admin membuat Program**, misalnya "Bimbel Ayo Kuliah 2027" atau "Seminar Ayo Kuliah 2027". Pengaturannya:
  - jenis, deskripsi, periode pendaftaran, dan kuota (opsional);
  - cara seleksi: langsung diterima, atau ditinjau admin;
  - pertanyaan tambahan dengan pembuat formulir sederhana: teks pendek, paragraf (surat motivasi atau esai), pilihan, dan centang persetujuan atau kontrak belajar.
- **Siswa mendaftar sekali klik.** Profil yang sudah ada dipakai ulang, jadi siswa cukup menjawab pertanyaan tambahan.
  - Status pendaftarannya terlihat di portal: menunggu, diterima, cadangan, atau ditolak.
- **Admin meninjau di satu tabel.**
  - Filter per status, sekolah, dan kota.
  - Baca esai dan ubah status, termasuk sekaligus untuk banyak pendaftar.
  - Bagi peserta ke kelas (A, B, ...) dan ekspor CSV.
  - Statistik jangkauan: jumlah per kota dan per sekolah, seperti slide jangkauan 2026.
- **Terhubung dengan tryout.** Akses tryout bisa diatur untuk semua siswa atau hanya peserta program tertentu. Nanti rekaman kelas dan presensi memakai daftar peserta yang sama.
- **Seminar:** cukup mode langsung diterima dengan kuota. Bisa ditambah check-in QR dan sertifikat di tahap berikutnya.

Rancangan data: `program/{id}` untuk pengaturan, dan `program/{id}/pendaftar/{uid}` untuk jawaban dan status. ID pendaftar sama dengan uid, sehingga satu akun hanya bisa mendaftar sekali. Rules mengizinkan siswa membuat pendaftarannya sendiri hanya selama periode pendaftaran, dan hanya admin yang bisa mengubah status.

**B. Tetap Google Form, lalu impor ke portal**

Admin mengunggah daftar email peserta yang diterima, lalu portal membuka akses tryout untuk email itu.
- **Kelebihan:** paling cepat, tidak ada yang perlu dibangun.
- **Kekurangan:**
  - data tersebar di dua tempat;
  - risiko folder Drive publik tetap ada;
  - siswa harus memakai email yang sama di formulir dan di portal.

**C. Formulir tetap khusus bimbel**

Isian formulirnya ditulis langsung di kode.
- **Kelebihan:** sederhana.
- **Kekurangan:** setiap angkatan atau seminar dengan isian berbeda butuh perubahan kode.

### Saran

Pilih **A**, mulai dari versi minimal yang siap sebelum pendaftaran Februari 2027:
- program;
- pertanyaan tambahan;
- seleksi oleh admin;
- akses tryout khusus peserta.

Check-in seminar, sertifikat, dan notifikasi menyusul.

Sesuai UU Pelindungan Data Pribadi:
- kumpulkan data seperlunya saja, dan hindari meminta scan kartu identitas jika tidak benar-benar dibutuhkan;
- tentukan kapan data pendaftar dihapus setelah program selesai.

### Yang perlu diputuskan

1. Apakah seleksi bimbel memakai surat motivasi atau esai yang ditinjau, atau semua pendaftar langsung diterima?
2. Apakah ada kuota per angkatan?
3. Apakah pembagian kelas (A/B) dilakukan admin di portal?
4. Data tambahan apa yang wajib, selain profil? Apakah benar-benar perlu unggah berkas?
5. Apakah pendaftaran seminar juga lewat portal, atau seminar boleh tanpa akun?

## Rencana berikutnya

1. Pendaftaran program (lihat eksplorasi di atas).
2. Impor soal massal dari spreadsheet, supaya 160 soal tidak diketik satu per satu.
3. Rekaman kelas dan presensi, menggantikan tautan di portal lama.
4. Versi Android, notifikasi FCM (pengingat tryout), dan `FLAG_SECURE` di layar tryout.
5. App Check untuk melindungi Functions dan Firestore dari akses di luar aplikasi.
