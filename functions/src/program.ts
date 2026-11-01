import { FieldValue, getFirestore, Timestamp } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { periksaPendaftaran, type JenisProgram } from "./pendaftaran.js";

const db = () => getFirestore();

interface Program {
  jenis: JenisProgram;
  judul: string;
  status: "draf" | "terbit";
  buka: Timestamp;
  tutup: Timestamp;
  kuota?: number;
  seleksi?: "otomatis" | "manual";
  jumlahPendaftar?: number;
}

interface Pendaftar {
  status: "menunggu" | "diterima" | "ditolak";
}

function idValid(v: unknown): string {
  if (typeof v !== "string" || v.length === 0 || v.length > 200 || v.includes("/")) {
    throw new HttpsError("invalid-argument", "Program tidak valid.");
  }
  return v;
}

async function bacaProgram(id: string): Promise<Program> {
  const snap = await db().doc(`program/${id}`).get();
  if (!snap.exists || snap.get("status") !== "terbit") throw new HttpsError("not-found", "Program tidak ditemukan.");
  return snap.data() as Program;
}

function periksaPeriode(p: Program) {
  const sekarang = Date.now();
  if (sekarang < p.buka.toMillis()) throw new HttpsError("failed-precondition", "Pendaftaran belum dibuka.");
  if (sekarang >= p.tutup.toMillis()) throw new HttpsError("failed-precondition", "Pendaftaran sudah ditutup.");
}

/**
 * Daftar (atau perbarui data pendaftaran) ke program. Data yang bisa dipakai ulang disimpan
 * ke profil, supaya pendaftaran berikutnya (mis. seminar lalu bimbel) terisi otomatis.
 */
export const daftarProgram = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Silakan masuk terlebih dahulu.");
  const uid = req.auth.uid;
  const programId = idValid(req.data?.programId);

  const refPengguna = db().doc(`pengguna/${uid}`);
  if (!(await refPengguna.get()).exists) throw new HttpsError("failed-precondition", "Lengkapi profil terlebih dahulu.");

  const program = await bacaProgram(programId);
  periksaPeriode(program);

  const hasil = periksaPendaftaran(program.jenis, req.data?.data);
  if (hasil.galat !== null) throw new HttpsError("invalid-argument", hasil.galat);
  const data = hasil.data;

  const refProgram = db().doc(`program/${programId}`);
  const refPendaftar = refProgram.collection("pendaftar").doc(uid);

  const status = await db().runTransaction(async (tx) => {
    const [snapProgram, snapPendaftar] = await Promise.all([tx.get(refProgram), tx.get(refPendaftar)]);
    const p = snapProgram.data() as Program;

    let statusAkhir: Pendaftar["status"];
    if (snapPendaftar.exists) {
      statusAkhir = (snapPendaftar.data() as Pendaftar).status;
      if (statusAkhir === "ditolak") throw new HttpsError("failed-precondition", "Pendaftaranmu di program ini tidak diterima.");
      tx.update(refPendaftar, { data, diperbarui: FieldValue.serverTimestamp() });
    } else {
      const kuota = p.kuota ?? 0;
      if (kuota > 0 && (p.jumlahPendaftar ?? 0) >= kuota) {
        throw new HttpsError("resource-exhausted", "Kuota pendaftaran sudah penuh.");
      }
      statusAkhir = p.seleksi === "otomatis" ? "diterima" : "menunggu";
      tx.set(refPendaftar, {
        uid,
        email: req.auth?.token.email ?? "",
        programId,
        jenis: p.jenis,
        data,
        status: statusAkhir,
        kelas: null,
        dibuat: FieldValue.serverTimestamp(),
        diperbarui: FieldValue.serverTimestamp(),
      });
      tx.update(refProgram, { jumlahPendaftar: FieldValue.increment(1) });
    }

    const profil: Record<string, unknown> = {
      nama: data.nama,
      sekolah: data.sekolah,
      kelas: data.kelas,
      noHp: data.noHp,
      alamat: data.alamat,
      minat: data.minat,
      diperbarui: FieldValue.serverTimestamp(),
    };
    if (data.kota) profil.kota = data.kota;
    if (program.jenis === "bimbel") {
      profil.tanggalLahir = data.tanggalLahir;
      profil.eligibleSnbp = data.eligibleSnbp;
      profil.nomorSnbp = data.nomorSnbp ?? "";
    }
    tx.set(refPengguna, profil, { merge: true });
    return statusAkhir;
  });

  return { status };
});

/** Batalkan pendaftaran selama periode pendaftaran masih dibuka dan belum diputuskan admin. */
export const batalDaftarProgram = onCall(async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Silakan masuk terlebih dahulu.");
  const uid = req.auth.uid;
  const programId = idValid(req.data?.programId);
  const program = await bacaProgram(programId);
  periksaPeriode(program);

  const refProgram = db().doc(`program/${programId}`);
  const refPendaftar = refProgram.collection("pendaftar").doc(uid);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(refPendaftar);
    if (!snap.exists) throw new HttpsError("not-found", "Kamu belum terdaftar di program ini.");
    const status = (snap.data() as Pendaftar).status;
    const bolehBatal = status === "menunggu" || (status === "diterima" && program.seleksi === "otomatis");
    if (!bolehBatal) throw new HttpsError("failed-precondition", "Pendaftaran ini sudah diputuskan panitia. Hubungi panitia untuk membatalkan.");
    tx.delete(refPendaftar);
    tx.update(refProgram, { jumlahPendaftar: FieldValue.increment(-1) });
  });
  return { dibatalkan: true };
});
