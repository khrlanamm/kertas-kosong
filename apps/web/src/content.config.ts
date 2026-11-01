import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

/**
 * Kegiatan: seminar, tryout, bimbel, dan acara lain.
 * Satu file Markdown di `src/content/kegiatan/` = satu halaman `/kegiatan/<nama-file>`.
 */
const kegiatan = defineCollection({
  loader: glob({ base: "./src/content/kegiatan", pattern: "**/*.md" }),
  schema: ({ image }) =>
    z.object({
      judul: z.string(),
      jenis: z.enum(["seminar", "tryout", "bimbel", "berbagi", "lainnya"]),
      /** Tanggal mulai, format YYYY-MM-DD. */
      tanggal: z.coerce.date(),
      /** Tanggal selesai untuk kegiatan lebih dari sehari (opsional). */
      tanggalSelesai: z.coerce.date().optional(),
      /** Jam pelaksanaan (opsional), contoh: "09.00-11.30 WIB". */
      waktu: z.string().optional(),
      /** Contoh: "Daring (Zoom)" atau nama tempat. */
      lokasi: z.string(),
      /** Satu-dua kalimat untuk kartu dan pratinjau link. */
      ringkasan: z.string(),
      /** Poster atau foto: path relatif dari file Markdown ini. */
      poster: image().optional(),
      /** Tautan pendaftaran. Disembunyikan otomatis setelah kegiatan selesai. */
      pendaftaran: z.url().optional(),
      /** true = hanya tampil saat `npm run dev`, tidak ikut dipublikasikan. */
      draft: z.boolean().default(false),
    }),
});

export const collections = { kegiatan };
