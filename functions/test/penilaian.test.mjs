import assert from "node:assert/strict";
import { test } from "node:test";
import { acakSoal, jawabanBenar, keAngka, nilaiSubtes, skorBerbobot } from "../lib/penilaian.js";

test("pilihan ganda: hanya kunci yang benar", () => {
  const soal = { tipe: "pg", kunci: "c" };
  assert.equal(jawabanBenar(soal, "c"), true);
  assert.equal(jawabanBenar(soal, "a"), false);
  assert.equal(jawabanBenar(soal, undefined), false);
  assert.equal(jawabanBenar(soal, ["c"]), false);
});

test("pilihan ganda kompleks: semua pilihan harus tepat", () => {
  const soal = { tipe: "pgk", kunci: ["a", "d"] };
  assert.equal(jawabanBenar(soal, ["d", "a"]), true);
  assert.equal(jawabanBenar(soal, ["a"]), false);
  assert.equal(jawabanBenar(soal, ["a", "d", "e"]), false);
  assert.equal(jawabanBenar(soal, []), false);
});

test("tabel benar-salah: setiap pernyataan harus tepat dan terisi", () => {
  const soal = {
    tipe: "bs",
    pernyataan: [{ id: "p1" }, { id: "p2" }, { id: "p3" }],
    kunci: { p1: true, p2: false, p3: true },
  };
  assert.equal(jawabanBenar(soal, { p1: true, p2: false, p3: true }), true);
  assert.equal(jawabanBenar(soal, { p1: true, p2: false }), false);
  assert.equal(jawabanBenar(soal, { p1: true, p2: true, p3: true }), false);
});

test("isian angka: koma desimal, pecahan, dan toleransi", () => {
  assert.equal(keAngka("2,5"), 2.5);
  assert.equal(keAngka("2.5"), 2.5);
  assert.equal(keAngka("1.250,5"), 1250.5);
  assert.equal(keAngka("3/4"), 0.75);
  assert.equal(keAngka("abc"), null);
  assert.equal(keAngka("1/0"), null);

  const soal = { tipe: "isian", kunci: { jawaban: ["0,75"], numerik: true } };
  assert.equal(jawabanBenar(soal, "3/4"), true);
  assert.equal(jawabanBenar(soal, " 0.75 "), true);
  assert.equal(jawabanBenar(soal, "0,7"), false);

  const toleran = { tipe: "isian", kunci: { jawaban: ["3,14"], numerik: true, toleransi: 0.01 } };
  assert.equal(jawabanBenar(toleran, "3,15"), true);
  assert.equal(jawabanBenar(toleran, "3,2"), false);
});

test("isian teks: tidak peka huruf besar dan spasi berlebih", () => {
  const soal = { tipe: "isian", kunci: { jawaban: ["fotosintesis", "foto sintesis"], numerik: false } };
  assert.equal(jawabanBenar(soal, "  Fotosintesis "), true);
  assert.equal(jawabanBenar(soal, "foto   sintesis"), true);
  assert.equal(jawabanBenar(soal, "respirasi"), false);
  assert.equal(jawabanBenar(soal, ""), false);
});

test("nilai subtes menghitung jumlah benar", () => {
  const soal = [
    { id: "s1", tipe: "pg", kunci: "a" },
    { id: "s2", tipe: "pg", kunci: "b" },
    { id: "s3", tipe: "isian", kunci: { jawaban: ["10"], numerik: true } },
  ];
  const hasil = nilaiSubtes(soal, { s1: "a", s2: "c", s3: "10,0" });
  assert.equal(hasil.benar, 2);
  assert.equal(hasil.jumlah, 3);
  assert.deepEqual(hasil.rincian, { s1: true, s2: false, s3: true });
});

test("skor berbobot: skala 200-1000 dan soal sulit lebih berharga", () => {
  const ids = ["mudah", "sulit"];
  const rincian = [
    { mudah: true, sulit: true },
    { mudah: true, sulit: false },
    { mudah: false, sulit: true },
    { mudah: true, sulit: false },
  ];
  const { skor, bobot } = skorBerbobot(rincian, ids);
  assert.equal(skor[0], 1000);
  assert.ok(bobot.sulit > bobot.mudah);
  assert.ok(skor[2] > skor[1], "menjawab soal sulit dinilai lebih tinggi daripada soal mudah");
  assert.equal(skorBerbobot([{ mudah: false, sulit: false }], ids).skor[0], 200);
});

test("acak soal menjaga soal satu bacaan tetap berdampingan", () => {
  const soal = [
    { id: "1", stimulusId: "A" },
    { id: "2", stimulusId: "A" },
    { id: "3", stimulusId: null },
    { id: "4", stimulusId: "B" },
    { id: "5", stimulusId: "B" },
    { id: "6", stimulusId: null },
  ];
  for (let n = 0; n < 50; n++) {
    const hasil = acakSoal(soal).map((s) => s.id);
    assert.equal(hasil.length, 6);
    assert.equal(Math.abs(hasil.indexOf("1") - hasil.indexOf("2")), 1);
    assert.equal(Math.abs(hasil.indexOf("4") - hasil.indexOf("5")), 1);
  }
});
