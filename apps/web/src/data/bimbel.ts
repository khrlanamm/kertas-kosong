/** Isi halaman Bimbel Ayo Kuliah. */

export const materi = [
  "Penalaran Umum (PU)",
  "Pengetahuan dan Pemahaman Umum (PPU)",
  "Pemahaman Bacaan dan Menulis (PBM)",
  "Pengetahuan Kuantitatif (PK)",
  "Literasi dalam Bahasa Indonesia (LBI)",
  "Literasi dalam Bahasa Inggris",
  "Penalaran Matematika (PM)",
];

/** Data per angkatan. Isi `null` untuk angka yang belum terdata; baris itu tampil sebagai tanda pisah. */
export const angkatan = [
  {
    tahun: "2026",
    waktu: "2 Maret - 12 April",
    bentuk: "Daring lewat Zoom",
    kelas: "2 kelas",
    peserta: "171 siswa",
    tentor: "14 tentor",
    fasilitator: "14 fasilitator",
    durasi: "90 menit",
  },
  {
    tahun: "2025",
    waktu: "10 Maret - 20 April",
    bentuk: "Daring lewat Zoom",
    kelas: "3 kelas",
    peserta: "74 peserta",
    tentor: "21 tentor",
    fasilitator: "8 fasilitator",
    durasi: "75 menit",
  },
  {
    tahun: "2024",
    waktu: "18 Maret - 27 April",
    bentuk: "Daring dan luring (Sabtu, di SMAN 1 Sukodadi)",
    kelas: "6 kelas",
    peserta: null,
    tentor: null,
    fasilitator: null,
    durasi: "60 menit",
  },
];

export const caraKerja = [
  "Setiap tentor mengampu satu materi sesuai keahliannya, satu kali seminggu.",
  "Minggu 1 sampai 4 berisi penjelasan dan pembahasan soal seluruh submateri. Minggu 5 berfokus pada pembahasan dan latihan soal UTBK.",
  "Fasilitator mendampingi setiap kelas, mencatat presensi, dan menjaga komunikasi di grup.",
  "Kelas direkam, sehingga peserta yang berhalangan bisa menonton ulang lalu mengumpulkan abstrak.",
  "Tryout diadakan di awal dan menjelang akhir program untuk melihat perkembangan.",
  "Program ditutup dengan acara Graduation & Gear Up, berisi apresiasi dan penguatan mental sebelum tes.",
  "Peserta menyepakati kontrak belajar, termasuk ketentuan kehadiran.",
];

/** Alur program untuk stepper. Isinya sama dengan `caraKerja`. */
export const alurLimaMinggu = [
  { judul: "Minggu 1-4", isi: "Penjelasan dan pembahasan soal seluruh submateri. Setiap tentor mengampu satu materi sesuai keahliannya, satu kali seminggu.", lebar: 4 },
  { judul: "Minggu 5", isi: "Fokus pada pembahasan dan latihan soal UTBK.", lebar: 1 },
  { judul: "Penutupan", isi: "Graduation & Gear Up, berisi apresiasi dan penguatan mental sebelum tes.", lebar: 1 },
];

export const hasil = [
  {
    tahun: "2026",
    isi: "Rerata skor tryout naik 6 persen, dari 486,46 pada Tryout 1 menjadi 514,81 pada Tryout 2. 15 peserta tercatat lolos SNBT, yaitu di UNESA (7), Universitas Negeri Malang (2), UTM (2), ITERA, Universitas Jember, UPN Veteran Jawa Timur, dan Universitas Brawijaya.",
  },
  {
    tahun: "2025",
    isi: "15 peserta tercatat lolos UTBK-SNBT, yaitu di UNESA (5), UTM (3), UNAIR (2), ITS, Polije, PPNS, UNNES, dan Polinema.",
  },
  {
    tahun: "2024",
    isi: "Dari 18 alumni yang mengisi pendataan, 11 diterima lewat SNBT, 5 lewat jalur mandiri, dan 2 lewat SNBP, antara lain di ITS, Universitas Airlangga, Universitas Brawijaya, Universitas Negeri Malang, Universitas Jember, Universitas Trunojoyo Madura, dan UPN Veteran Jawa Timur.",
  },
];

export const jangkauan2026 = {
  ringkas: [
    { angka: "171", label: "siswa" },
    { angka: "50", label: "sekolah" },
    { angka: "15", label: "kota" },
  ],
  sebaran:
    "Sebanyak 74,3 persen peserta dari Gresik, 13,5 persen dari Lamongan, dan 12,3 persen dari kota lain, antara lain Surabaya, Jombang, Tuban, Bojonegoro, Probolinggo, Ponorogo, Banyumas, Bekasi, Depok, Jakarta Selatan, Bandar Lampung, Medan, dan Binjai.",
};

/** Sebaran peserta 2026. Persentase hanya tersedia untuk tiga kelompok ini. */
export const sebaran2026 = [
  { nama: "Gresik", persen: 74.3 },
  { nama: "Lamongan", persen: 13.5 },
  { nama: "Kota lain", persen: 12.3 },
];

/** 15 kota asal peserta 2026, untuk peta jangkauan. */
export const kotaJangkauan = [
  { nama: "Lamongan", lintang: -7.12, bujur: 112.42, jatim: true },
  { nama: "Gresik", lintang: -7.16, bujur: 112.65, jatim: true },
  { nama: "Surabaya", lintang: -7.26, bujur: 112.75, jatim: true },
  { nama: "Jombang", lintang: -7.55, bujur: 112.23, jatim: true },
  { nama: "Tuban", lintang: -6.9, bujur: 112.05, jatim: true },
  { nama: "Bojonegoro", lintang: -7.15, bujur: 111.88, jatim: true },
  { nama: "Probolinggo", lintang: -7.75, bujur: 113.22, jatim: true },
  { nama: "Ponorogo", lintang: -7.87, bujur: 111.46, jatim: true },
  { nama: "Banyumas", lintang: -7.51, bujur: 109.29, jatim: false },
  { nama: "Bekasi", lintang: -6.24, bujur: 106.99, jatim: false },
  { nama: "Depok", lintang: -6.4, bujur: 106.82, jatim: false },
  { nama: "Jakarta Selatan", lintang: -6.26, bujur: 106.81, jatim: false },
  { nama: "Bandar Lampung", lintang: -5.43, bujur: 105.26, jatim: false },
  { nama: "Medan", lintang: 3.59, bujur: 98.67, jatim: false },
  { nama: "Binjai", lintang: 3.6, bujur: 98.49, jatim: false },
];

/** Rerata skor tryout 2026. */
export const tryout2026 = [
  { label: "Tryout 1", skor: 486.46 },
  { label: "Tryout 2", skor: 514.81 },
];

/** Kampus peserta yang tercatat lolos. Sama dengan isi `hasil`. */
export const kampusLolos = [
  { tahun: "2026", kampus: "UNESA", jumlah: 7 },
  { tahun: "2026", kampus: "Universitas Negeri Malang", jumlah: 2 },
  { tahun: "2026", kampus: "UTM", jumlah: 2 },
  { tahun: "2026", kampus: "ITERA", jumlah: 1 },
  { tahun: "2026", kampus: "Universitas Jember", jumlah: 1 },
  { tahun: "2026", kampus: "UPN Veteran Jawa Timur", jumlah: 1 },
  { tahun: "2026", kampus: "Universitas Brawijaya", jumlah: 1 },
  { tahun: "2025", kampus: "UNESA", jumlah: 5 },
  { tahun: "2025", kampus: "UTM", jumlah: 3 },
  { tahun: "2025", kampus: "UNAIR", jumlah: 2 },
  { tahun: "2025", kampus: "ITS", jumlah: 1 },
  { tahun: "2025", kampus: "Polije", jumlah: 1 },
  { tahun: "2025", kampus: "PPNS", jumlah: 1 },
  { tahun: "2025", kampus: "UNNES", jumlah: 1 },
  { tahun: "2025", kampus: "Polinema", jumlah: 1 },
];

export const pesertaBimbel = {
  sasaran: "Siswa kelas XII SMA, SMK, dan sederajat, serta alumni yang ingin mengikuti UTBK-SNBT.",
  syarat: [
    "Mengikuti Instagram @komunitaskertaskosong.",
    "Mengisi formulir pendaftaran.",
    "Mengunggah surat motivasi atau esai.",
    "Berkomitmen mengikuti rangkaian bimbingan sampai selesai.",
  ],
  didapat: [
    "Program belajar intensif lebih dari satu bulan.",
    "Tentor UTBK berpengalaman dari seluruh Indonesia.",
    "Soal latihan lengkap.",
    "Tryout.",
    "Jejaring.",
  ],
  jadwal: "Pendaftaran biasanya dibuka Februari. Kami tidak menerima pendaftaran setelah pengumuman SNBP, jadi daftarkan dirimu lebih awal.",
};

export const faqBimbel = [
  {
    q: "Apakah bimbel dan seminarnya gratis?",
    a: "Ya. Seminar dan bimbel diselenggarakan gratis, tanpa biaya apa pun.",
  },
  {
    q: "Siapa yang boleh ikut?",
    a: "Siswa kelas XII SMA, SMK, dan sederajat, juga alumni yang akan mengikuti UTBK-SNBT, dari mana saja, karena kelasnya daring.",
  },
  {
    q: "Bagaimana kalau tidak bisa hadir di kelas?",
    a: "Sampaikan izin kepada fasilitator, lalu tonton rekaman dan kumpulkan abstrak. Peserta yang berkali-kali tidak hadir tanpa keterangan bisa dikeluarkan sesuai kontrak belajar.",
  },
  {
    q: "Kapan pendaftaran dibuka?",
    a: "Pendaftaran biasanya dibuka Februari dan diumumkan di Instagram @komunitaskertaskosong. Kami tidak menerima pendaftaran setelah pengumuman SNBP.",
  },
];
