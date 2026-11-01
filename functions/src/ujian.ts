import { getFirestore, Timestamp, FieldValue, type Transaction, type DocumentReference } from "firebase-admin/firestore";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { acakDaftar, acakSoal, nilaiSubtes, skorBerbobot, type Soal } from "./penilaian.js";

const db = () => getFirestore();

interface Subtes {
  id: string;
  nama: string;
  singkatan?: string;
  durasiDetik: number;
}

interface Ujian {
  judul: string;
  status: "draf" | "terbit";
  buka: Timestamp;
  tutup: Timestamp;
  subtes: Subtes[];
  /** Jika diisi, hanya peserta yang diterima di program ini yang bisa mengerjakan. */
  programId?: string | null;
  pengaturan?: {
    acakSoal?: boolean;
    acakOpsi?: boolean;
    urutanBebas?: boolean;
    tampilkanHasil?: "segera" | "setelahTutup";
    tampilkanPembahasan?: boolean;
    pengawasan?: { aktif?: boolean; batasPelanggaran?: number; layarPenuh?: boolean };
  };
}

interface Pengguna {
  nama: string;
  email: string;
  peran: "siswa" | "admin";
  sekolah?: string;
}

interface Pengerjaan {
  uid: string;
  ujianId: string;
  subtesId: string;
  mulai: Timestamp;
  batas: Timestamp;
  soalIds: string[];
  opsiUrutan: Record<string, string[]>;
  jawaban: Record<string, unknown>;
  ragu: Record<string, boolean>;
  selesai: boolean;
  uji?: boolean;
  pelanggaran?: number;
  jejak?: string[];
}

type HasilSesi = { benar: number; jumlah: number; skor?: number; pelanggaran?: number };

interface Sesi {
  uid: string;
  ujianId: string;
  nama: string;
  sekolah: string;
  status: "berlangsung" | "selesai";
  subtesAktif: string | null;
  subtesSelesai: string[];
  hasil: Record<string, HasilSesi>;
  uji: boolean;
}

/** Waktu tenggang untuk jawaban yang tersimpan tepat saat waktu habis. */
const TENGGANG_MS = 5_000;

function wajibMasuk(req: CallableRequest): string {
  if (!req.auth) throw new HttpsError("unauthenticated", "Silakan masuk terlebih dahulu.");
  return req.auth.uid;
}

function teksWajib(nilai: unknown, nama: string): string {
  if (typeof nilai !== "string" || nilai.length === 0 || nilai.length > 200 || nilai.includes("/")) {
    throw new HttpsError("invalid-argument", `Parameter ${nama} tidak valid.`);
  }
  return nilai;
}

async function ambilPengguna(uid: string): Promise<Pengguna> {
  const snap = await db().doc(`pengguna/${uid}`).get();
  if (!snap.exists) throw new HttpsError("failed-precondition", "Lengkapi profil terlebih dahulu.");
  return snap.data() as Pengguna;
}

async function wajibAdmin(uid: string): Promise<Pengguna> {
  const pengguna = await ambilPengguna(uid);
  if (pengguna.peran !== "admin") throw new HttpsError("permission-denied", "Hanya admin yang boleh melakukan ini.");
  return pengguna;
}

function refSesi(ujianId: string, uid: string) {
  return db().doc(`sesi/${ujianId}_${uid}`);
}

function soalSubtes(ujianId: string, subtesId: string) {
  return db().collection(`ujian/${ujianId}/soal`).where("subtesId", "==", subtesId);
}

function urutkanSoal(soal: Soal[]): Soal[] {
  return [...soal].sort((a, b) => (a.urutan ?? 0) - (b.urutan ?? 0));
}

function bacaSoal(snap: FirebaseFirestore.QuerySnapshot): Soal[] {
  return urutkanSoal(snap.docs.map((d) => ({ ...(d.data() as Omit<Soal, "id">), id: d.id })));
}

/** Soal yang dikirim ke peserta: tanpa kunci dan pembahasan, opsi sesuai urutan acak peserta. */
function soalUntukPeserta(soal: Soal, urutanOpsi?: string[]) {
  const opsi = soal.opsi ?? [];
  const opsiTerurut = urutanOpsi
    ? urutanOpsi.map((id) => opsi.find((o) => o.id === id)).filter((o): o is NonNullable<typeof o> => !!o)
    : opsi;
  return {
    id: soal.id,
    tipe: soal.tipe,
    teks: soal.teks,
    stimulusId: soal.stimulusId ?? null,
    opsi: opsiTerurut,
    pernyataan: soal.pernyataan ?? [],
    labelBs: soal.labelBs ?? ["Benar", "Salah"],
    isianAngka: soal.tipe === "isian" && (soal.kunci as { numerik?: boolean })?.numerik === true,
  };
}

/** Tutup satu pengerjaan dan catat hasilnya ke dokumen sesi. Dipanggil di dalam transaksi. */
function tutupPengerjaan(
  tx: Transaction,
  refKerja: DocumentReference,
  kerja: Pengerjaan,
  soal: Soal[],
  refSesiUjian: DocumentReference,
  sesi: Sesi,
  ujian: Ujian,
) {
  const terpakai = soal.filter((s) => kerja.soalIds.includes(s.id));
  const hasil = nilaiSubtes(terpakai, kerja.jawaban ?? {});
  tx.update(refKerja, { selesai: true, ditutup: FieldValue.serverTimestamp(), rincian: hasil.rincian });

  const subtesSelesai = Array.from(new Set([...(sesi.subtesSelesai ?? []), kerja.subtesId]));
  const semuaSelesai = ujian.subtes.every((s) => subtesSelesai.includes(s.id));
  const hasilSesi: Record<string, HasilSesi> = {
    ...(sesi.hasil ?? {}),
    [kerja.subtesId]: { benar: hasil.benar, jumlah: hasil.jumlah, pelanggaran: kerja.pelanggaran ?? 0 },
  };
  tx.update(refSesiUjian, {
    hasil: hasilSesi,
    subtesSelesai,
    subtesAktif: sesi.subtesAktif === kerja.subtesId ? null : sesi.subtesAktif,
    totalBenar: Object.values(hasilSesi).reduce((s, h) => s + h.benar, 0),
    pelanggaran: Object.values(hasilSesi).reduce((s, h) => s + (h.pelanggaran ?? 0), 0),
    status: semuaSelesai ? "selesai" : "berlangsung",
    ...(semuaSelesai ? { selesai: FieldValue.serverTimestamp() } : {}),
  });
  return { benar: hasil.benar, jumlah: hasil.jumlah, semuaSelesai };
}

async function bacaUjian(ujianId: string): Promise<Ujian> {
  const snap = await db().doc(`ujian/${ujianId}`).get();
  if (!snap.exists) throw new HttpsError("not-found", "Ujian tidak ditemukan.");
  return snap.data() as Ujian;
}

/**
 * Mulai (atau lanjutkan) satu subtes. Mengembalikan soal tanpa kunci, batas waktu dari server,
 * dan jawaban yang sudah tersimpan.
 */
export const mulaiSubtes = onCall(async (req) => {
  const uid = wajibMasuk(req);
  const ujianId = teksWajib(req.data?.ujianId, "ujianId");
  const subtesId = teksWajib(req.data?.subtesId, "subtesId");

  const pengguna = await ambilPengguna(uid);
  const ujian = await bacaUjian(ujianId);
  const admin = pengguna.peran === "admin";
  const sekarang = Timestamp.now();

  if (!admin) {
    if (ujian.status !== "terbit") throw new HttpsError("failed-precondition", "Ujian ini belum dibuka.");
    if (ujian.programId) {
      const pendaftar = await db().doc(`program/${ujian.programId}/pendaftar/${uid}`).get();
      if (!pendaftar.exists || pendaftar.get("status") !== "diterima") {
        throw new HttpsError("permission-denied", "Tryout ini khusus peserta bimbel yang sudah diterima.");
      }
    }
    if (sekarang.toMillis() < ujian.buka.toMillis()) throw new HttpsError("failed-precondition", "Ujian ini belum dimulai.");
    if (sekarang.toMillis() >= ujian.tutup.toMillis()) throw new HttpsError("failed-precondition", "Waktu ujian ini sudah berakhir.");
  }

  const indeks = ujian.subtes.findIndex((s) => s.id === subtesId);
  if (indeks < 0) throw new HttpsError("not-found", "Subtes tidak ditemukan.");
  const subtes = ujian.subtes[indeks];

  const refSesiUjian = refSesi(ujianId, uid);
  const refKerja = refSesiUjian.collection("pengerjaan").doc(subtesId);

  const status = await db().runTransaction(async (tx) => {
    const [snapSesi, snapKerja] = await Promise.all([tx.get(refSesiUjian), tx.get(refKerja)]);
    const sesi: Sesi = snapSesi.exists
      ? (snapSesi.data() as Sesi)
      : {
          uid,
          ujianId,
          nama: pengguna.nama,
          sekolah: pengguna.sekolah ?? "",
          status: "berlangsung",
          subtesAktif: null,
          subtesSelesai: [],
          hasil: {},
          uji: admin,
        };

    if (snapKerja.exists) {
      const kerja = snapKerja.data() as Pengerjaan;
      if (kerja.selesai) return "sudahSelesai" as const;
      if (kerja.batas.toMillis() + TENGGANG_MS > sekarang.toMillis()) return "lanjut" as const;
      const soal = bacaSoal(await tx.get(soalSubtes(ujianId, subtesId)));
      tutupPengerjaan(tx, refKerja, kerja, soal, refSesiUjian, sesi, ujian);
      return "waktuHabis" as const;
    }

    // Subtes lain yang masih aktif: tolak jika waktunya masih ada, tutup jika sudah habis.
    let refAktif: DocumentReference | null = null;
    let kerjaAktif: Pengerjaan | null = null;
    let soalAktif: Soal[] = [];
    if (sesi.subtesAktif && sesi.subtesAktif !== subtesId) {
      refAktif = refSesiUjian.collection("pengerjaan").doc(sesi.subtesAktif);
      const snapAktif = await tx.get(refAktif);
      if (snapAktif.exists) {
        kerjaAktif = snapAktif.data() as Pengerjaan;
        if (!kerjaAktif.selesai && kerjaAktif.batas.toMillis() + TENGGANG_MS > sekarang.toMillis()) {
          throw new HttpsError("failed-precondition", "Selesaikan subtes yang sedang berjalan terlebih dahulu.");
        }
        if (!kerjaAktif.selesai) soalAktif = bacaSoal(await tx.get(soalSubtes(ujianId, sesi.subtesAktif)));
      }
    }

    if (!ujian.pengaturan?.urutanBebas) {
      const sebelumnya = ujian.subtes.slice(0, indeks).map((s) => s.id);
      const selesai = new Set(sesi.subtesSelesai ?? []);
      if (kerjaAktif && !kerjaAktif.selesai) selesai.add(kerjaAktif.subtesId);
      const belum = sebelumnya.filter((id) => !selesai.has(id));
      if (belum.length > 0) {
        const nama = ujian.subtes.find((s) => s.id === belum[0])?.nama ?? belum[0];
        throw new HttpsError("failed-precondition", `Kerjakan subtes ${nama} terlebih dahulu.`);
      }
    }

    const soal = bacaSoal(await tx.get(soalSubtes(ujianId, subtesId)));
    if (soal.length === 0) throw new HttpsError("failed-precondition", "Subtes ini belum memiliki soal.");

    // Semua pembacaan selesai, mulai menulis.
    if (!snapSesi.exists) {
      tx.set(refSesiUjian, { ...sesi, mulai: FieldValue.serverTimestamp() });
    }
    if (refAktif && kerjaAktif && !kerjaAktif.selesai) {
      tutupPengerjaan(tx, refAktif, kerjaAktif, soalAktif, refSesiUjian, sesi, ujian);
    }

    const terurut = ujian.pengaturan?.acakSoal ? acakSoal(soal) : soal;
    const opsiUrutan: Record<string, string[]> = {};
    if (ujian.pengaturan?.acakOpsi) {
      for (const s of terurut) {
        if ((s.tipe === "pg" || s.tipe === "pgk") && s.opsi?.length) opsiUrutan[s.id] = acakDaftar(s.opsi.map((o) => o.id));
      }
    }
    const batasMs = admin
      ? sekarang.toMillis() + subtes.durasiDetik * 1000
      : Math.min(sekarang.toMillis() + subtes.durasiDetik * 1000, ujian.tutup.toMillis());

    const kerjaBaru: Pengerjaan = {
      uid,
      ujianId,
      subtesId,
      mulai: sekarang,
      batas: Timestamp.fromMillis(batasMs),
      soalIds: terurut.map((s) => s.id),
      opsiUrutan,
      jawaban: {},
      ragu: {},
      selesai: false,
      uji: admin,
    };
    tx.set(refKerja, kerjaBaru);
    tx.update(refSesiUjian, { subtesAktif: subtesId });
    return "baru" as const;
  });

  if (status === "sudahSelesai") throw new HttpsError("failed-precondition", "Subtes ini sudah selesai dikerjakan.");
  if (status === "waktuHabis") return { status, sekarang: Date.now() };

  const [snapKerja, snapSoal, snapStimulus] = await Promise.all([
    refKerja.get(),
    soalSubtes(ujianId, subtesId).get(),
    db().collection(`ujian/${ujianId}/stimulus`).where("subtesId", "==", subtesId).get(),
  ]);
  const kerja = snapKerja.data() as Pengerjaan;
  const peta = new Map(bacaSoal(snapSoal).map((s) => [s.id, s]));
  const soal = kerja.soalIds
    .map((id) => peta.get(id))
    .filter((s): s is Soal => !!s)
    .map((s) => soalUntukPeserta(s, kerja.opsiUrutan?.[s.id]));
  const dipakai = new Set(soal.map((s) => s.stimulusId).filter(Boolean));
  const stimulus = Object.fromEntries(
    snapStimulus.docs.filter((d) => dipakai.has(d.id)).map((d) => [d.id, { judul: d.get("judul") ?? "", teks: d.get("teks") ?? "" }]),
  );

  return {
    status,
    sekarang: Date.now(),
    mulai: kerja.mulai.toMillis(),
    batas: kerja.batas.toMillis(),
    subtes: { id: subtes.id, nama: subtes.nama, durasiDetik: subtes.durasiDetik },
    soal,
    stimulus,
    jawaban: kerja.jawaban ?? {},
    ragu: kerja.ragu ?? {},
    pelanggaran: kerja.pelanggaran ?? 0,
    pengawasan: {
      aktif: ujian.pengaturan?.pengawasan?.aktif !== false,
      batasPelanggaran: ujian.pengaturan?.pengawasan?.batasPelanggaran ?? 0,
      layarPenuh: ujian.pengaturan?.pengawasan?.layarPenuh === true,
    },
  };
});

/** Kumpulkan subtes yang sedang dikerjakan. Aman dipanggil berulang. */
export const kumpulkanSubtes = onCall(async (req) => {
  const uid = wajibMasuk(req);
  const ujianId = teksWajib(req.data?.ujianId, "ujianId");
  const subtesId = teksWajib(req.data?.subtesId, "subtesId");
  const ujian = await bacaUjian(ujianId);

  const refSesiUjian = refSesi(ujianId, uid);
  const refKerja = refSesiUjian.collection("pengerjaan").doc(subtesId);

  const hasil = await db().runTransaction(async (tx) => {
    const [snapSesi, snapKerja] = await Promise.all([tx.get(refSesiUjian), tx.get(refKerja)]);
    if (!snapSesi.exists || !snapKerja.exists) throw new HttpsError("not-found", "Pengerjaan tidak ditemukan.");
    const sesi = snapSesi.data() as Sesi;
    const kerja = snapKerja.data() as Pengerjaan;
    if (kerja.selesai) {
      const h = sesi.hasil?.[subtesId];
      return { benar: h?.benar ?? 0, jumlah: h?.jumlah ?? 0, semuaSelesai: sesi.status === "selesai" };
    }
    const soal = bacaSoal(await tx.get(soalSubtes(ujianId, subtesId)));
    return tutupPengerjaan(tx, refKerja, kerja, soal, refSesiUjian, sesi, ujian);
  });

  const tampilkan = ujian.pengaturan?.tampilkanHasil === "segera";
  return {
    semuaSelesai: hasil.semuaSelesai,
    ...(tampilkan ? { benar: hasil.benar, jumlah: hasil.jumlah } : {}),
  };
});

/**
 * Soal lengkap dengan kunci, pembahasan, dan jawaban peserta.
 * Untuk peserta: hanya setelah ujian ditutup dan pembahasan diizinkan. Admin selalu boleh.
 */
export const pembahasan = onCall(async (req) => {
  const uid = wajibMasuk(req);
  const ujianId = teksWajib(req.data?.ujianId, "ujianId");
  const pengguna = await ambilPengguna(uid);
  const ujian = await bacaUjian(ujianId);
  const admin = pengguna.peran === "admin";

  if (!admin) {
    if (Date.now() < ujian.tutup.toMillis()) throw new HttpsError("failed-precondition", "Pembahasan tersedia setelah ujian ditutup.");
    if (!ujian.pengaturan?.tampilkanPembahasan) throw new HttpsError("permission-denied", "Pembahasan ujian ini tidak dibuka.");
  }

  const refSesiUjian = refSesi(ujianId, uid);
  const [snapSoal, snapStimulus, snapKerja] = await Promise.all([
    db().collection(`ujian/${ujianId}/soal`).get(),
    db().collection(`ujian/${ujianId}/stimulus`).get(),
    refSesiUjian.collection("pengerjaan").get(),
  ]);
  if (!admin && snapKerja.empty) throw new HttpsError("permission-denied", "Kamu belum mengikuti ujian ini.");

  const jawaban: Record<string, unknown> = {};
  for (const d of snapKerja.docs) Object.assign(jawaban, (d.data() as Pengerjaan).jawaban ?? {});

  const semuaSoal = bacaSoal(snapSoal);
  const urutanSubtes = new Map(ujian.subtes.map((s, i) => [s.id, i]));
  semuaSoal.sort((a, b) => (urutanSubtes.get(a.subtesId) ?? 0) - (urutanSubtes.get(b.subtesId) ?? 0) || a.urutan - b.urutan);

  return {
    soal: semuaSoal.map((s) => ({
      ...soalUntukPeserta(s),
      subtesId: s.subtesId,
      kunci: s.kunci,
      pembahasan: s.pembahasan ?? "",
      jawaban: jawaban[s.id] ?? null,
      benar: nilaiSubtes([s], jawaban).benar === 1,
    })),
    stimulus: Object.fromEntries(snapStimulus.docs.map((d) => [d.id, { judul: d.get("judul") ?? "", teks: d.get("teks") ?? "" }])),
  };
});

/**
 * Admin: tutup pengerjaan yang waktunya sudah habis, nilai ulang semua jawaban dengan kunci terbaru,
 * lalu hitung skor berbobot (skala 200-1000) per subtes.
 */
export const hitungSkor = onCall({ timeoutSeconds: 300, memory: "512MiB" }, async (req) => {
  const uid = wajibMasuk(req);
  await wajibAdmin(uid);
  const ujianId = teksWajib(req.data?.ujianId, "ujianId");
  const ujian = await bacaUjian(ujianId);
  if (Date.now() < ujian.tutup.toMillis()) {
    throw new HttpsError("failed-precondition", "Skor dihitung setelah ujian ditutup, supaya peserta yang masih mengerjakan tidak terganggu.");
  }

  const [snapSesi, snapSoal] = await Promise.all([
    db().collection("sesi").where("ujianId", "==", ujianId).get(),
    db().collection(`ujian/${ujianId}/soal`).get(),
  ]);
  const soal = bacaSoal(snapSoal);
  const sesiPeserta = snapSesi.docs.filter((d) => d.get("uji") !== true);
  const sekarang = Date.now();

  const kerjaPerSesi = await Promise.all(sesiPeserta.map((d) => d.ref.collection("pengerjaan").get()));

  const penulis = db().bulkWriter();
  const hasilBaru: Record<string, Record<string, HasilSesi>> = {};
  const statistik: Record<string, { peserta: number; rataSkor: number }> = {};

  for (const subtes of ujian.subtes) {
    const soalSubtesIni = soal.filter((s) => s.subtesId === subtes.id);
    const ids = soalSubtesIni.map((s) => s.id);
    const peserta: { sesiId: string; rincian: Record<string, boolean>; benar: number; pelanggaran: number }[] = [];

    sesiPeserta.forEach((sesiDoc, i) => {
      const kerjaDoc = kerjaPerSesi[i].docs.find((d) => d.id === subtes.id);
      if (!kerjaDoc) return;
      const kerja = kerjaDoc.data() as Pengerjaan;
      const sudahHabis = kerja.selesai || kerja.batas.toMillis() + TENGGANG_MS <= sekarang;
      if (!sudahHabis) return;
      const hasil = nilaiSubtes(soalSubtesIni.filter((s) => kerja.soalIds.includes(s.id)), kerja.jawaban ?? {});
      penulis.update(kerjaDoc.ref, { selesai: true, rincian: hasil.rincian });
      peserta.push({ sesiId: sesiDoc.id, rincian: hasil.rincian, benar: hasil.benar, pelanggaran: kerja.pelanggaran ?? 0 });
    });

    const { skor } = skorBerbobot(peserta.map((p) => p.rincian), ids);
    peserta.forEach((p, i) => {
      hasilBaru[p.sesiId] ??= {};
      hasilBaru[p.sesiId][subtes.id] = { benar: p.benar, jumlah: ids.length, skor: skor[i], pelanggaran: p.pelanggaran };
    });
    statistik[subtes.id] = {
      peserta: peserta.length,
      rataSkor: skor.length ? Math.round((skor.reduce((a, b) => a + b, 0) / skor.length) * 100) / 100 : 0,
    };
  }

  for (const sesiDoc of sesiPeserta) {
    const hasil = hasilBaru[sesiDoc.id] ?? {};
    const daftarSkor = Object.values(hasil).map((h) => h.skor ?? 0);
    const selesaiSemua = ujian.subtes.every((s) => hasil[s.id]);
    penulis.update(sesiDoc.ref, {
      hasil,
      subtesSelesai: Object.keys(hasil),
      subtesAktif: null,
      totalBenar: Object.values(hasil).reduce((s, h) => s + h.benar, 0),
      pelanggaran: Object.values(hasil).reduce((s, h) => s + (h.pelanggaran ?? 0), 0),
      skorRata: daftarSkor.length ? Math.round((daftarSkor.reduce((a, b) => a + b, 0) / daftarSkor.length) * 100) / 100 : null,
      status: selesaiSemua ? "selesai" : sesiDoc.get("status"),
    });
  }
  penulis.update(db().doc(`ujian/${ujianId}`), { skorDihitung: FieldValue.serverTimestamp(), statistik });
  await penulis.close();

  return { peserta: sesiPeserta.length, statistik };
});
