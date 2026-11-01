/** Garis waktu halaman Perjalanan. `foto` adalah path di src/assets/foto/. */

export interface Peristiwa {
  tahun: string;
  isi: string;
  foto?: string;
}

export const perjalanan: Peristiwa[] = [
  {
    tahun: "2016",
    isi: "K3 dibentuk pada 8 Juli, sebagai reaksi atas ketimpangan pendidikan dan literasi di Lamongan.",
  },
  {
    tahun: "2017",
    isi: "Launching pada 19 Januari di SMAN 1 Sukodadi, bertema \"Bergerak Bersama Membangun Bangsa\", bersama Relawan Literasi, MASIS, dan ekstrakurikuler Jurnalistik. Rangkaiannya berupa talkshow inspiratif untuk siswa.",
    foto: "sejarah/launching-2017-poster.jpg",
  },
  {
    tahun: "2017",
    isi: "Research Journalist Camp, 23-25 Desember di Jegulo, Tuban, bersama ekstrakurikuler KIR, Jurnalistik, dan Teater SMAN 1 Sukodadi.",
    foto: "sejarah/research-journalist-camp-sesi-danau.jpg",
  },
  {
    tahun: "2018",
    isi: "Seminar Ayo Kuliah 28 Januari, tema \"Kuliah, Siapa Takut?\", diikuti siswa dari berbagai sekolah di Lamongan.",
    foto: "seminar/seminar-2018-foto-panitia.jpg",
  },
  {
    tahun: "2018",
    isi: "Bimbingan belajar daring dan luring persiapan SBMPTN. Daring Senin sampai Sabtu, luring setiap Minggu.",
    foto: "bimbel/bimbel-2018-kelas-offline.jpg",
  },
  {
    tahun: "2018",
    isi: "Gerakan 1000 Baju Lebaran menyalurkan baju untuk 70 anak yatim piatu di Lamongan.",
  },
  {
    tahun: "2018",
    isi: "Liputan Radar Lamongan (Jawa Pos) berjudul \"Dana Patungan, Wujudkan Mimpi Anak Sekolah\".",
    foto: "liputan/radar-lamongan-dana-patungan.jpg",
  },
  {
    tahun: "Sampai 2019",
    isi: "Lebih dari 50 siswa dari daerah di Lamongan mendapat manfaat intensif selama dua tahun pertama. K3 tampil di talkshow Cakrawala BBS TV Surabaya dan menerbitkan buku Para Perebut Mimpi.",
    foto: "liputan/bbs-tv-cakrawala-judul.jpg",
  },
  {
    tahun: "2020",
    isi: "Ayo Berbagi tetap berjalan di masa pandemi, tersalurkan ke 69 anak yatim.",
    foto: "berbagi/belanja-baju-2020.jpg",
  },
  {
    tahun: "2021",
    isi: "Pelatihan Menulis Puisi secara daring, 8 Agustus.",
  },
  {
    tahun: "2022",
    isi: "Gerakan 1000 Baju Lebaran melalui Celengan Akhirat, bersama MASIS dan KIR SMAN 1 Sukodadi.",
    foto: "berbagi/label-celengan-akhirat-2022.jpg",
  },
  {
    tahun: "2024",
    isi: "Seminar Ayo Kuliah 7 Januari. Bimbel SNBT 18 Maret - 27 April. Ayo Berbagi menyalurkan 123 baju untuk 104 anak. Webinar \"Kiat Mudah Tembus SKD CPNS\" 13 Oktober.",
    foto: "seminar/seminar-2024-foto-bersama.jpg",
  },
  {
    tahun: "2025",
    isi: "Seminar Ayo Kuliah 25 Januari. Bimbel UTBK-SNBT 10 Maret - 20 April untuk 74 peserta. Graduation & Gear Up 21 April. 137 baju lebaran tersalurkan. Aplikasi Mandu dirilis.",
    foto: "bimbel/bimbel-2025-poster-graduation.jpg",
  },
  {
    tahun: "2026",
    isi: "Seminar Ayo Kuliah 24 Januari di SMAN 1 Dukun, Gresik. Bimbel Ayo Kuliah 2 Maret - 12 April menjangkau 171 siswa dari 50 sekolah dan 15 kota. Portal Bimbel dan tryout daring digunakan.",
    foto: "bimbel/bimbel-2026-slide-jangkauan.jpg",
  },
];
