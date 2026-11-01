import { getCollection, type CollectionEntry } from "astro:content";

export type Kegiatan = CollectionEntry<"kegiatan">;

export const labelJenis: Record<Kegiatan["data"]["jenis"], string> = {
  seminar: "Seminar",
  tryout: "Tryout",
  bimbel: "Bimbel",
  berbagi: "Ayo Berbagi",
  lainnya: "Kegiatan",
};

/** Semua kegiatan yang boleh tampil, terbaru dulu. Draft hanya muncul saat `npm run dev`. */
export async function getKegiatan(): Promise<Kegiatan[]> {
  const semua = await getCollection("kegiatan", ({ data }) => import.meta.env.DEV || !data.draft);
  return semua.sort((a, b) => b.data.tanggal.getTime() - a.data.tanggal.getTime());
}

const HARI = 24 * 60 * 60 * 1000;
const WIB = 7 * 60 * 60 * 1000;

/**
 * Tanggal di frontmatter (YYYY-MM-DD) terbaca sebagai pukul 00.00 UTC.
 * Mulai = pukul 00.00 WIB di tanggal mulai; akhir = pukul 24.00 WIB di tanggal selesai.
 */
export function rentangKegiatan({ data }: Kegiatan): { mulai: Date; akhir: Date } {
  const mulai = new Date(data.tanggal.getTime() - WIB);
  const akhir = new Date((data.tanggalSelesai ?? data.tanggal).getTime() + HARI - WIB);
  return { mulai, akhir };
}

const formatPanjang = new Intl.DateTimeFormat("id-ID", { timeZone: "UTC", dateStyle: "full" });
const formatSedang = new Intl.DateTimeFormat("id-ID", { timeZone: "UTC", dateStyle: "long" });
const formatTanpaTahun = new Intl.DateTimeFormat("id-ID", { timeZone: "UTC", day: "numeric", month: "long" });

/** Contoh: "24 Januari 2026" atau "2 Maret - 12 April 2026". */
export function formatTanggal({ data }: Kegiatan): string {
  const { tanggal, tanggalSelesai } = data;
  if (!tanggalSelesai) return formatSedang.format(tanggal);
  const awal =
    tanggal.getUTCFullYear() === tanggalSelesai.getUTCFullYear()
      ? formatTanpaTahun.format(tanggal)
      : formatSedang.format(tanggal);
  return `${awal} - ${formatSedang.format(tanggalSelesai)}`;
}

/** Contoh: "Sabtu, 24 Januari 2026, 08.00-12.00 WIB". */
export function formatWaktuLengkap(kegiatan: Kegiatan): string {
  const { tanggal, tanggalSelesai, waktu } = kegiatan.data;
  const hari = tanggalSelesai ? formatTanggal(kegiatan) : formatPanjang.format(tanggal);
  return waktu ? `${hari}, ${waktu}` : hari;
}
