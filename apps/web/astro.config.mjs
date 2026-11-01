// @ts-check
import { defineConfig } from "astro/config";
import sitemap from "@astrojs/sitemap";
import tailwindcss from "@tailwindcss/vite";

// Alamat publik website. Ganti lewat env SITE_URL saat domain sendiri sudah siap,
// misalnya: SITE_URL=https://kertaskosong.id npm run build
const site = process.env.SITE_URL ?? "https://kertas-kosong.web.app";

export default defineConfig({
  site,
  // Halaman dibuat sebagai `tentang.html`, lalu Firebase Hosting (cleanUrls)
  // menyajikannya di `/tentang` tanpa garis miring di akhir.
  trailingSlash: "never",
  build: { format: "file" },
  integrations: [sitemap()],
  vite: { plugins: [tailwindcss()] },
});
