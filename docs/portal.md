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

**Program, pendaftaran, dan jadwal**
- Admin membuat program **Seminar** atau **Bimbel** dengan pengaturan berikut:
  - periode pendaftaran (WIB) dan kuota;
  - verifikasi panitia, atau langsung diterima;
  - waktu dan tempat acara (seminar);
  - daftar kelas (bimbel, bawaan A dan B).
- Data pendaftaran sesuai permintaan:

  | Program | Data |
  |---|---|
  | Seminar | nama, kelas, sekolah, email, nomor HP, alamat, kota, serta 1-3 pilihan jurusan dan kampus |
  | Bimbel | semua data seminar, ditambah tanggal lahir dan pertanyaan apakah siswa eligible SNBP. Nomor pendaftaran SNBP wajib diisi jika jawabannya "ya" |

- Data yang sudah pernah diisi dipakai ulang. Siswa yang sudah mendaftar seminar mendapati formulir bimbelnya sudah terisi, dan cukup menambah data pelengkap.
- Pendaftaran diproses Cloud Function `daftarProgram`, yang menjaga periode, kuota, dan validasi data. Siswa bisa mengubah data atau membatalkan pendaftaran selama periode masih dibuka dan panitia belum memutuskan.
- Admin mengelola pendaftar di satu tabel:
  - terima atau tolak, satu per satu atau "Terima semua yang menunggu";
  - pilih kelas per siswa, atau tekan **Bagi kelas otomatis** untuk membagi rata ke kelas A/B sesuai urutan mendaftar;
  - beri catatan panitia yang terlihat oleh siswa;
  - unduh CSV.
- Admin mengatur jadwal bimbel per pertemuan: materi, tanggal, jam (WIB), kelas (semua, A, atau B), tautan Zoom, dan catatan.
- Siswa yang diterima melihat jadwal kelasnya di beranda (pertemuan terdekat) dan di halaman **Jadwal bimbel**, lengkap dengan tombol masuk kelas daring. Siswa yang belum diterima tidak bisa membaca jadwal, karena isinya tautan kelas.
- Tryout bisa dibatasi untuk peserta yang diterima di program tertentu, dan dicek di server.

**Pengawasan saat mengerjakan tryout** (bisa diatur per tryout)
- **Tanda air** berisi nama, email, dan waktu peserta di seluruh area soal, sehingga foto atau screenshot yang tersebar bisa dilacak.
- **Soal tidak bisa disalin:**
  - teks tidak bisa diblok;
  - salin (Ctrl+C) dan klik kanan diblokir;
  - cetak (Ctrl+P) diblokir, dan halaman tetap kosong jika dicetak lewat menu browser.
- **Soal ditutup** saat peserta pindah tab, pindah aplikasi, atau meninggalkan jendela. Untuk melanjutkan, peserta harus menekan tombol, dan kejadiannya tercatat.
- **Dicatat sebagai pelanggaran:**
  - pindah tab atau jendela;
  - mencoba menyalin;
  - menekan tombol Print Screen (clipboard juga dikosongkan, jika browser mengizinkan);
  - membuka alat pengembang;
  - keluar dari layar penuh (jika layar penuh diwajibkan).
- **Opsi wajib layar penuh**, dan **kumpulkan otomatis** setelah 3, 5, atau 10 pelanggaran.
- **Admin melihat jumlah pelanggaran** setiap peserta di tab Hasil (juga di CSV), beserta rincian jenis dan waktu tiap kejadian.
- **Catatan tidak bisa dihapus** peserta: rules hanya mengizinkan jumlahnya bertambah.

Batasannya: di browser, tangkapan layar tidak bisa diblokir sepenuhnya, karena itu fitur sistem operasi. Begitu juga foto dari HP lain. Pengawasan web menyulitkan, mendeteksi, dan membuat bocoran bisa dilacak. Pemblokiran penuh tersedia di aplikasi Android lewat `FLAG_SECURE`, yang membuat layar tryout tidak bisa di-screenshot atau direkam.

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

- Data pendaftar hanya bisa dibaca pemiliknya dan admin. Pendaftar hanya bisa ditulis lewat Cloud Function, dan admin hanya bisa mengubah status, kelas, dan catatan.

Tes otomatisnya ada di `functions/test`:

| Tes | Isi | Perintah |
|---|---|---|
| Penilaian dan validasi | Logika penilaian dan validasi data pendaftaran (unit test) | `npm test` |
| Rules dan alur | Rules Firestore, alur ujian, pendaftaran, akses jadwal, dan catatan pelanggaran di emulator | `npm run test:emulator` |

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

Portal sudah tayang di [kertas-kosong-portal.web.app](https://kertas-kosong-portal.web.app). Konfigurasi Firebase yang sudah diterapkan:

| Layanan | Pengaturan |
|---|---|
| Paket | Blaze |
| Authentication | Google dan Email/Password, domain portal sudah diizinkan |
| Firestore | `asia-southeast2` |
| Storage | `kertas-kosong.firebasestorage.app`, `asia-southeast2` |
| Hosting | situs `kertas-kosong` (website) dan `kertas-kosong-portal` (portal) |
| Functions | `asia-southeast2`, Node.js 22 |

Untuk deploy dari komputer baru:

1. Masuk dengan akun pemilik project: `firebase login`.
2. Salin `apps/portal/env/produksi.contoh.json` menjadi `apps/portal/env/produksi.json`, lalu isi dari Project settings → Your apps → Web app. Berkas ini tidak masuk git.
3. Taruh `secrets/firebase-adminsdk.json` untuk media website.
4. Pasang dependensi: `npm --prefix functions install` dan `npm --prefix apps/web install`.
5. Bangun portal sekali, karena Firebase memeriksa foldernya sebelum deploy:
   ```sh
   cd apps/portal && flutter build web --release --dart-define-from-file=env/produksi.json && cd ../..
   ```
6. Deploy:
   ```sh
   firebase deploy --only functions,firestore,storage,hosting
   ```

Admin pertama: masuk ke portal, lengkapi profil, lalu jalankan:

```sh
node functions/scripts/jadikan-admin.mjs email@contoh.id
```

Setelah itu admin lain bisa diatur dari menu Pengguna di portal.

Jika gambar soal tidak tampil, portal memuatnya lewat elemen `<img>` sebagai cadangan. Untuk performa terbaik, atur CORS bucket Storage seperti dijelaskan di [dokumentasi Firebase](https://firebase.google.com/docs/storage/web/download-files#cors_configuration).

## Pendaftaran: keputusan yang diambil

Pendaftaran pindah dari Google Form ke portal. Keputusan pengurus:

- **Seminar dan bimbel didaftarkan lewat portal.** Seminar langsung diterima, bimbel diverifikasi panitia.
- **Data seminar:** nama, kelas, sekolah, email, nomor HP, alamat, serta minat jurusan dan kampus.
- **Data bimbel:** data seminar, ditambah tanggal lahir dan status eligible SNBP. Nomor SNBP diisi jika eligible.
- **Pembagian kelas** (biasanya A dan B) dilakukan admin di portal.
- **Jadwal bimbel** diatur admin dan dilihat siswa di portal.

Sesuai UU Pelindungan Data Pribadi, portal tidak meminta unggahan berkas identitas. Data pendaftar hanya bisa dibaca admin dan pemiliknya. Tetapkan juga kapan data pendaftar dihapus setelah program selesai.

## Rencana berikutnya

1. Impor soal massal dari spreadsheet, supaya 160 soal tidak diketik satu per satu.
2. Notifikasi email atau WhatsApp saat pendaftaran diterima.
3. Rekaman kelas dan presensi, menggantikan tautan di portal lama.
4. Versi Android, notifikasi FCM (pengingat tryout), dan `FLAG_SECURE` di layar tryout.
5. App Check untuk melindungi Functions dan Firestore dari akses di luar aplikasi.
