# Kertas Kosong

Monorepo untuk website Komunitas Kertas Kosong dan Portal Bimbel #AyoKuliah. Semuanya memakai satu project Firebase: `kertas-kosong`.

Website: [kertas-kosong.web.app](https://kertas-kosong.web.app).

Portal lama, yang hanya berisi tautan, diarsipkan di branch [`arsip/portal-lama`](https://github.com/khrlanamm/kertas-kosong/tree/arsip/portal-lama).

## Struktur

```
apps/
  web/                  website komunitas (Astro + Tailwind CSS, statis)
  portal/               (menyusul) Portal Bimbel, Flutter untuk web dan Android
functions/              (menyusul) Cloud Functions, TypeScript, region asia-southeast2
firebase.json           hosting, rules, dan emulator
firestore.rules         aturan akses Firestore (saat ini semua ditutup)
firestore.indexes.json
storage.rules           aturan akses Cloud Storage (saat ini semua ditutup)
docs/architecture.md    keputusan arsitektur, rencana data, dan tahapan
```

Alasan memakai satu repo dan rencana lengkapnya ada di [docs/architecture.md](docs/architecture.md).

## Website (`apps/web`)

Butuh Node.js 22.23.4 atau lebih baru.

```sh
cd apps/web
npm install
npm run dev        # http://localhost:4321
npm run build      # cek tipe, lalu build ke apps/web/dist
```

Website tidak membaca Firestore dan tidak butuh file `.env`.

### Mengubah isi

| Yang diubah | Tempatnya |
|---|---|
| Nama, slogan, angkatan bimbel, tautan pendaftaran, tautan portal, media sosial, email | `apps/web/src/config/site.ts` |
| Tentang Kami: visi, misi, nilai, hambatan, sapaan | `apps/web/src/data/tentang.ts` |
| Garis waktu Perjalanan | `apps/web/src/data/perjalanan.ts` |
| Program #4AYO, Seminar Ayo Kuliah, Ayo Berbagi | `apps/web/src/data/program.ts` |
| Bimbel: materi, data per angkatan, hasil, syarat, FAQ | `apps/web/src/data/bimbel.ts` |
| Angka di Beranda dan halaman Dampak | `apps/web/src/data/dampak.ts` |
| Album galeri dan liputan media | `apps/web/src/data/galeri.ts` |
| Ayo Terlibat: tentor, fasilitator, donasi, FAQ | `apps/web/src/data/terlibat.ts` |
| Kegiatan (seminar, bimbel, dan lain-lain) | satu file Markdown per kegiatan di `apps/web/src/content/kegiatan/` |

Tautan di `site.ts` yang dibiarkan kosong tidak ditampilkan, misalnya WhatsApp, YouTube, dan formulir pendaftaran.

**Kegiatan baru:** salin `contoh-seminar.md`, ganti isinya, lalu hapus `draft: true`. Nama file menjadi alamat halaman, misalnya `seminar-ayo-kuliah-2027.md` menjadi `/kegiatan/seminar-ayo-kuliah-2027`. Kegiatan dengan `draft: true` hanya muncul saat `npm run dev`.

**Foto:** simpan di `apps/web/src/assets/foto/<album>/`, kecilkan dulu ke sisi terpanjang sekitar 1600 px, lalu sebutkan path-nya di file data, misalnya `"seminar/nama-foto.jpg"`. Website membuat ukuran kecil dan format WebP secara otomatis. Build gagal kalau path-nya salah, jadi gambar rusak tidak akan sampai tayang. Jangan memasang foto wajah anak penerima bantuan atau peserta kelas daring tanpa izin wali atau peserta.

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
| `/galeri` | Album foto dengan lightbox, dan liputan media |
| `/kegiatan`, `/kegiatan/<nama>` | Daftar dan detail kegiatan |
| `/ayo-terlibat` | Tentor relawan, fasilitator, peserta, donasi, kolaborasi |
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

Website tersedia di http://127.0.0.1:5002 dengan aturan hosting yang sama seperti produksi (URL bersih, redirect, dan cache). Emulator UI ada di http://127.0.0.1:4000.

### Deploy

```sh
firebase login
firebase deploy --only hosting                # build website lalu unggah
firebase deploy --only firestore              # rules dan index Firestore
firebase deploy --only storage                # rules Storage (setelah Storage diaktifkan)
```

`firebase deploy --only hosting` menjalankan `npm run build` di `apps/web` secara otomatis.

Saat domain sendiri sudah siap, build dengan alamat barunya supaya canonical URL, sitemap, dan pratinjau link memakai domain itu:

```sh
SITE_URL=https://domain-baru.id firebase deploy --only hosting
```

## Lisensi

Hak cipta dilindungi. Kode sumber dipublikasikan hanya untuk referensi. Lihat [LICENSE](LICENSE).
