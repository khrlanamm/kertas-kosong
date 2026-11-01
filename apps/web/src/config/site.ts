/**
 * Pengaturan umum website. Ubah di sini, bukan di tiap halaman.
 *
 * Tautan yang dibiarkan kosong ("") tidak ditampilkan di website,
 * jadi aman diisi bertahap.
 */
export const site = {
  name: "Komunitas Kertas Kosong",
  shortName: "Kertas Kosong",
  singkatan: "K3",
  tagline: "Membangun Asa, Menggapai Cita",
  description:
    "Komunitas Kertas Kosong adalah gerakan sosial pendidikan yang lahir sejak 2016 untuk memutus rantai kemiskinan melalui akses pendidikan tinggi.",
  locale: "id_ID",
  lokasi: "Sukodadi, Kabupaten Lamongan, Jawa Timur",

  bimbel: {
    name: "Bimbel Ayo Kuliah",
    /** Angkatan berikutnya. */
    angkatan: "2027",
  },

  links: {
    /** Portal Bimbel baru (Flutter, web + Android). Isi setelah portal rilis. */
    portal: "",
    /** Formulir pendaftaran bimbel. Kosong = pendaftaran belum dibuka. */
    pendaftaranBimbel: "",
    /** Formulir pendaftaran tentor relawan. Kosong = belum dibuka. */
    pendaftaranRelawan: "",
  },

  /** Media sosial dan kontak. Yang kosong tidak ditampilkan. */
  social: {
    instagram: "https://www.instagram.com/komunitaskertaskosong",
    linkedin: "https://www.linkedin.com/company/komunitaskertaskosong",
    youtube: "",
    tiktok: "",
    /** Nomor WhatsApp resmi komunitas, format https://wa.me/62xxxxxxxxxx */
    whatsapp: "",
    email: "komunitaskertaskosong9@gmail.com",
  },
} as const;

export const nav = [
  { href: "/tentang", label: "Tentang" },
  { href: "/program", label: "Program" },
  { href: "/bimbel", label: "Bimbel" },
  { href: "/dampak", label: "Dampak" },
  { href: "/galeri", label: "Galeri" },
  { href: "/kegiatan", label: "Kegiatan" },
] as const;

/** Tautan lengkap untuk footer. */
export const peta = [
  {
    judul: "Tentang",
    tautan: [
      { href: "/tentang", label: "Tentang Kami" },
      { href: "/perjalanan", label: "Perjalanan" },
      { href: "/dampak", label: "Dampak" },
      { href: "/karya-digital", label: "Karya Digital" },
    ],
  },
  {
    judul: "Program #4AYO",
    tautan: [
      { href: "/program/ayo-membaca", label: "Ayo Membaca" },
      { href: "/program/ayo-menulis", label: "Ayo Menulis" },
      { href: "/program/ayo-kuliah", label: "Ayo Kuliah" },
      { href: "/program/ayo-berbagi", label: "Ayo Berbagi" },
      { href: "/bimbel", label: "Bimbel Ayo Kuliah" },
    ],
  },
  {
    judul: "Lainnya",
    tautan: [
      { href: "/kegiatan", label: "Kegiatan" },
      { href: "/galeri", label: "Galeri" },
      { href: "/ayo-terlibat", label: "Ayo Terlibat" },
      { href: "/kontak", label: "Kontak" },
      { href: "/privasi", label: "Kebijakan Privasi" },
    ],
  },
] as const;
