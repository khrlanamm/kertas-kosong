// Tes aturan Firestore. Jalankan lewat `npm run test:emulator` (butuh emulator Firestore).
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";
import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { doc, getDoc, setDoc, updateDoc, Timestamp } from "firebase/firestore";

let env;

const profil = (email, peran = "siswa") => ({
  nama: "Adik Pejuang",
  email,
  peran,
  sekolah: "SMAN 1 Sukodadi",
  kelas: "XII",
  kota: "Lamongan",
  setujuData: true,
});

before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  env = await initializeTestEnvironment({
    projectId: "demo-kertas-kosong",
    firestore: { rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"), host, port: Number(port) },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, "pengguna/admin1"), profil("admin@contoh.id", "admin"));
    await setDoc(doc(db, "pengguna/siswa2"), profil("siswa2@contoh.id"));
    await setDoc(doc(db, "ujian/u1"), { judul: "Tryout 1", status: "terbit" });
    await setDoc(doc(db, "ujian/u2"), { judul: "Draf", status: "draf" });
    await setDoc(doc(db, "ujian/u1/soal/s1"), { teks: "?", kunci: "a" });
    await setDoc(doc(db, "sesi/u1_siswa1"), { uid: "siswa1", ujianId: "u1" });
    await setDoc(doc(db, "sesi/u1_siswa1/pengerjaan/pu"), {
      uid: "siswa1",
      soalIds: ["s1", "s2"],
      jawaban: {},
      ragu: {},
      selesai: false,
      batas: Timestamp.fromMillis(Date.now() + 60_000),
    });
    await setDoc(doc(db, "sesi/u1_siswa1/pengerjaan/ppu"), {
      uid: "siswa1",
      soalIds: ["s3"],
      jawaban: {},
      ragu: {},
      selesai: false,
      batas: Timestamp.fromMillis(Date.now() - 60_000),
    });
  });
});

after(async () => {
  await env?.cleanup();
});

const siswa = () => env.authenticatedContext("siswa1", { email: "siswa1@contoh.id" }).firestore();
const admin = () => env.authenticatedContext("admin1", { email: "admin@contoh.id" }).firestore();

test("pengguna baru hanya bisa membuat profilnya sendiri sebagai siswa", async () => {
  await assertSucceeds(setDoc(doc(siswa(), "pengguna/siswa1"), profil("siswa1@contoh.id")));
  await env.clearFirestore();
  await assertFails(setDoc(doc(siswa(), "pengguna/siswa1"), profil("siswa1@contoh.id", "admin")));
  await assertFails(setDoc(doc(siswa(), "pengguna/orang-lain"), profil("siswa1@contoh.id")));
  await assertFails(setDoc(doc(siswa(), "pengguna/siswa1"), { ...profil("siswa1@contoh.id"), setujuData: false }));
  await assertFails(setDoc(doc(siswa(), "pengguna/siswa1"), profil("palsu@contoh.id")));
});

test("siswa tidak bisa menaikkan perannya, admin bisa mengatur peran", async () => {
  await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), "pengguna/siswa1"), profil("siswa1@contoh.id")));
  await assertFails(updateDoc(doc(siswa(), "pengguna/siswa1"), { peran: "admin" }));
  await assertSucceeds(updateDoc(doc(siswa(), "pengguna/siswa1"), { nama: "Nama Baru" }));
  await assertFails(getDoc(doc(siswa(), "pengguna/siswa2")));
  await assertSucceeds(updateDoc(doc(admin(), "pengguna/siswa2"), { peran: "admin" }));
  await assertFails(updateDoc(doc(admin(), "pengguna/siswa2"), { nama: "Diubah admin" }));
});

test("soal dan kunci hanya bisa dibaca admin", async () => {
  await assertFails(getDoc(doc(siswa(), "ujian/u1/soal/s1")));
  await assertSucceeds(getDoc(doc(admin(), "ujian/u1/soal/s1")));
});

test("siswa hanya melihat ujian yang sudah terbit dan tidak bisa mengubahnya", async () => {
  await assertSucceeds(getDoc(doc(siswa(), "ujian/u1")));
  await assertFails(getDoc(doc(siswa(), "ujian/u2")));
  await assertFails(updateDoc(doc(siswa(), "ujian/u1"), { judul: "Diretas" }));
  await assertSucceeds(updateDoc(doc(admin(), "ujian/u1"), { judul: "Tryout 1 (revisi)" }));
});

test("sesi ditulis server; peserta hanya membaca miliknya", async () => {
  await assertSucceeds(getDoc(doc(siswa(), "sesi/u1_siswa1")));
  await assertFails(updateDoc(doc(siswa(), "sesi/u1_siswa1"), { totalBenar: 999 }));
  const lain = env.authenticatedContext("siswa2", { email: "siswa2@contoh.id" }).firestore();
  await assertFails(getDoc(doc(lain, "sesi/u1_siswa1")));
});

test("jawaban hanya bisa disimpan selama waktu subtes berjalan", async () => {
  const ref = doc(siswa(), "sesi/u1_siswa1/pengerjaan/pu");
  await assertSucceeds(updateDoc(ref, { "jawaban.s1": "a", "ragu.s2": true }));
  await assertFails(updateDoc(ref, { "jawaban.soal-lain": "a" }));
  await assertFails(updateDoc(ref, { batas: Timestamp.fromMillis(Date.now() + 3_600_000) }));
  await assertFails(updateDoc(ref, { selesai: true }));
  await assertFails(updateDoc(doc(siswa(), "sesi/u1_siswa1/pengerjaan/ppu"), { "jawaban.s3": "a" }));

  const lain = env.authenticatedContext("siswa2", { email: "siswa2@contoh.id" }).firestore();
  await assertFails(updateDoc(doc(lain, "sesi/u1_siswa1/pengerjaan/pu"), { "jawaban.s1": "b" }));

  const tersimpan = await getDoc(ref);
  assert.equal(tersimpan.get("jawaban").s1, "a");
});
