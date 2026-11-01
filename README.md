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
| Nama, tagline, angkatan bimbel, tautan pendaftaran, tautan portal, media sosial | `apps/web/src/config/site.ts` |
| Visi, misi, dan pengurus | bagian atas `apps/web/src/pages/tentang.astro` |
| Fasilitas dan FAQ bimbel | bagian atas `apps/web/src/pages/bimbel.astro` |
| Kegiatan (seminar, tryout, dan lain-lain) | satu file Markdown per kegiatan di `apps/web/src/content/kegiatan/` |

Tautan di `site.ts` yang dibiarkan kosong tidak ditampilkan. Begitu juga visi, misi, dan pengurus yang masih kosong.

Untuk menambah kegiatan, salin `contoh-seminar.md`, ganti isinya, lalu hapus `draft: true`. Nama file menjadi alamat halaman, misalnya `seminar-maret.md` menjadi `/kegiatan/seminar-maret`. Poster opsional dan disimpan di folder yang sama. Kegiatan dengan `draft: true` hanya muncul saat `npm run dev`.

### Halaman

| URL | Isi |
|---|---|
| `/` | Beranda: program, alur bimbel, kegiatan terbaru, info portal |
| `/tentang` | Tentang komunitas |
| `/bimbel` | Bimbel #AyoKuliah: fasilitas, aturan kelas, pendaftaran, FAQ |
| `/kegiatan` | Daftar kegiatan |
| `/kegiatan/<nama>` | Detail kegiatan |

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
