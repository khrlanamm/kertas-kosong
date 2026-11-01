import assert from "node:assert/strict";
import { test } from "node:test";
import { normalNoHp, periksaPendaftaran, tanggalLahirValid } from "../lib/pendaftaran.js";

const dasar = {
  nama: "  Adik   Pejuang ",
  sekolah: "SMAN 1 Dukun",
  kelas: "Kelas XII",
  kota: "Gresik",
  noHp: "+62 812-3456-7890",
  alamat: "Jl. Raya Dukun No. 1, Gresik",
  minat: [{ kampus: "UNESA", jurusan: "Pendidikan Matematika" }],
};

test("nomor HP dinormalkan ke 08...", () => {
  assert.equal(normalNoHp("+62 812-3456-7890"), "081234567890");
  assert.equal(normalNoHp("6281234567890"), "081234567890");
  assert.equal(normalNoHp("0812 3456 7890"), "081234567890");
  assert.equal(normalNoHp("12345"), null);
  assert.equal(normalNoHp("021555123"), null);
});

test("tanggal lahir harus ada di kalender dan usianya masuk akal", () => {
  const sekarang = new Date("2027-02-01T00:00:00Z");
  assert.equal(tanggalLahirValid("2009-05-17", sekarang), true);
  assert.equal(tanggalLahirValid("2009-02-30", sekarang), false);
  assert.equal(tanggalLahirValid("17-05-2009", sekarang), false);
  assert.equal(tanggalLahirValid("2024-01-01", sekarang), false);
});

test("pendaftaran seminar butuh data dasar dan minat", () => {
  const ok = periksaPendaftaran("seminar", dasar);
  assert.equal(ok.galat, null);
  assert.equal(ok.data.nama, "Adik Pejuang");
  assert.equal(ok.data.noHp, "081234567890");
  assert.equal("tanggalLahir" in ok.data, false);

  assert.match(periksaPendaftaran("seminar", { ...dasar, alamat: "" }).galat, /Alamat/);
  assert.match(periksaPendaftaran("seminar", { ...dasar, minat: [] }).galat, /pilihan jurusan/);
  assert.match(periksaPendaftaran("seminar", { ...dasar, minat: [{ kampus: "UNESA", jurusan: "" }] }).galat, /jurusan dan kampus/);
  assert.match(periksaPendaftaran("seminar", { ...dasar, noHp: "123" }).galat, /Nomor HP/);
});

test("pendaftaran bimbel butuh tanggal lahir dan status SNBP", () => {
  const sekarang = new Date("2027-02-01T00:00:00Z");
  assert.match(periksaPendaftaran("bimbel", dasar, sekarang).galat, /Tanggal lahir/);
  const tanpaNomor = periksaPendaftaran("bimbel", { ...dasar, tanggalLahir: "2009-05-17", eligibleSnbp: "ya" }, sekarang);
  assert.match(tanpaNomor.galat, /nomor pendaftaran SNBP/);

  const eligible = periksaPendaftaran("bimbel", { ...dasar, tanggalLahir: "2009-05-17", eligibleSnbp: "ya", nomorSnbp: "4270 0123 45" }, sekarang);
  assert.equal(eligible.galat, null);
  assert.equal(eligible.data.nomorSnbp, "4270012345");

  const tidak = periksaPendaftaran("bimbel", { ...dasar, tanggalLahir: "2009-05-17", eligibleSnbp: "tidak", nomorSnbp: "abaikan" }, sekarang);
  assert.equal(tidak.galat, null);
  assert.equal(tidak.data.nomorSnbp, "");
});
