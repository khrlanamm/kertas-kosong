/**
 * Isi halaman Galeri, sudah dikurasi: satu foto untuk satu momen, tanpa poster dan slide.
 * `foto` adalah path di src/assets/foto/. Kosongkan `tahun` kalau tahunnya belum pasti.
 * Foto penyaluran bantuan yang memperlihatkan wajah anak sengaja tidak dimasukkan.
 */

export interface FotoGaleri {
  foto: string;
  ket: string;
  tahun?: string;
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
      { foto: "seminar/seminar-2026-foto-bersama-aula.jpg", ket: "Foto bersama di aula SMAN 1 Dukun, Gresik", tahun: "2026" },
      { foto: "seminar/seminar-2026-peserta-bertanya.jpg", ket: "Peserta angkat bicara di tengah sesi", tahun: "2026" },
      { foto: "seminar/seminar-2026-di-tengah-peserta.jpg", ket: "Bicara dari tengah peserta", tahun: "2026" },
      { foto: "seminar/seminar-2026-peserta-lesehan.jpg", ket: "Peserta menyimak sambil lesehan di aula", tahun: "2026" },
      { foto: "seminar/seminar-2026-sambutan-panggung.jpg", ket: "Sambutan di podium, disaksikan pemateri dan panitia", tahun: "2026" },
      { foto: "seminar/seminar-2026-pesan-mungkin.jpg", ket: "Satu kata di layar: mungkin", tahun: "2026" },
      { foto: "seminar/seminar-2026-peserta-putra.jpg", ket: "Peserta di barisan putra", tahun: "2026" },
      { foto: "seminar/seminar-2026-registrasi-peserta.jpg", ket: "Peserta mengantre registrasi di meja panitia", tahun: "2026" },
      { foto: "seminar/seminar-2026-penyerahan-plakat.jpg", ket: "Penyerahan plakat kepada pemateri", tahun: "2026" },
      { foto: "seminar/seminar-2026-tim-panitia-dan-banner.jpg", ket: "Panitia di samping roll banner", tahun: "2026" },
      { foto: "seminar/seminar-2025-sesi-materi.jpg", ket: "Sesi materi di depan peserta", tahun: "2025" },
      { foto: "seminar/seminar-2025-panitia-di-depan-panggung.jpg", ket: "Panitia berkaos K3 di depan panggung", tahun: "2025" },
      { foto: "seminar/seminar-2024-foto-bersama.jpg", ket: "Foto bersama di SMAN 1 Sukodadi", tahun: "2024" },
    ],
  },
  {
    id: "bimbel",
    judul: "Bimbel Ayo Kuliah",
    foto: [
      { foto: "bimbel/bimbel-2024-kelas-luring.jpg", ket: "Suasana kelas luring di SMAN 1 Sukodadi", tahun: "2024" },
      { foto: "bimbel/bimbel-2024-tentor-menulis.jpg", ket: "Tentor menulis pembahasan di papan tulis", tahun: "2024" },
      { foto: "bimbel/bimbel-2024-tentor-mengajar.jpg", ket: "Tentor menjelaskan materi di kelas luring", tahun: "2024" },
      { foto: "bimbel/bimbel-2024-peserta-menyimak.jpg", ket: "Peserta mengikuti pembahasan soal", tahun: "2024" },
      { foto: "bimbel/bimbel-2024-offline-foto-bersama.jpg", ket: "Foto bersama pertemuan luring", tahun: "2024" },
      { foto: "bimbel/bimbel-2025-kelas-online-papan-tulis.jpg", ket: "Tentor menjelaskan soal di kelas daring", tahun: "2025" },
      { foto: "bimbel/bimbel-2018-kelas-offline.jpg", ket: "Bimbingan belajar luring persiapan SBMPTN", tahun: "2018" },
      { foto: "bimbel/bimbel-2018-foto-bersama.jpg", ket: "Foto bersama bimbingan belajar luring", tahun: "2018" },
    ],
  },
  {
    id: "berbagi",
    judul: "Ayo Berbagi",
    foto: [
      { foto: "berbagi/celengan-akhirat-2026.jpg", ket: "Celengan Akhirat disiapkan sebelum Ramadan", tahun: "2026" },
      { foto: "berbagi/celengan-terkumpul-2026.jpg", ket: "Celengan yang kembali dari para donatur", tahun: "2026" },
      { foto: "berbagi/buka-bersama-2026.jpg", ket: "Buka puasa bersama saat membuka celengan", tahun: "2026" },
      { foto: "berbagi/mengemas-baju-2026.jpg", ket: "Relawan mengemas baju lebaran", tahun: "2026" },
      { foto: "berbagi/penyaluran-tangan-2026.jpg", ket: "Paket baju diserahkan langsung di depan rumah", tahun: "2026" },
      { foto: "berbagi/belanja-baju-2020.jpg", ket: "Memilih baju lebaran di masa pandemi", tahun: "2020" },
      { foto: "berbagi/memilah-baju-2020.jpg", ket: "Relawan memilah baju", tahun: "2020" },
      { foto: "berbagi/persiapan-paket-2019.jpg", ket: "Persiapan paket bantuan", tahun: "2019" },
    ],
  },
  {
    id: "relawan",
    judul: "Relawan dan Komunitas",
    foto: [
      { foto: "relawan/pengurus-evaluasi-mei-2025.jpg", ket: "Anggota selepas rapat evaluasi", tahun: "2025" },
      { foto: "relawan/silaturahmi-lebaran-2025.jpg", ket: "Kumpul anggota selepas Lebaran", tahun: "2025" },
      { foto: "relawan/makan-bersama-grill-and-grow-2025.jpg", ket: "Makan bersama Grill & Grow", tahun: "2025" },
      { foto: "relawan/pertemuan-januari-2025.jpg", ket: "Pertemuan anggota", tahun: "2025" },
      { foto: "relawan/produksi-kaos-k3.jpg", ket: "Proses menyablon kaos K3", tahun: "2025" },
      { foto: "relawan/relawan-dan-roll-banner-sman1-dukun.jpg", ket: "Relawan di samping roll banner, SMAN 1 Dukun", tahun: "2026" },
      { foto: "relawan/relawan-dan-roll-banner-sman1-sukodadi.jpg", ket: "Relawan di depan mural SMAN 1 Sukodadi", tahun: "2025" },
      { foto: "relawan/kaos-k3-relawan-1.jpg", ket: "Relawan memakai kaos K3", tahun: "2025" },
      { foto: "relawan/kaos-k3-relawan-7.jpg", ket: "Relawan memakai kaos K3", tahun: "2026" },
    ],
  },
  {
    id: "masa-awal",
    judul: "Masa Awal 2017-2019",
    foto: [
      { foto: "sejarah/research-journalist-camp-sesi-danau.jpg", ket: "Sesi Research Journalist Camp di tepi danau", tahun: "2017" },
      { foto: "seminar/seminar-2018-foto-panitia.jpg", ket: "Panitia dan relawan Seminar Ayo Kuliah", tahun: "2018" },
      { foto: "sejarah/adik-pejuang-lolos-sbmptn.jpg", ket: "Adik pejuang yang lolos SBMPTN", tahun: "2018" },
      { foto: "menulis/adik-pejuang-juara-lomba-esai.jpg", ket: "Adik pejuang menjadi juara lomba esai", tahun: "2018" },
      { foto: "sejarah/goes-to-expo-campus.jpg", ket: "Komunitas Kertas Kosong Goes to Expo Campus" },
      { foto: "sejarah/kegiatan-relawan-kaos-biru.jpg", ket: "Relawan dan tamu kegiatan K3" },
      { foto: "menulis/buku-para-perebut-mimpi.jpg", ket: "Buku Para Perebut Mimpi" },
    ],
  },
  {
    id: "liputan",
    judul: "Liputan Media",
    foto: [
      { foto: "liputan/bbs-tv-cakrawala-judul.jpg", ket: "Talkshow Cakrawala: Mengenal Komunitas Kertas Kosong. Sumber: BBS TV Surabaya" },
      { foto: "liputan/radar-lamongan-dana-patungan.jpg", ket: "Dana Patungan, Wujudkan Mimpi Anak Sekolah. Sumber: Radar Lamongan (Jawa Pos)", tahun: "2018" },
    ],
  },
];
