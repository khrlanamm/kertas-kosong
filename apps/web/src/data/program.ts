/** Isi halaman Program #4AYO. Sumber: Community Profile K3 2026 dan dokumentasi kegiatan. */

export const pengantar4ayo =
  "Kami menjalankan model pemberdayaan empat pilar yang dikenal dengan #4AYO. Dimulai dari menumbuhkan minat baca, melatih kepenulisan kritis, mendampingi pendaftaran kuliah, hingga menciptakan siklus alumni yang saling memberdayakan.";

export const gerakan = [
  {
    slug: "ayo-membaca",
    nama: "Ayo Membaca",
    ringkas: "Menumbuhkan budaya baca yang sistematis lewat Sabu Saku: Satu Bulan Satu Buku.",
    kartu: "gerakan/gerakan-ayo-membaca.jpg",
  },
  {
    slug: "ayo-menulis",
    nama: "Ayo Menulis",
    ringkas: "Melatih berpikir kritis lewat Sabu Saka: Satu Bulan Satu Karya.",
    kartu: "gerakan/gerakan-ayo-menulis.jpg",
  },
  {
    slug: "ayo-kuliah",
    nama: "Ayo Kuliah",
    ringkas: "Seminar, bimbel gratis, tryout, konsultasi, sampai pendampingan hari tes.",
    kartu: "gerakan/gerakan-ayo-kuliah.jpg",
  },
  {
    slug: "ayo-berbagi",
    nama: "Ayo Berbagi",
    ringkas: "Gerakan 1000 Baju Lebaran untuk anak yatim dan sinergi alumni.",
    kartu: "gerakan/gerakan-ayo-berbagi.jpg",
  },
] as const;

export const kegiatanAyoKuliah = [
  { nama: "Seminar Ayo Kuliah", isi: "Seminar gratis tentang alasan kuliah, pemilihan jurusan, jalur masuk, dan beasiswa, dibawakan alumni dan mahasiswa." },
  { nama: "Bimbel gratis", isi: "Bimbingan belajar intensif persiapan UTBK-SNBT oleh tentor relawan." },
  { nama: "Tryout", isi: "Tryout untuk mengukur kesiapan dan memantau kemajuan peserta." },
  { nama: "Layanan konsultasi", isi: "Konsultasi jurusan, jalur masuk PTN dan PTS, serta informasi beasiswa." },
  { nama: "Home visit", isi: "Kunjungan ke rumah untuk membantu siswa yang terkendala restu orang tua atau masalah keluarga." },
  { nama: "Pendampingan tes", isi: "Bantuan informasi tempat tes dan penginapan selama tes masuk perguruan tinggi." },
];

export const seminar = [
  {
    tahun: "2018",
    waktu: "28 Januari",
    tema: "Kuliah, Siapa Takut?",
    materi: "Alasan harus kuliah, persiapan menuju kuliah, pemilihan jurusan, tips dan trik SBMPTN",
  },
  {
    tahun: "2024",
    waktu: "7 Januari, SMAN 1 Sukodadi",
    tema: "Inklusifitas Pendidikan Tinggi: Siapa Saja Bisa Berkuliah!",
    materi: "Tips dan trik lolos PTN, jalur masuk, dan beasiswa",
  },
  {
    tahun: "2025",
    waktu: "25 Januari, SMAN 1 Sukodadi",
    tema: "Membangun Asa, Menggapai Cita",
    materi: "Kenapa harus kuliah, menggali potensi diri dan jurusan, jalur kuliah dan beasiswa",
  },
  {
    tahun: "2026",
    waktu: "24 Januari, SMAN 1 Dukun, Gresik",
    tema: "Bersama Menata Diri untuk Mengejar Mimpi",
    materi: "Kenapa kita harus kuliah, kuliah dengan beasiswa, strategi memilih jurusan disertai tes minat bakat",
  },
];

export const alurBerbagi = [
  { judul: "Celengan Akhirat", isi: "Celengan dibagikan kepada para donatur, dan donasi juga bisa disalurkan secara digital." },
  { judul: "Data penerima", isi: "Data penerima dikumpulkan dari relawan di berbagai daerah." },
  { judul: "Buka celengan", isi: "Celengan biasanya dibuka bersama-sama, diiringi buka puasa bersama." },
  { judul: "Belanja dan pengemasan", isi: "Baju dibeli dan dikemas sesuai ukuran tiap anak." },
  { judul: "Penyaluran langsung", isi: "Paket diantar ke rumah penerima menjelang Lebaran." },
];

/** Angka tahun lain belum terdata, jadi tidak ditampilkan. */
export const capaianBerbagi = [
  { tahun: "2018", isi: "Baju untuk 70 anak yatim piatu" },
  { tahun: "2020", isi: "69 anak yatim" },
  { tahun: "2024", isi: "123 baju untuk 104 anak" },
  { tahun: "2025", isi: "137 baju" },
];
