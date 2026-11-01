// Tes rules untuk program, pendaftar, jadwal, dan catatan pengawasan tryout.
import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";
import { assertFails, assertSucceeds, initializeTestEnvironment } from "@firebase/rules-unit-testing";
import { arrayUnion, collectionGroup, doc, getDoc, getDocs, increment, query, setDoc, Timestamp, updateDoc, where } from "firebase/firestore";

let env;
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
    const profil = { nama: "X", sekolah: "S", kelas: "K", kota: "Kota", setujuData: true };
    await setDoc(doc(db, "pengguna/admin1"), { ...profil, email: "a@k3.id", peran: "admin" });
    await setDoc(doc(db, "program/b27"), { judul: "Bimbel 2027", jenis: "bimbel", status: "terbit" });
    await setDoc(doc(db, "program/draf"), { judul: "Draf", jenis: "seminar", status: "draf" });
    await setDoc(doc(db, "program/b27/pendaftar/diterima1"), { uid: "diterima1", status: "diterima", kelas: "A", data: { nama: "D" } });
    await setDoc(doc(db, "program/b27/pendaftar/menunggu1"), { uid: "menunggu1", status: "menunggu", kelas: null, data: { nama: "M" } });
    await setDoc(doc(db, "program/b27/jadwal/j1"), { judul: "PU minggu 1", tautan: "https://zoom.us/j/1" });
    await setDoc(doc(db, "sesi/u1_s1/pengerjaan/pu"), {
      uid: "s1",
      soalIds: ["a"],
      jawaban: {},
      ragu: {},
      selesai: false,
      pelanggaran: 1,
      jejak: ["keluarTab@1"],
      batas: Timestamp.fromMillis(Date.now() + 60_000),
    });
  });
});

after(async () => env?.cleanup());

const sebagai = (uid) => env.authenticatedContext(uid, { email: `${uid}@k3.id` }).firestore();

test("program terbit terbaca siswa; draf dan penulisan hanya admin", async () => {
  await assertSucceeds(getDoc(doc(sebagai("s1"), "program/b27")));
  await assertFails(getDoc(doc(sebagai("s1"), "program/draf")));
  await assertFails(updateDoc(doc(sebagai("s1"), "program/b27"), { judul: "x" }));
  await assertSucceeds(updateDoc(doc(sebagai("admin1"), "program/b27"), { judul: "Bimbel Ayo Kuliah 2027" }));
});

test("pendaftar hanya ditulis lewat Cloud Function; admin mengatur status dan kelas", async () => {
  await assertFails(setDoc(doc(sebagai("baru"), "program/b27/pendaftar/baru"), { uid: "baru", status: "diterima" }));
  await assertSucceeds(getDoc(doc(sebagai("menunggu1"), "program/b27/pendaftar/menunggu1")));
  await assertFails(getDoc(doc(sebagai("menunggu1"), "program/b27/pendaftar/diterima1")));
  await assertFails(updateDoc(doc(sebagai("menunggu1"), "program/b27/pendaftar/menunggu1"), { status: "diterima" }));
  await assertSucceeds(updateDoc(doc(sebagai("admin1"), "program/b27/pendaftar/menunggu1"), { status: "diterima", kelas: "B" }));
  await assertFails(updateDoc(doc(sebagai("admin1"), "program/b27/pendaftar/menunggu1"), { status: "lulus" }));
  await assertFails(updateDoc(doc(sebagai("admin1"), "program/b27/pendaftar/menunggu1"), { "data.nama": "diubah" }));
});

test("siswa bisa mencari pendaftarannya sendiri di semua program", async () => {
  await assertSucceeds(getDocs(query(collectionGroup(sebagai("diterima1"), "pendaftar"), where("uid", "==", "diterima1"))));
  await assertFails(getDocs(query(collectionGroup(sebagai("diterima1"), "pendaftar"), where("uid", "==", "menunggu1"))));
});

test("jadwal hanya untuk peserta yang diterima", async () => {
  await assertSucceeds(getDoc(doc(sebagai("diterima1"), "program/b27/jadwal/j1")));
  await assertFails(getDoc(doc(sebagai("menunggu1"), "program/b27/jadwal/j1")));
  await assertFails(getDoc(doc(sebagai("orangLain"), "program/b27/jadwal/j1")));
  await assertFails(setDoc(doc(sebagai("diterima1"), "program/b27/jadwal/j2"), { judul: "palsu" }));
  await assertSucceeds(setDoc(doc(sebagai("admin1"), "program/b27/jadwal/j2"), { judul: "PM minggu 1" }));
});

test("catatan pelanggaran hanya bisa bertambah", async () => {
  const ref = doc(sebagai("s1"), "sesi/u1_s1/pengerjaan/pu");
  await assertSucceeds(updateDoc(ref, { pelanggaran: increment(1), jejak: arrayUnion("salin@2") }));
  await assertFails(updateDoc(ref, { pelanggaran: 0 }));
  await assertFails(updateDoc(ref, { jejak: [] }));
  await assertFails(updateDoc(ref, { pelanggaran: "nol" }));
});

test("profil boleh menyimpan data pendaftaran tambahan", async () => {
  const db = sebagai("s9");
  await assertSucceeds(
    setDoc(doc(db, "pengguna/s9"), {
      nama: "S9",
      email: "s9@k3.id",
      peran: "siswa",
      sekolah: "SMA",
      kelas: "Kelas XII",
      kota: "Gresik",
      alamat: "Jl. Mawar 1",
      minat: [{ kampus: "UNESA", jurusan: "Matematika" }],
      tanggalLahir: "2009-05-17",
      eligibleSnbp: "ya",
      nomorSnbp: "4270012345",
      setujuData: true,
    }),
  );
  await assertFails(updateDoc(doc(db, "pengguna/s9"), { hobi: "membaca" }));
});
