// Tes alur ujian lewat Cloud Functions di emulator. Jalankan lewat `npm run test:emulator`.
import assert from "node:assert/strict";
import { after, before, test } from "node:test";
import { initializeApp, deleteApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth } from "firebase/auth";
import { connectFirestoreEmulator, doc, getDoc, getFirestore, setDoc, updateDoc } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { readFileSync } from "node:fs";

const PROJECT = "demo-kertas-kosong";
let env;
const aplikasi = [];

function klien(nama) {
  const app = initializeApp({ apiKey: "demo", projectId: PROJECT, authDomain: `${PROJECT}.firebaseapp.com` }, nama);
  aplikasi.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, `http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}`, { disableWarnings: true });
  const db = getFirestore(app);
  const [fh, fp] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  connectFirestoreEmulator(db, fh, Number(fp));
  const fungsi = getFunctions(app, "asia-southeast2");
  connectFunctionsEmulator(fungsi, "127.0.0.1", 5001);
  const panggil = (nama, data) => httpsCallable(fungsi, nama)(data).then((r) => r.data);
  return { auth, db, panggil };
}

async function daftar(k, email, nama) {
  const { user } = await createUserWithEmailAndPassword(k.auth, email, "rahasia123");
  await setDoc(doc(k.db, `pengguna/${user.uid}`), {
    nama,
    email,
    peran: "siswa",
    sekolah: "SMAN 1 Dukun",
    kelas: "XII",
    kota: "Gresik",
    setujuData: true,
  });
  return user.uid;
}

async function seed(fn) {
  await env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
}

const jam = 3_600_000;
let siswa, admin, uidSiswa, uidAdmin;

before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"), host, port: Number(port) },
  });
  await env.clearFirestore();

  siswa = klien("siswa");
  admin = klien("admin");
  uidSiswa = await daftar(siswa, `siswa${Date.now()}@contoh.id`, "Adik Pejuang");
  uidAdmin = await daftar(admin, `admin${Date.now()}@contoh.id`, "Kakak Admin");

  const { Timestamp } = await import("firebase/firestore");
  await seed(async (db) => {
    await setDoc(doc(db, `pengguna/${uidAdmin}`), { peran: "admin" }, { merge: true });
    await setDoc(doc(db, "ujian/to1"), {
      judul: "Tryout 1",
      status: "terbit",
      buka: Timestamp.fromMillis(Date.now() - jam),
      tutup: Timestamp.fromMillis(Date.now() + jam),
      subtes: [
        { id: "pu", nama: "Penalaran Umum", durasiDetik: 1800 },
        { id: "pm", nama: "Penalaran Matematika", durasiDetik: 2550 },
      ],
      pengaturan: { acakSoal: true, acakOpsi: true, tampilkanHasil: "segera", tampilkanPembahasan: true },
    });
    const opsi = ["a", "b", "c", "d", "e"].map((id) => ({ id, teks: `Opsi ${id.toUpperCase()}` }));
    await setDoc(doc(db, "ujian/to1/stimulus/bacaan1"), { subtesId: "pu", judul: "Bacaan 1", teks: "Teks bacaan." });
    await setDoc(doc(db, "ujian/to1/soal/pu1"), { subtesId: "pu", urutan: 1, tipe: "pg", teks: "Soal 1", opsi, kunci: "b", stimulusId: "bacaan1", pembahasan: "Karena B." });
    await setDoc(doc(db, "ujian/to1/soal/pu2"), { subtesId: "pu", urutan: 2, tipe: "pgk", teks: "Soal 2", opsi, kunci: ["a", "c"], stimulusId: "bacaan1" });
    await setDoc(doc(db, "ujian/to1/soal/pu3"), {
      subtesId: "pu",
      urutan: 3,
      tipe: "bs",
      teks: "Soal 3",
      pernyataan: [{ id: "p1", teks: "P1" }, { id: "p2", teks: "P2" }],
      labelBs: ["Benar", "Salah"],
      kunci: { p1: true, p2: false },
    });
    await setDoc(doc(db, "ujian/to1/soal/pm1"), { subtesId: "pm", urutan: 1, tipe: "isian", teks: "Soal 4", kunci: { jawaban: ["0,5"], numerik: true } });
  });
});

after(async () => {
  await Promise.all(aplikasi.map((a) => deleteApp(a)));
  await env?.cleanup();
});

test("subtes harus dikerjakan berurutan", async () => {
  await assert.rejects(siswa.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pm" }), /Penalaran Umum/);
});

test("peserta mengerjakan ujian dari awal sampai selesai", async () => {
  const mulai = await siswa.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pu" });
  assert.equal(mulai.status, "baru");
  assert.equal(mulai.soal.length, 3);
  assert.ok(mulai.batas > mulai.sekarang, "batas waktu di masa depan");
  assert.ok(mulai.soal.every((s) => !("kunci" in s) && !("pembahasan" in s)), "kunci tidak dikirim ke peserta");
  assert.equal(mulai.stimulus.bacaan1.teks, "Teks bacaan.");
  const iPu1 = mulai.soal.findIndex((s) => s.id === "pu1");
  const iPu2 = mulai.soal.findIndex((s) => s.id === "pu2");
  assert.equal(Math.abs(iPu1 - iPu2), 1, "soal satu bacaan tetap berdampingan");

  const ref = doc(siswa.db, `sesi/to1_${uidSiswa}/pengerjaan/pu`);
  await updateDoc(ref, { "jawaban.pu1": "b", "jawaban.pu2": ["c", "a"], "jawaban.pu3": { p1: true, p2: true }, "ragu.pu3": true });

  const lanjut = await siswa.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pu" });
  assert.equal(lanjut.status, "lanjut");
  assert.equal(lanjut.batas, mulai.batas, "batas waktu tidak berubah saat dilanjutkan");
  assert.equal(lanjut.jawaban.pu1, "b");

  const hasilPu = await siswa.panggil("kumpulkanSubtes", { ujianId: "to1", subtesId: "pu" });
  assert.deepEqual(hasilPu, { semuaSelesai: false, benar: 2, jumlah: 3 });
  await assert.rejects(siswa.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pu" }), /sudah selesai/);
  await assert.rejects(updateDoc(ref, { "jawaban.pu3": { p1: true, p2: false } }));

  await siswa.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pm" });
  await updateDoc(doc(siswa.db, `sesi/to1_${uidSiswa}/pengerjaan/pm`), { "jawaban.pm1": "1/2" });
  const hasilPm = await siswa.panggil("kumpulkanSubtes", { ujianId: "to1", subtesId: "pm" });
  assert.deepEqual(hasilPm, { semuaSelesai: true, benar: 1, jumlah: 1 });

  const sesi = (await getDoc(doc(siswa.db, `sesi/to1_${uidSiswa}`))).data();
  assert.equal(sesi.status, "selesai");
  assert.equal(sesi.totalBenar, 3);
  assert.equal(sesi.uji, false);
});

test("pembahasan dan skor tersedia setelah ujian ditutup", async () => {
  await assert.rejects(siswa.panggil("pembahasan", { ujianId: "to1" }), /setelah ujian ditutup/);
  await assert.rejects(admin.panggil("hitungSkor", { ujianId: "to1" }), /setelah ujian ditutup/);
  await assert.rejects(siswa.panggil("hitungSkor", { ujianId: "to1" }), /admin/);

  const { Timestamp } = await import("firebase/firestore");
  await seed((db) => updateDoc(doc(db, "ujian/to1"), { tutup: Timestamp.fromMillis(Date.now() - 1000) }));

  const skor = await admin.panggil("hitungSkor", { ujianId: "to1" });
  assert.equal(skor.peserta, 1);
  const sesi = (await getDoc(doc(siswa.db, `sesi/to1_${uidSiswa}`))).data();
  assert.equal(sesi.hasil.pu.benar, 2);
  assert.ok(sesi.hasil.pu.skor >= 200 && sesi.hasil.pu.skor <= 1000);
  assert.equal(sesi.hasil.pm.skor, 1000);

  const bahas = await siswa.panggil("pembahasan", { ujianId: "to1" });
  const pu3 = bahas.soal.find((s) => s.id === "pu3");
  assert.deepEqual(pu3.kunci, { p1: true, p2: false });
  assert.equal(pu3.benar, false);
  assert.equal(bahas.soal.find((s) => s.id === "pu1").pembahasan, "Karena B.");
});

test("peserta tidak bisa memulai setelah ujian ditutup, admin tetap bisa mencoba", async () => {
  const lain = klien("lain");
  await daftar(lain, `lain${Date.now()}@contoh.id`, "Peserta Telat");
  await assert.rejects(lain.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pu" }), /sudah berakhir/);

  const coba = await admin.panggil("mulaiSubtes", { ujianId: "to1", subtesId: "pu" });
  assert.equal(coba.status, "baru");
  const sesiAdmin = (await getDoc(doc(admin.db, `sesi/to1_${uidAdmin}`))).data();
  assert.equal(sesiAdmin.uji, true, "percobaan admin ditandai uji dan tidak ikut dinilai");
});
