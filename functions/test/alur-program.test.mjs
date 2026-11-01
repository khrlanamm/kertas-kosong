// Tes alur pendaftaran program, akses tryout khusus peserta, dan catatan pelanggaran.
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { after, before, test } from "node:test";
import { initializeApp, deleteApp } from "firebase/app";
import { connectAuthEmulator, createUserWithEmailAndPassword, getAuth } from "firebase/auth";
import { arrayUnion, connectFirestoreEmulator, doc, getDoc, getFirestore, increment, setDoc, Timestamp, updateDoc } from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable } from "firebase/functions";
import { initializeTestEnvironment } from "@firebase/rules-unit-testing";

const PROJECT = "demo-kertas-kosong";
const jam = 3_600_000;
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
  return { auth, db, panggil: (n, d) => httpsCallable(fungsi, n)(d).then((r) => r.data) };
}

async function daftarAkun(k, email) {
  const { user } = await createUserWithEmailAndPassword(k.auth, email, "rahasia123");
  await setDoc(doc(k.db, `pengguna/${user.uid}`), { nama: "Calon", email, peran: "siswa", sekolah: "SMA", kelas: "Kelas XII", kota: "Gresik", setujuData: true });
  return user.uid;
}

const seed = (fn) => env.withSecurityRulesDisabled((ctx) => fn(ctx.firestore()));
const dataSeminar = {
  nama: "Adik Pejuang",
  sekolah: "SMAN 1 Dukun",
  kelas: "Kelas XII",
  kota: "Gresik",
  noHp: "081234567890",
  alamat: "Jl. Raya Dukun 1",
  minat: [{ kampus: "UNESA", jurusan: "Pendidikan Matematika" }],
};

let a, b, uidA, uidB;
before(async () => {
  const [host, port] = process.env.FIRESTORE_EMULATOR_HOST.split(":");
  env = await initializeTestEnvironment({
    projectId: PROJECT,
    firestore: { rules: readFileSync(new URL("../../firestore.rules", import.meta.url), "utf8"), host, port: Number(port) },
  });
  await env.clearFirestore();
  a = klien("a");
  b = klien("b");
  uidA = await daftarAkun(a, `a${Date.now()}@k3.id`);
  uidB = await daftarAkun(b, `b${Date.now()}@k3.id`);
  await seed(async (db) => {
    const buka = Timestamp.fromMillis(Date.now() - jam);
    const tutup = Timestamp.fromMillis(Date.now() + jam);
    await setDoc(doc(db, "program/sem"), { jenis: "seminar", judul: "Seminar", status: "terbit", buka, tutup, kuota: 1, seleksi: "otomatis", jumlahPendaftar: 0 });
    await setDoc(doc(db, "program/bim"), { jenis: "bimbel", judul: "Bimbel", status: "terbit", buka, tutup, kuota: 0, seleksi: "manual", jumlahPendaftar: 0 });
    await setDoc(doc(db, "program/lama"), { jenis: "seminar", judul: "Lama", status: "terbit", buka, tutup: Timestamp.fromMillis(Date.now() - 1000), seleksi: "otomatis" });
    await setDoc(doc(db, "ujian/khusus"), {
      judul: "Tryout khusus",
      status: "terbit",
      programId: "bim",
      buka,
      tutup,
      subtes: [{ id: "pu", nama: "PU", durasiDetik: 600 }],
      pengaturan: { tampilkanHasil: "segera", pengawasan: { aktif: true, batasPelanggaran: 3 } },
    });
    await setDoc(doc(db, "ujian/khusus/soal/s1"), { subtesId: "pu", urutan: 1, tipe: "pg", teks: "?", opsi: [{ id: "a", teks: "A" }, { id: "b", teks: "B" }], kunci: "a" });
  });
});

after(async () => {
  await Promise.all(aplikasi.map((x) => deleteApp(x)));
  await env?.cleanup();
});

test("seminar: langsung diterima, profil terisi, dan kuota dijaga", async () => {
  const r = await a.panggil("daftarProgram", { programId: "sem", data: dataSeminar });
  assert.equal(r.status, "diterima");
  const profil = (await getDoc(doc(a.db, `pengguna/${uidA}`))).data();
  assert.equal(profil.alamat, "Jl. Raya Dukun 1");
  assert.deepEqual(profil.minat, dataSeminar.minat);

  await assert.rejects(b.panggil("daftarProgram", { programId: "sem", data: dataSeminar }), /Kuota/);
  await assert.rejects(a.panggil("daftarProgram", { programId: "lama", data: dataSeminar }), /sudah ditutup/);
  await assert.rejects(a.panggil("daftarProgram", { programId: "sem", data: { ...dataSeminar, alamat: "" } }), /Alamat/);
});

test("bimbel: menunggu seleksi, tryout khusus terkunci sampai diterima", async () => {
  await assert.rejects(a.panggil("daftarProgram", { programId: "bim", data: dataSeminar }), /Tanggal lahir/);
  const r = await a.panggil("daftarProgram", {
    programId: "bim",
    data: { ...dataSeminar, tanggalLahir: "2009-05-17", eligibleSnbp: "ya", nomorSnbp: "4270012345" },
  });
  assert.equal(r.status, "menunggu");
  const pendaftar = (await getDoc(doc(a.db, `program/bim/pendaftar/${uidA}`))).data();
  assert.equal(pendaftar.data.nomorSnbp, "4270012345");
  assert.equal(pendaftar.kelas, null);

  await assert.rejects(a.panggil("mulaiSubtes", { ujianId: "khusus", subtesId: "pu" }), /khusus peserta/);
  await seed((db) => updateDoc(doc(db, `program/bim/pendaftar/${uidA}`), { status: "diterima", kelas: "A" }));
  const mulai = await a.panggil("mulaiSubtes", { ujianId: "khusus", subtesId: "pu" });
  assert.equal(mulai.pengawasan.batasPelanggaran, 3);
  assert.equal(mulai.pelanggaran, 0);

  const ref = doc(a.db, `sesi/khusus_${uidA}/pengerjaan/pu`);
  await updateDoc(ref, { "jawaban.s1": "a", pelanggaran: increment(2), jejak: arrayUnion(`keluarTab@${Date.now()}`, `salin@${Date.now()}`) });
  await a.panggil("kumpulkanSubtes", { ujianId: "khusus", subtesId: "pu" });
  const sesi = (await getDoc(doc(a.db, `sesi/khusus_${uidA}`))).data();
  assert.equal(sesi.pelanggaran, 2);
  assert.equal(sesi.hasil.pu.pelanggaran, 2);
  assert.equal(sesi.hasil.pu.benar, 1);
});

test("pendaftaran bisa dibatalkan selama masih menunggu", async () => {
  await b.panggil("daftarProgram", {
    programId: "bim",
    data: { ...dataSeminar, tanggalLahir: "2008-01-31", eligibleSnbp: "belumTahu" },
  });
  await b.panggil("batalDaftarProgram", { programId: "bim" });
  assert.equal((await getDoc(doc(b.db, `program/bim/pendaftar/${uidB}`))).exists(), false);
  await assert.rejects(a.panggil("batalDaftarProgram", { programId: "bim" }), /sudah diputuskan/);
});
