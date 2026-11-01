import { getCollection, type CollectionEntry } from "astro:content";

export type Kegiatan = CollectionEntry<"kegiatan">;

export const labelJenis: Record<Kegiatan["data"]["jenis"], string> = {
  seminar: "Seminar",
  tryout: "Tryout",
  bimbel: "Bimbel",
  lainnya: "Kegiatan",
};

/** Semua kegiatan yang boleh tampil, terbaru dulu. Draft hanya muncul saat `npm run dev`. */
export async function getKegiatan(): Promise<Kegiatan[]> {
  const semua = await getCollection("kegiatan", ({ data }) => import.meta.env.DEV || !data.draft);
  return semua.sort((a, b) => b.data.mulai.getTime() - a.data.mulai.getTime());
}

const HARI = 24 * 60 * 60 * 1000;
const WIB = 7 * 60 * 60 * 1000;

/** Batas akhir kegiatan: waktu selesai, atau pukul 24.00 WIB di hari mulai bila tidak diisi. */
export function akhirKegiatan({ data }: Kegiatan): Date {
  if (data.selesai) return data.selesai;
  const akhirHari = Math.floor((data.mulai.getTime() + WIB) / HARI) * HARI + HARI - WIB;
  return new Date(akhirHari);
}

const zona = { timeZone: "Asia/Jakarta" } as const;

export function formatTanggal(date: Date): string {
  return new Intl.DateTimeFormat("id-ID", { ...zona, dateStyle: "long" }).format(date);
}

const formatHari = new Intl.DateTimeFormat("id-ID", { ...zona, dateStyle: "full" });
const formatJam = new Intl.DateTimeFormat("id-ID", { ...zona, hour: "2-digit", minute: "2-digit" });

/** Contoh: "Minggu, 14 Februari 2027, pukul 09.00–11.30 WIB". */
export function formatWaktu(mulai: Date, selesai?: Date): string {
  const hariMulai = formatHari.format(mulai);
  if (!selesai) return `${hariMulai}, pukul ${formatJam.format(mulai)} WIB`;
  if (formatHari.format(selesai) === hariMulai) {
    return `${hariMulai}, pukul ${formatJam.format(mulai)}–${formatJam.format(selesai)} WIB`;
  }
  return `${hariMulai}, pukul ${formatJam.format(mulai)} WIB sampai ${formatHari.format(selesai)}, pukul ${formatJam.format(selesai)} WIB`;
}
