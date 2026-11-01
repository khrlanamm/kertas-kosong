#!/usr/bin/env node
/**
 * Media website disimpan di Firebase Storage (folder `website/`, tertutup untuk klien),
 * bukan di git, karena repo ini publik dan foto memuat wajah orang.
 *
 *   node functions/scripts/media.mjs tarik    Unduh media ke apps/web sebelum build
 *   node functions/scripts/media.mjs dorong   Unggah media lokal ke Storage
 *   node functions/scripts/media.mjs dorong --hapus   Sekaligus hapus objek yang tidak ada lagi di lokal
 *
 * Kredensial: secrets/firebase-adminsdk.json (tidak masuk git).
 */
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve, sep } from "node:path";
import { fileURLToPath } from "node:url";
import { cert, initializeApp } from "firebase-admin/app";
import { getStorage } from "firebase-admin/storage";

const AKAR = resolve(dirname(fileURLToPath(import.meta.url)), "../..");
const KREDENSIAL = join(AKAR, "secrets/firebase-adminsdk.json");
const BUCKET = "kertas-kosong.firebasestorage.app";
const AWALAN = "website/";

/** Lokasi lokal -> awalan di Storage. Boleh folder atau satu berkas. */
const PETA = [
  ["apps/web/src/assets", "assets"],
  ["apps/web/public/og.jpg", "public/og.jpg"],
];

function daftarBerkas(p) {
  if (!existsSync(p)) return [];
  if (statSync(p).isFile()) return [p];
  return readdirSync(p, { withFileTypes: true })
    .filter((e) => !e.name.startsWith("."))
    .flatMap((e) => daftarBerkas(join(p, e.name)));
}

const md5 = (f) => createHash("md5").update(readFileSync(f)).digest("base64");
const keObjek = (f, lokal, awalan) => AWALAN + (f === lokal ? awalan : `${awalan}/${relative(lokal, f).split(sep).join("/")}`);

function keLokal(nama) {
  const sisa = nama.slice(AWALAN.length);
  for (const [lokal, awalan] of PETA) {
    if (sisa === awalan) return join(AKAR, lokal);
    if (sisa.startsWith(`${awalan}/`)) return join(AKAR, lokal, sisa.slice(awalan.length + 1));
  }
  return null;
}

function bucket() {
  const sa = JSON.parse(readFileSync(KREDENSIAL, "utf8"));
  return getStorage(initializeApp({ credential: cert(sa), storageBucket: BUCKET })).bucket();
}

async function tarik() {
  if (!existsSync(KREDENSIAL)) {
    if (daftarBerkas(join(AKAR, PETA[0][0])).length > 0) {
      console.warn("media: kredensial tidak ada, memakai media lokal yang sudah ada.");
      return;
    }
    throw new Error(`media: butuh ${relative(AKAR, KREDENSIAL)} untuk mengunduh media dari Storage.`);
  }
  const [objek] = await bucket().getFiles({ prefix: AWALAN });
  let unduh = 0;
  await Promise.all(
    objek.map(async (o) => {
      const tujuan = keLokal(o.name);
      if (!tujuan || (existsSync(tujuan) && md5(tujuan) === o.metadata.md5Hash)) return;
      mkdirSync(dirname(tujuan), { recursive: true });
      await o.download({ destination: tujuan });
      unduh++;
    }),
  );
  console.log(`media: ${objek.length} berkas di Storage, ${unduh} diunduh.`);
}

async function dorong(hapus) {
  const b = bucket();
  const [objek] = await b.getFiles({ prefix: AWALAN });
  const ada = new Map(objek.map((o) => [o.name, o.metadata.md5Hash]));
  const lokal = PETA.flatMap(([p, awalan]) => {
    const dasar = join(AKAR, p);
    return daftarBerkas(dasar).map((f) => ({ f, nama: keObjek(f, dasar, awalan) }));
  });
  if (lokal.length === 0) throw new Error("media: tidak ada berkas lokal untuk diunggah. Jalankan `tarik` dulu.");
  let unggah = 0;
  for (const { f, nama } of lokal) {
    if (ada.get(nama) === md5(f)) continue;
    await b.upload(f, { destination: nama, resumable: false });
    unggah++;
  }
  const lama = hapus ? objek.filter((o) => !lokal.some((l) => l.nama === o.name)) : [];
  await Promise.all(lama.map((o) => o.delete()));
  console.log(`media: ${lokal.length} berkas lokal, ${unggah} diunggah, ${lama.length} dihapus dari Storage.`);
}

const perintah = process.argv[2];
if (perintah === "tarik") await tarik();
else if (perintah === "dorong") await dorong(process.argv.includes("--hapus"));
else {
  console.error("Pakai: media.mjs tarik | dorong [--hapus]");
  process.exit(1);
}
