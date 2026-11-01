import { defineCollection } from "astro:content";
import { glob } from "astro/loaders";
import { z } from "astro/zod";

/**
 * Kegiatan: seminar, tryout, pembukaan bimbel, dan acara lain.
 * Satu file Markdown di `src/content/kegiatan/` = satu halaman `/kegiatan/<nama-file>`.
 */
const kegiatan = defineCollection({
  loader: glob({ base: "./src/content/kegiatan", pattern: "**/*.md" }),
  schema: ({ image }) =>
    z.object({
      judul: z.string(),
      jenis: z.enum(["seminar", "tryout", "bimbel", "lainnya"]),
      /** Waktu mulai, contoh: 2027-02-14T09:00:00+07:00 */
      mulai: z.coerce.date(),
      /** Waktu selesai (opsional). */
      selesai: z.coerce.date().optional(),
      /** Contoh: "Daring (Zoom)" atau nama tempat. */
      lokasi: z.string(),
      /** Satu-dua kalimat untuk kartu dan pratinjau link. */
      ringkasan: z.string(),
      /** Poster, disimpan di folder yang sama dengan file Markdown. */
      poster: image().optional(),
      /** Tautan pendaftaran. Disembunyikan otomatis setelah kegiatan selesai. */
      pendaftaran: z.url().optional(),
      /** true = hanya tampil saat `npm run dev`, tidak ikut dipublikasikan. */
      draft: z.boolean().default(false),
    }),
});

export const collections = { kegiatan };
