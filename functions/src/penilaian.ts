/**
 * Penilaian soal. Modul ini murni (tanpa Firebase) supaya mudah diuji.
 *
 * Tipe soal mengikuti bentuk soal UTBK-SNBT:
 * - `pg`     pilihan ganda, satu jawaban (A-E)
 * - `pgk`    pilihan ganda kompleks, bisa lebih dari satu jawaban
 * - `bs`     pilihan majemuk kompleks berbentuk tabel, tiap pernyataan punya dua pilihan
 *            (Benar/Salah, Ya/Tidak, Sesuai/Tidak Sesuai, ...)
 * - `isian`  isian singkat berupa angka, kata, atau frasa
 *
 * Seperti UTBK, setiap soal bernilai 1 jika benar dan 0 jika salah atau kosong, tanpa nilai minus.
 * Soal `pgk` dan `bs` dianggap benar hanya jika seluruh bagiannya benar.
 */

export type TipeSoal = "pg" | "pgk" | "bs" | "isian";

export interface Opsi {
  id: string;
  teks: string;
}

export interface KunciIsian {
  jawaban: string[];
  numerik: boolean;
  toleransi?: number;
}

export type Kunci = string | string[] | Record<string, boolean> | KunciIsian;
export type Jawaban = string | string[] | Record<string, boolean>;

export interface Soal {
  id: string;
  subtesId: string;
  urutan: number;
  tipe: TipeSoal;
  stimulusId?: string | null;
  teks: string;
  opsi?: Opsi[];
  pernyataan?: Opsi[];
  labelBs?: string[];
  kunci: Kunci;
  pembahasan?: string;
}

export function normalTeks(s: string): string {
  return s.normalize("NFKC").trim().toLowerCase().replace(/\s+/g, " ");
}

/**
 * Ubah isian menjadi angka. Menerima koma desimal ("2,5"), titik desimal ("2.5"),
 * titik ribuan bersama koma desimal ("1.250,5"), dan pecahan ("3/4").
 */
export function keAngka(s: string): number | null {
  const t = s.trim().replace(/\s+/g, "");
  if (t === "") return null;

  const pecahan = /^([+-]?[\d.,]+)\/([+-]?[\d.,]+)$/.exec(t);
  if (pecahan) {
    const a = keAngka(pecahan[1]);
    const b = keAngka(pecahan[2]);
    if (a === null || b === null || b === 0) return null;
    return a / b;
  }

  let angka = t;
  if (angka.includes(".") && angka.includes(",")) {
    angka = angka.replace(/\./g, "").replace(",", ".");
  } else if (angka.includes(",")) {
    angka = angka.replace(",", ".");
  }
  if (!/^[+-]?(\d+(\.\d*)?|\.\d+)$/.test(angka)) return null;
  const hasil = Number(angka);
  return Number.isFinite(hasil) ? hasil : null;
}

function samaHimpunan(a: string[], b: string[]): boolean {
  const x = new Set(a);
  const y = new Set(b);
  if (x.size !== y.size) return false;
  for (const v of x) if (!y.has(v)) return false;
  return true;
}

/** Apakah jawaban untuk satu soal benar. Jawaban kosong atau formatnya tidak cocok dianggap salah. */
export function jawabanBenar(soal: Pick<Soal, "tipe" | "kunci" | "pernyataan">, jawaban: unknown): boolean {
  if (jawaban === undefined || jawaban === null) return false;

  switch (soal.tipe) {
    case "pg":
      return typeof jawaban === "string" && jawaban === soal.kunci;

    case "pgk": {
      if (!Array.isArray(jawaban) || !Array.isArray(soal.kunci)) return false;
      if (!jawaban.every((v) => typeof v === "string")) return false;
      return jawaban.length > 0 && samaHimpunan(jawaban as string[], soal.kunci as string[]);
    }

    case "bs": {
      if (typeof jawaban !== "object" || Array.isArray(jawaban)) return false;
      const kunci = soal.kunci as Record<string, boolean>;
      const isi = jawaban as Record<string, unknown>;
      const ids = soal.pernyataan?.map((p) => p.id) ?? Object.keys(kunci);
      return ids.length > 0 && ids.every((id) => typeof isi[id] === "boolean" && isi[id] === kunci[id]);
    }

    case "isian": {
      if (typeof jawaban !== "string" || jawaban.trim() === "") return false;
      const kunci = soal.kunci as KunciIsian;
      if (!kunci || !Array.isArray(kunci.jawaban)) return false;
      if (kunci.numerik) {
        const x = keAngka(jawaban);
        if (x === null) return false;
        const toleransi = Math.abs(kunci.toleransi ?? 0);
        return kunci.jawaban.some((k) => {
          const y = keAngka(k);
          return y !== null && Math.abs(x - y) <= toleransi + 1e-9;
        });
      }
      const teks = normalTeks(jawaban);
      return kunci.jawaban.some((k) => normalTeks(k) === teks);
    }

    default:
      return false;
  }
}

export interface HasilSubtes {
  benar: number;
  jumlah: number;
  /** soalId -> benar/salah */
  rincian: Record<string, boolean>;
}

export function nilaiSubtes(soal: Soal[], jawaban: Record<string, unknown>): HasilSubtes {
  const rincian: Record<string, boolean> = {};
  let benar = 0;
  for (const s of soal) {
    const ok = jawabanBenar(s, jawaban[s.id]);
    rincian[s.id] = ok;
    if (ok) benar++;
  }
  return { benar, jumlah: soal.length, rincian };
}

/**
 * Skor berbobot tingkat kesulitan, skala 200-1000 seperti laporan UTBK.
 *
 * Ini bukan IRT resmi. Bobot soal dihitung dari proporsi peserta yang menjawab benar (p):
 * bobot = 0,1 + 0,9 x (1 - p). Soal yang jarang dijawab benar berbobot lebih besar.
 *
 * @param rincianPeserta daftar rincian benar/salah per peserta untuk satu subtes
 * @param soalIds soal pada subtes itu
 * @returns skor per peserta (urutan sama dengan input) dan bobot per soal
 */
export function skorBerbobot(
  rincianPeserta: Record<string, boolean>[],
  soalIds: string[],
): { skor: number[]; bobot: Record<string, number>; proporsi: Record<string, number> } {
  const n = rincianPeserta.length;
  const bobot: Record<string, number> = {};
  const proporsi: Record<string, number> = {};
  for (const id of soalIds) {
    const benar = rincianPeserta.filter((r) => r[id] === true).length;
    const p = n === 0 ? 0 : benar / n;
    proporsi[id] = p;
    bobot[id] = 0.1 + 0.9 * (1 - p);
  }
  const total = soalIds.reduce((s, id) => s + bobot[id], 0);
  const skor = rincianPeserta.map((r) => {
    if (total === 0) return 200;
    const nilai = soalIds.reduce((s, id) => s + (r[id] ? bobot[id] : 0), 0);
    return Math.round((200 + (800 * nilai) / total) * 100) / 100;
  });
  return { skor, bobot, proporsi };
}

/**
 * Acak urutan soal, tetapi soal yang memakai stimulus (bacaan) yang sama tetap berdampingan,
 * seperti soal berbasis teks di UTBK.
 */
export function acakSoal<T extends Pick<Soal, "id" | "stimulusId">>(soal: T[], acak: () => number = Math.random): T[] {
  const kelompok: T[][] = [];
  const indeks = new Map<string, number>();
  for (const s of soal) {
    const kunci = s.stimulusId ? `stimulus:${s.stimulusId}` : `soal:${s.id}`;
    const i = indeks.get(kunci);
    if (i === undefined) {
      indeks.set(kunci, kelompok.length);
      kelompok.push([s]);
    } else {
      kelompok[i].push(s);
    }
  }
  for (let i = kelompok.length - 1; i > 0; i--) {
    const j = Math.floor(acak() * (i + 1));
    [kelompok[i], kelompok[j]] = [kelompok[j], kelompok[i]];
  }
  return kelompok.flat();
}

export function acakDaftar<T>(daftar: T[], acak: () => number = Math.random): T[] {
  const hasil = [...daftar];
  for (let i = hasil.length - 1; i > 0; i--) {
    const j = Math.floor(acak() * (i + 1));
    [hasil[i], hasil[j]] = [hasil[j], hasil[i]];
  }
  return hasil;
}
