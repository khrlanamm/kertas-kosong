/**
 * Validasi data pendaftaran seminar dan bimbel. Modul murni supaya mudah diuji.
 *
 * Seminar: nama, kelas, sekolah, nomor HP, alamat, serta minat jurusan dan kampus.
 * Bimbel: semua data seminar, ditambah tanggal lahir (untuk membantu akses hasil UTBK)
 * dan status eligible SNBP sekolah beserta nomor pendaftaran SNBP jika eligible.
 */

export type JenisProgram = "seminar" | "bimbel";
export type EligibleSnbp = "ya" | "tidak" | "belumTahu";

export interface Minat {
  kampus: string;
  jurusan: string;
}

export interface DataPendaftaran {
  nama: string;
  sekolah: string;
  kelas: string;
  kota: string;
  noHp: string;
  alamat: string;
  minat: Minat[];
  tanggalLahir?: string;
  eligibleSnbp?: EligibleSnbp;
  nomorSnbp?: string;
}

function teks(v: unknown, maks: number): string {
  return typeof v === "string" ? v.trim().replace(/\s+/g, " ").slice(0, maks) : "";
}

/** Normalkan nomor HP Indonesia ke format 08xxxxxxxxxx. Null jika tidak valid. */
export function normalNoHp(v: unknown): string | null {
  if (typeof v !== "string") return null;
  let n = v.replace(/[\s().-]/g, "");
  if (n.startsWith("+62")) n = "0" + n.slice(3);
  else if (n.startsWith("62")) n = "0" + n.slice(2);
  return /^08\d{7,12}$/.test(n) ? n : null;
}

/** Tanggal format YYYY-MM-DD yang benar-benar ada, dan usia masuk akal untuk peserta bimbel. */
export function tanggalLahirValid(v: unknown, sekarang = new Date()): boolean {
  if (typeof v !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(v)) return false;
  const [y, m, d] = v.split("-").map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  if (t.getUTCFullYear() !== y || t.getUTCMonth() !== m - 1 || t.getUTCDate() !== d) return false;
  const usia = sekarang.getUTCFullYear() - y;
  return usia >= 12 && usia <= 30;
}

export function periksaPendaftaran(
  jenis: JenisProgram,
  masukan: unknown,
  sekarang = new Date(),
): { data: DataPendaftaran; galat: null } | { data: null; galat: string } {
  const m = (masukan && typeof masukan === "object" ? masukan : {}) as Record<string, unknown>;
  const gagal = (galat: string) => ({ data: null, galat }) as const;

  const nama = teks(m.nama, 100);
  const sekolah = teks(m.sekolah, 150);
  const kelas = teks(m.kelas, 50);
  const kota = teks(m.kota, 100);
  const alamat = teks(m.alamat, 300);
  const noHp = normalNoHp(m.noHp);

  if (!nama) return gagal("Nama wajib diisi.");
  if (!sekolah) return gagal("Asal sekolah wajib diisi.");
  if (!kelas) return gagal("Kelas wajib diisi.");
  if (!noHp) return gagal("Nomor HP tidak valid. Gunakan format 08xxxxxxxxxx.");
  if (alamat.length < 5) return gagal("Alamat wajib diisi.");

  const daftarMinat = Array.isArray(m.minat) ? m.minat : [];
  const minat = daftarMinat
    .map((x) => (x && typeof x === "object" ? (x as Record<string, unknown>) : {}))
    .map((x) => ({ kampus: teks(x.kampus, 100), jurusan: teks(x.jurusan, 100) }))
    .filter((x) => x.kampus || x.jurusan);
  if (minat.length === 0) return gagal("Isi minimal satu pilihan jurusan dan kampus.");
  if (minat.length > 3) return gagal("Pilihan jurusan dan kampus maksimal tiga.");
  if (minat.some((x) => !x.kampus || !x.jurusan)) return gagal("Setiap pilihan harus berisi jurusan dan kampus.");

  const data: DataPendaftaran = { nama, sekolah, kelas, kota, noHp, alamat, minat };
  if (jenis === "seminar") return { data, galat: null };

  if (!tanggalLahirValid(m.tanggalLahir, sekarang)) return gagal("Tanggal lahir tidak valid.");
  const eligible = m.eligibleSnbp;
  if (eligible !== "ya" && eligible !== "tidak" && eligible !== "belumTahu") {
    return gagal("Pilih status eligible SNBP sekolahmu.");
  }
  const nomorSnbp = teks(m.nomorSnbp, 30).replace(/\s/g, "");
  if (eligible === "ya" && !/^[0-9A-Za-z-]{5,30}$/.test(nomorSnbp)) {
    return gagal("Isi nomor pendaftaran SNBP (5-30 karakter angka/huruf).");
  }
  return {
    data: {
      ...data,
      tanggalLahir: m.tanggalLahir as string,
      eligibleSnbp: eligible,
      nomorSnbp: eligible === "ya" ? nomorSnbp : "",
    },
    galat: null,
  };
}
