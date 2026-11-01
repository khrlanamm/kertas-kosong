/**
 * Isi halaman Galeri. `foto` adalah path di src/assets/foto/.
 * Foto penyaluran bantuan yang memperlihatkan wajah anak sengaja tidak dimasukkan.
 */

export interface FotoGaleri {
  foto: string;
  ket: string;
}

export interface Album {
  id: string;
  judul: string;
  foto: FotoGaleri[];
}

export const album: Album[] = [
  {
    id: "seminar",
    judul: "Seminar Ayo Kuliah",
    foto: [
      { foto: "seminar/seminar-2026-foto-bersama-aula.jpg", ket: "Foto bersama di aula SMAN 1 Dukun, Gresik, 2026" },
      { foto: "seminar/seminar-2026-sesi-pemateri.jpg", ket: "Sesi pemateri, 2026" },
      { foto: "seminar/seminar-2026-peserta-menyimak.jpg", ket: "Peserta menyimak materi, 2026" },
      { foto: "seminar/seminar-2026-suasana-panggung.jpg", ket: "Suasana panggung dan peserta, 2026" },
      { foto: "seminar/seminar-2026-registrasi-peserta.jpg", ket: "Registrasi peserta di meja panitia, 2026" },
      { foto: "seminar/seminar-2026-meja-registrasi.jpg", ket: "Meja registrasi dengan roll banner Program Ayo Kuliah, 2026" },
      { foto: "seminar/seminar-2026-penyerahan-plakat.jpg", ket: "Penyerahan plakat kepada pemateri, 2026" },
      { foto: "seminar/seminar-2026-tim-panitia-dan-banner.jpg", ket: "Panitia di samping roll banner, 2026" },
      { foto: "seminar/seminar-2026-foto-bersama-lebar.jpg", ket: "Foto bersama, sudut lebar, 2026" },
      { foto: "seminar/seminar-2026-dok-04.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2026-dok-07.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2026-dok-15.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2026-dok-23.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2026-dok-28.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2026-dok-34.jpg", ket: "Dokumentasi Seminar Ayo Kuliah di SMAN 1 Dukun, 2026" },
      { foto: "seminar/seminar-2025-sesi-materi.jpg", ket: "Sesi materi di depan peserta, 2025" },
      { foto: "seminar/seminar-2025-panitia-di-depan-panggung.jpg", ket: "Panitia berkaos K3 di depan panggung, 2025" },
      { foto: "seminar/seminar-2025-penyerahan-sertifikat.jpg", ket: "Penyerahan sertifikat kepada pemateri, 2025" },
      { foto: "seminar/seminar-2025-foto-bersama-peserta.jpg", ket: "Foto bersama peserta dan panitia, 2025" },
      { foto: "seminar/seminar-2024-foto-bersama.jpg", ket: "Foto bersama di SMAN 1 Sukodadi, 2024" },
      { foto: "seminar/seminar-2024-sesi-materi.jpg", ket: "Sesi materi di kelas SMAN 1 Sukodadi, 2024" },
      { foto: "seminar/seminar-2018-foto-panitia.jpg", ket: "Panitia dan relawan Seminar Ayo Kuliah, sekitar 2018" },
    ],
  },
  {
    id: "bimbel",
    judul: "Bimbel Ayo Kuliah",
    foto: [
      { foto: "bimbel/bimbel-2026-slide-jangkauan.jpg", ket: "Jangkauan Bimbel Ayo Kuliah 2026: 171 siswa, 50 sekolah, 15 kota" },
      { foto: "bimbel/bimbel-2026-slide-progres-tryout.jpg", ket: "Progres pembelajaran 2026: rerata tryout naik 6 persen" },
      { foto: "bimbel/bimbel-2026-slide-konsolidasi-pembukaan.jpg", ket: "Konsolidasi peserta dan pembukaan, 2026" },
      { foto: "bimbel/poster-bimbel-ayo-kuliah-2026.jpg", ket: "Poster Bimbel Ayo Kuliah 2026" },
      { foto: "bimbel/bimbel-2026-banner-graduation.jpg", ket: "Graduation & Gear Up Bimbel Ayo Kuliah 2026" },
      { foto: "bimbel/bimbel-2025-kelas-online-papan-tulis.jpg", ket: "Tentor menjelaskan soal di kelas daring, 2025" },
      { foto: "bimbel/bimbel-2025-poster-graduation.jpg", ket: "Poster Graduation & Gear Up, 21 April 2025" },
      { foto: "bimbel/bimbel-2024-offline-foto-bersama.jpg", ket: "Foto bersama pertemuan luring, April 2024" },
      { foto: "bimbel/poster-bimbel-snbt-2024.jpg", ket: "Poster Bimbel SNBT 2024" },
      { foto: "bimbel/bimbel-2024-poster-closing-party.jpg", ket: "Poster Closing Party Bimbel SNBT, 2 Mei 2024" },
      { foto: "bimbel/bimbel-offline-foto-bersama-kelas.jpg", ket: "Foto bersama di ruang kelas" },
      { foto: "bimbel/bimbel-2018-kelas-offline.jpg", ket: "Bimbingan belajar luring persiapan SBMPTN, 2018" },
      { foto: "bimbel/bimbel-2018-foto-bersama.jpg", ket: "Foto bersama bimbingan belajar luring, 2018" },
    ],
  },
  {
    id: "berbagi",
    judul: "Ayo Berbagi",
    foto: [
      { foto: "berbagi/celengan-akhirat-2026.jpg", ket: "Celengan Akhirat disiapkan sebelum Ramadan, 2026" },
      { foto: "berbagi/paket-baju-2026.jpg", ket: "Tumpukan paket baju lebaran, 2026" },
      { foto: "berbagi/mengemas-baju-2026.jpg", ket: "Relawan mengemas baju lebaran, 2026" },
      { foto: "berbagi/belanja-baju-2025.jpg", ket: "Relawan berbelanja baju lebaran, 2025" },
      { foto: "berbagi/label-celengan-akhirat-2022.jpg", ket: "Label Celengan Akhirat, kolaborasi K3 dengan MASIS dan KIR, 2022" },
      { foto: "berbagi/belanja-baju-2020.jpg", ket: "Relawan memilih baju lebaran, 2020" },
      { foto: "berbagi/belanja-baju-2020-2.jpg", ket: "Relawan memilih baju lebaran, 2020" },
      { foto: "berbagi/memilah-baju-2020.jpg", ket: "Relawan memilah baju, 2020" },
      { foto: "berbagi/persiapan-paket-2019.jpg", ket: "Persiapan paket bantuan, 2019" },
    ],
  },
  {
    id: "relawan",
    judul: "Relawan dan Komunitas",
    foto: [
      { foto: "relawan/pengurus-evaluasi-mei-2025.jpg", ket: "Anggota selepas rapat evaluasi, Mei 2025" },
      { foto: "relawan/silaturahmi-lebaran-2025.jpg", ket: "Kumpul anggota selepas Lebaran, April 2025" },
      { foto: "relawan/silaturahmi-lebaran-2025-2.jpg", ket: "Kumpul anggota selepas Lebaran, 2025" },
      { foto: "relawan/makan-bersama-grill-and-grow-2025.jpg", ket: "Makan bersama Grill & Grow, Juni 2025" },
      { foto: "relawan/pertemuan-januari-2025.jpg", ket: "Pertemuan anggota, Januari 2025" },
      { foto: "relawan/relawan-dan-roll-banner-sman1-dukun.jpg", ket: "Relawan di samping roll banner, SMAN 1 Dukun, 2026" },
      { foto: "relawan/relawan-dan-roll-banner-sman1-sukodadi.jpg", ket: "Relawan di samping roll banner, SMAN 1 Sukodadi, 2025" },
      { foto: "relawan/relawan-dan-peserta-semangat.jpg", ket: "Relawan bersama peserta, 2025" },
      { foto: "relawan/tim-k3-di-panggung.jpg", ket: "Tim K3 di panggung acara kepemudaan" },
      { foto: "relawan/produksi-kaos-k3.jpg", ket: "Proses menyablon kaos K3, 2025" },
      { foto: "relawan/merchandise-tumbler.jpg", ket: "Tumbler merchandise K3" },
      { foto: "relawan/kaos-k3-relawan-1.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-2.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-3.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-4.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-5.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-6.jpg", ket: "Relawan memakai kaos K3" },
      { foto: "relawan/kaos-k3-relawan-7.jpg", ket: "Relawan memakai kaos K3" },
    ],
  },
  {
    id: "masa-awal",
    judul: "Masa Awal 2017-2019",
    foto: [
      { foto: "sejarah/launching-2017-poster.jpg", ket: "Poster launching, 19 Januari 2017" },
      { foto: "sejarah/research-journalist-camp-2017-poster.jpg", ket: "Poster Research Journalist Camp 2017" },
      { foto: "sejarah/research-journalist-camp-sesi-danau.jpg", ket: "Sesi Research Journalist Camp di tepi danau, 2017" },
      { foto: "sejarah/goes-to-expo-campus.jpg", ket: "Komunitas Kertas Kosong Goes to Expo Campus" },
      { foto: "sejarah/adik-pejuang-lolos-sbmptn.jpg", ket: "Adik pejuang yang lolos SBMPTN" },
      { foto: "sejarah/kegiatan-relawan-kaos-biru.jpg", ket: "Relawan dan tamu kegiatan K3" },
      { foto: "menulis/adik-pejuang-juara-lomba-esai.jpg", ket: "Adik pejuang menjadi juara lomba esai" },
      { foto: "menulis/buku-para-perebut-mimpi.jpg", ket: "Buku Para Perebut Mimpi" },
    ],
  },
];

export const liputan = [
  {
    media: "BBS TV Surabaya",
    judul: "Talkshow Cakrawala: Mengenal Komunitas Kertas Kosong",
    foto: [
      { foto: "liputan/bbs-tv-cakrawala-studio.jpg", ket: "Talkshow Cakrawala di BBS TV Surabaya. Sumber: BBS TV" },
      { foto: "liputan/bbs-tv-cakrawala-judul.jpg", ket: "Tema Mengenal Komunitas Kertas Kosong. Sumber: BBS TV" },
      { foto: "liputan/bbs-tv-cakrawala-lebar.jpg", ket: "Talkshow Cakrawala, sudut lebar. Sumber: BBS TV" },
    ],
  },
  {
    media: "Radar Lamongan (Jawa Pos)",
    judul: "Dana Patungan, Wujudkan Mimpi Anak Sekolah",
    foto: [
      {
        foto: "liputan/radar-lamongan-dana-patungan.jpg",
        ket: "Dana Patungan, Wujudkan Mimpi Anak Sekolah, 2018. Sumber: Radar Lamongan (Jawa Pos)",
      },
    ],
  },
];
