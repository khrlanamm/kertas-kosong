/**
 * Pengaturan umum website. Ubah di sini, bukan di tiap halaman.
 *
 * Tautan yang dibiarkan kosong ("") tidak ditampilkan di website,
 * jadi aman diisi bertahap.
 */
export const site = {
  name: "Komunitas Kertas Kosong",
  shortName: "Kertas Kosong",
  tagline: "Mulai dari kertas kosong, melangkah ke kampus impian.",
  description:
    "Komunitas Kertas Kosong menyelenggarakan Bimbel #AyoKuliah, bimbingan belajar gratis untuk persiapan masuk perguruan tinggi, lengkap dengan kelas, rekaman, tryout, dan seminar.",
  locale: "id_ID",

  bimbel: {
    name: "Bimbel #AyoKuliah",
    /** Angkatan yang sedang atau akan berjalan. */
    angkatan: "2027",
  },

  links: {
    /** Portal Bimbel (Flutter, web + Android). Isi setelah portal rilis. */
    portal: "",
    /** Formulir pendaftaran bimbel. Kosong = pendaftaran belum dibuka. */
    pendaftaranBimbel: "",
  },

  /** Media sosial dan kontak. Yang kosong tidak ditampilkan. */
  social: {
    instagram: "",
    youtube: "",
    tiktok: "",
    whatsapp: "",
    email: "",
  },
} as const;

export const nav = [
  { href: "/", label: "Beranda" },
  { href: "/tentang", label: "Tentang" },
  { href: "/bimbel", label: "Bimbel" },
  { href: "/kegiatan", label: "Kegiatan" },
] as const;
