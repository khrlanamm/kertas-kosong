# Kertas Kosong

Monorepo untuk website Komunitas Kertas Kosong dan Portal Bimbel #AyoKuliah. Semuanya memakai satu project Firebase: `kertas-kosong`.

- Website: [kertas-kosong.web.app](https://kertas-kosong.web.app)
- Portal Bimbel: [kertas-kosong-portal.web.app](https://kertas-kosong-portal.web.app)

Portal lama, yang hanya berisi tautan, diarsipkan di branch [`arsip/portal-lama`](https://github.com/khrlanamm/kertas-kosong/tree/arsip/portal-lama).

## Struktur

```
apps/
  web/                  website komunitas (Astro + Tailwind CSS, statis)
  portal/               Portal Bimbel (Flutter; web dulu, Android menyusul)
functions/              Cloud Functions untuk tryout dan pendaftaran (TypeScript, region asia-southeast2)
functions/scripts/      skrip admin: sinkron media dan penetapan admin
secrets/                kredensial lokal, tidak masuk git
firebase.json           dua situs hosting, functions, rules, dan emulator
firestore.rules         aturan akses Firestore (peran siswa/admin, soal hanya untuk admin)
firestore.indexes.json
storage.rules           aturan akses Cloud Storage (gambar soal)
docs/architecture.md    keputusan arsitektur dan tahapan
docs/portal.md          fitur portal, tipe soal UTBK, pendaftaran, pengawasan, cara menjalankan, dan deploy
```

Alasan memakai satu repo dan rencana lengkapnya ada di [docs/architecture.md](docs/architecture.md). Detail Portal Bimbel ada di [docs/portal.md](docs/portal.md).

## Website (`apps/web`)

Butuh Node.js 22.23.4 atau lebih baru.

```sh
cd apps/web
npm install
npm run dev        # http://localhost:4321
npm run build      # cek tipe, lalu build ke apps/web/dist
```

Website tidak membaca Firestore dan tidak butuh file `.env`.

### Media

Repo ini publik, jadi foto dan gambar website tidak disimpan di git. Semuanya ada di Firebase Storage (`website/`, tertutup untuk klien). `npm run dev` dan `npm run build` mengunduhnya otomatis ke `apps/web/src/assets/` dan `apps/web/public/og.jpg`, dan Astro menyajikannya lewat Firebase Hosting.

Syaratnya:

1. `secrets/firebase-adminsdk.json` ada. Unduh dari Firebase Console → Project settings → Service accounts. Folder `secrets/` tidak masuk git.
2. Dependensi Functions terpasang: `npm --prefix functions install`.

Setelah menambah atau mengganti foto, unggah dengan `npm run media:dorong` di `apps/web`, lalu commit `apps/web/media.txt` yang ikut diperbarui. Berkas itu daftar media yang dipakai website. Build hanya mengunduh berkas di daftar ini, jadi foto yang sudah dikeluarkan tidak ikut tayang walaupun masih ada di Storage. Untuk menghapusnya sekaligus dari Storage, jalankan `npm run media:dorong -- --hapus`.

### Mengubah isi

| Yang diubah | Tempatnya |
|---|---|
| Nama, slogan, angkatan bimbel, tautan pendaftaran, tautan portal, media sosial, email | `apps/web/src/config/site.ts` |
| Tentang Kami: visi, misi, nilai, hambatan, sapaan | `apps/web/src/data/tentang.ts` |
| Garis waktu Perjalanan | `apps/web/src/data/perjalanan.ts` |
| Program #4AYO, Seminar Ayo Kuliah, Ayo Berbagi, grid 1000 baju, alur lima langkah | `apps/web/src/data/program.ts` |
| Bimbel: materi, data per angkatan, peta jangkauan, grafik tryout, daftar kampus, hasil, syarat, FAQ | `apps/web/src/data/bimbel.ts` |
| Angka di Beranda dan halaman Dampak | `apps/web/src/data/dampak.ts` |
| Foto galeri, album, tahun, dan liputan media | `apps/web/src/data/galeri.ts` |
| Tumpukan foto di Beranda | `momen` di `apps/web/src/pages/index.astro` |
| Ayo Terlibat: tentor, fasilitator, donasi, FAQ | `apps/web/src/data/terlibat.ts` |
| Kegiatan (seminar, bimbel, dan lain-lain) | satu file Markdown per kegiatan di `apps/web/src/content/kegiatan/` |

Tautan di `site.ts` yang dibiarkan kosong tidak ditampilkan, misalnya WhatsApp, YouTube, dan formulir pendaftaran.

**Kegiatan baru:** salin `contoh-seminar.md`, ganti isinya, lalu hapus `draft: true`. Nama file menjadi alamat halaman, misalnya `seminar-ayo-kuliah-2027.md` menjadi `/kegiatan/seminar-ayo-kuliah-2027`. Kegiatan dengan `draft: true` hanya muncul saat `npm run dev`.

**Gerak dan interaksi:** efek umum ada di `apps/web/src/scripts/gerak.ts`. Tambahkan `data-muncul` supaya elemen masuk saat terlihat, `data-urut` supaya anak-anaknya masuk bergantian, dan `data-hitung="171"` supaya angka menghitung naik. Tab memakai `apps/web/src/scripts/tab.ts`. Semua efek otomatis mati kalau pengunjung meminta gerak dikurangi, dan seluruh isi tetap tampil tanpa JavaScript.

**Foto:** simpan di `apps/web/src/assets/foto/<album>/`, kecilkan dulu ke sisi terpanjang sekitar 1600 px, lalu sebutkan path-nya di file data, misalnya `"seminar/nama-foto.jpg"`. Unggah dengan `npm run media:dorong`. Website membuat ukuran kecil dan format WebP secara otomatis. Build gagal kalau path-nya salah, jadi gambar rusak tidak akan sampai tayang. Jangan memasang foto wajah anak penerima bantuan atau peserta kelas daring tanpa izin wali atau peserta.

### Halaman

| URL | Isi |
|---|---|
| `/` | Beranda: slogan, angka singkat, mengapa kami ada, #4AYO, bimbel, kegiatan terbaru |
| `/tentang` | Tentang Kami: makna nama, hambatan, visi, misi, nilai, siklus alumni |
| `/perjalanan` | Garis waktu sejak 2016 |
| `/program` | Gerakan #4AYO |
| `/program/ayo-membaca`, `/ayo-menulis`, `/ayo-kuliah`, `/ayo-berbagi` | Detail tiap gerakan |
| `/bimbel` | Bimbel Ayo Kuliah: jangkauan, materi, cara kerja, data per angkatan, hasil, pendaftaran, FAQ |
| `/dampak` | Capaian per tahun |
| `/karya-digital` | Portal Bimbel, Mandu, Sabu Saku |
| `/galeri` | Foto pilihan dengan filter album dan tahun, lightbox, dan liputan media |
| `/kegiatan`, `/kegiatan/<nama>` | Daftar dan detail kegiatan |
| `/ayo-terlibat` | Pilihan peran: siswa, tentor dan fasilitator, donatur, mitra |
| `/kontak` | Email, Instagram, LinkedIn, lokasi |
| `/privasi` | Kebijakan privasi dan cara meminta foto diturunkan |

Alamat portal lama `/portal-bimbel` dan `/tryout` dialihkan (301) ke `/bimbel`.

## Firebase

Pasang Firebase CLI sekali: `npm install -g firebase-tools`.

### Emulator lokal

Emulator berjalan tanpa login dan tanpa menyentuh data asli:

```sh
npm --prefix apps/web run build
firebase emulators:start --project demo-kertas-kosong
```

Website tersedia di http://127.0.0.1:5002 dengan aturan hosting yang sama seperti produksi (URL bersih, redirect, dan cache). Portal (hasil `flutter build web --dart-define-from-file=env/emulator.json` di `apps/portal`) ada di http://127.0.0.1:5007, dan Emulator UI di http://127.0.0.1:4000. Sebelum menjalankan emulator, pasang dependensi Functions sekali: `npm --prefix functions install`.

### Deploy

```sh
firebase login
firebase deploy --only hosting:kertas-kosong           # website
firebase deploy --only hosting:kertas-kosong-portal    # portal (butuh apps/portal/env/produksi.json)
firebase deploy --only functions,firestore,storage     # backend portal
```

Deploy memakai `firebase login` dengan akun pemilik project. Service account di `secrets/` hanya untuk media dan data, karena perannya tidak mencakup deploy.

Deploy website menjalankan `npm run build` di `apps/web` secara otomatis, dan deploy portal menjalankan `flutter build web`. Langkah persiapan portal (Blaze, Authentication, Storage, situs hosting kedua, admin pertama) ada di [docs/portal.md](docs/portal.md#menayangkan).

Saat domain sendiri sudah siap, build dengan alamat barunya supaya canonical URL, sitemap, dan pratinjau link memakai domain itu:

```sh
SITE_URL=https://domain-baru.id firebase deploy --only hosting:kertas-kosong
```

## Lisensi

Hak cipta dilindungi. Kode sumber dipublikasikan hanya untuk referensi. Lihat [LICENSE](LICENSE).
