# Arsitektur

Catatan keputusan dan rencana untuk website Komunitas Kertas Kosong dan Portal Bimbel.

## Kebutuhan dan skala

- Website komunitas yang menjelaskan komunitas dan programnya secara lengkap.
- Portal Bimbel, untuk web dan Android:
  - tryout (fitur utama)
  - pendaftaran bimbel
  - pendaftaran seminar
  - rekaman kelas dan kehadiran
- Peserta bimbel sekitar 100 sampai 200 orang per tahun.
- Tryout biasanya dua kali setahun, di bulan Maret dan Mei.
- Semua program gratis, jadi tidak perlu payment gateway.

## Keputusan

### Firebase sebagai backend

Satu project Firebase (`kertas-kosong`) dengan paket Blaze sudah lebih dari cukup:

| Kebutuhan | Layanan |
|---|---|
| Hosting website dan portal web | Firebase Hosting, dua site dalam satu project |
| Login peserta dan admin | Firebase Authentication: Google serta Email/Password |
| Data (kegiatan, pendaftaran, tryout) | Cloud Firestore |
| Logika yang tidak boleh di klien (penilaian tryout, peran admin) | Cloud Functions, TypeScript |
| Poster, sertifikat, lampiran | Cloud Storage |
| Notifikasi (pengingat tryout, info kelas) | Firebase Cloud Messaging |

Perkiraan biaya hampir nol, karena paket Blaze tetap memakai kuota gratis harian dan bulanan:

| Kuota gratis | Batas |
|---|---|
| Firestore | 50 ribu baca dan 20 ribu tulis per hari |
| Functions | 2 juta panggilan per bulan |

Satu tryout dengan 200 peserta × ±160 soal, jika jawaban disimpan otomatis per soal, menghasilkan sekitar 32 ribu tulis yang tersebar selama periode tryout. Kalaupun melewati kuota, biayanya hanya beberapa sen dolar. Tetap pasang budget alert di Google Cloud Billing, karena Blaze tidak punya batas biaya otomatis.

Dengan skala ini, prioritasnya adalah kesederhanaan, bukan optimasi skala.

### Satu repo (monorepo)

Website, portal, Functions, dan rules memakai project Firebase yang sama dan sering berubah bersamaan. Contohnya, fitur pendaftaran menyentuh rules, Function, dan portal sekaligus. Dalam satu repo, perubahan seperti itu cukup satu PR, dan `firebase.json` mengatur semuanya dari satu tempat. Dengan tim kecil, memecah repo hanya menambah risiko rules dan kode tidak sinkron.

Target strukturnya:

```
apps/web/        website komunitas (Astro)          → site hosting "kertas-kosong"
apps/portal/     Portal Bimbel (Flutter web+Android) → site hosting kedua, mis. "kertas-kosong-portal"
functions/       Cloud Functions (TypeScript)
firestore.rules, storage.rules, firestore.indexes.json, firebase.json
```

### Website: Astro, statis

Website komunitas perlu tampil baik di mesin pencari dan saat link dibagikan di WhatsApp atau Instagram. Astro menghasilkan HTML statis, sehingga setiap halaman membawa judul, deskripsi, dan gambar pratinjaunya sendiri tanpa JavaScript. Website sengaja tidak dibuat dengan Flutter, karena Flutter web berat di awal dan lemah untuk SEO.

Saat ini isi website, termasuk kegiatan, disimpan sebagai file di repo. Setelah portal punya data kegiatan di Firestore, website bisa membacanya saat build supaya data tidak dobel.

### Portal: Flutter, web dulu lalu Android

Satu kode Flutter untuk web dan Android. Rilis web lebih dulu supaya bisa langsung dipakai dari browser mana pun. Versi Android menyusul dari kode yang sama.

Fitur admin (kelola kegiatan, pendaftar, soal tryout) dibuat sebagai halaman khusus admin di portal yang sama. Aksesnya dibatasi dengan custom claim `admin`.

### Region

Firestore berada di `asia-southeast2` (Jakarta). Functions harus diletakkan di region yang sama.

## Rancangan data portal

> Rancangan awal di bawah ini sudah diwujudkan dengan nama koleksi `pengguna`, `ujian` (beserta `soal` dan `stimulus`), dan `sesi` (beserta `pengerjaan`). Detail yang berlaku ada di [portal.md](portal.md) dan `firestore.rules`.

Koleksi lama (`rekaman`, `kehadiran`, `jadwal_tryout`, `tryout`, `tautan_penting`) milik portal lama. Datanya tetap ada, tapi tidak lagi bisa dibaca klien sejak rules baru di-deploy. Portal baru memakai koleksi baru:

| Koleksi | Isi | Akses |
|---|---|---|
| `pengguna/{uid}` | Profil: nama, sekolah, kelas, nomor HP | Hanya pemilik; admin bisa membaca |
| `kegiatan/{id}` | Bimbel, seminar, dan tryout: jadwal, kuota, status pendaftaran | Publik membaca; hanya admin menulis |
| `pendaftaran/{kegiatanId}_{uid}` | Data pendaftaran dan statusnya. ID gabungan mencegah daftar dua kali | Pemilik membuat dan membaca; admin mengubah status |
| `tryout/{id}` | Paket tryout: subtes, durasi, waktu buka dan tutup | Peserta terdaftar membaca |
| `tryout/{id}/soal/{subtes}` | Soal satu subtes dalam satu dokumen, tanpa kunci jawaban | Hanya saat sesi subtes berjalan |
| `kunci_tryout/{id}` | Kunci jawaban | Tertutup untuk klien; hanya dibaca Functions |
| `sesi_tryout/{tryoutId}_{uid}` | Waktu mulai dari server, batas waktu, dan jawaban yang tersimpan otomatis | Pemilik menulis selama waktu belum habis |
| `hasil_tryout/{tryoutId}_{uid}` | Nilai | Ditulis Functions; pemilik membaca |

### Keamanan tryout

- Kunci jawaban tidak pernah dikirim ke aplikasi. Penilaian dilakukan di Cloud Functions.
- Waktu mulai dicatat dengan waktu server, bukan jam HP peserta. Rules menolak jawaban setelah batas waktu.
- Jawaban disimpan otomatis per soal. Kalau koneksi putus, peserta bisa melanjutkan dari jawaban terakhir.
- Soal hanya bisa dibaca selama sesi subtes peserta sedang berjalan.
- Di Android, layar tryout bisa diberi `FLAG_SECURE` supaya tidak bisa di-screenshot.
- Nilai berbasis IRT (jika dipakai) dihitung setelah tryout ditutup oleh satu Function, karena butuh semua jawaban peserta. Untuk 200 peserta, proses ini hanya beberapa detik.

## Tahapan

1. **Website komunitas (selesai).** Astro, isi dari materi komunitas, hosting baru.
2. **Portal: akun dan tryout (selesai, versi web).** Login Google/email, peran siswa/admin, penyusun tryout dengan empat tipe soal UTBK, pengerjaan berwaktu, penilaian di Functions, hasil, skor berbobot, dan pembahasan. Lihat [portal.md](portal.md).
3. **Portal: pendaftaran, jadwal, dan pengawasan (selesai, versi web).** Pendaftaran seminar dan bimbel, pembagian kelas A/B, jadwal bimbel, tryout khusus peserta, dan pengawasan saat tryout. Lihat [portal.md](portal.md).
4. **Android.** Rilis ke Play Store, notifikasi FCM, dan `FLAG_SECURE` di layar tryout.
5. **Rekaman dan kehadiran** pindah ke portal, menggantikan tautan di portal lama.

## Firebase Console

Blaze, Authentication, Firestore, Storage, dan kedua situs hosting sudah aktif. Detailnya ada di [portal.md](portal.md#menayangkan).

Yang masih perlu disiapkan nanti:

- [ ] Pasang budget alert di Google Cloud Billing, jika belum.
- [ ] Jalankan `flutterfire configure` untuk mendaftarkan app Android.
- [ ] Tambahkan SHA-1 dan SHA-256 kunci signing Android di Project settings. Ini wajib untuk login Google di Android.
- [ ] Cloud Messaging → buat Web Push certificate (VAPID key) untuk notifikasi di web.
- [ ] App Check untuk melindungi tryout dari akses di luar aplikasi.
- [ ] Domain sendiri di Hosting. Tambahkan juga ke Authentication → Settings → Authorized domains.
