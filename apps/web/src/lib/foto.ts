import type { ImageMetadata } from "astro";

const semua = import.meta.glob<{ default: ImageMetadata }>("../assets/foto/**/*.{jpg,png}", { eager: true });

/**
 * Ambil gambar dari `src/assets/foto/` berdasarkan path relatif, mis. "seminar/seminar-2026-foto-bersama-aula.jpg".
 * Build akan gagal kalau path salah, jadi tautan gambar yang rusak ketahuan sebelum tayang.
 */
export function foto(path: string): ImageMetadata {
  const modul = semua[`../assets/foto/${path}`];
  if (!modul) throw new Error(`Gambar tidak ditemukan di src/assets/foto: ${path}`);
  return modul.default;
}
