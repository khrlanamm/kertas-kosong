import 'dart:math';

import '../data/model.dart';

/// Susunan subtes UTBK-SNBT 2026: 160 soal, 195 menit, tanpa jeda.
const templateUtbk = [
  Subtes(id: 'pu', nama: 'Penalaran Umum', singkatan: 'PU', durasiDetik: 1800, targetSoal: 30),
  Subtes(id: 'ppu', nama: 'Pengetahuan dan Pemahaman Umum', singkatan: 'PPU', durasiDetik: 900, targetSoal: 20),
  Subtes(id: 'pbm', nama: 'Pemahaman Bacaan dan Menulis', singkatan: 'PBM', durasiDetik: 1500, targetSoal: 20),
  Subtes(id: 'pk', nama: 'Pengetahuan Kuantitatif', singkatan: 'PK', durasiDetik: 1200, targetSoal: 20),
  Subtes(id: 'lbi', nama: 'Literasi dalam Bahasa Indonesia', singkatan: 'LBI', durasiDetik: 2550, targetSoal: 30),
  Subtes(id: 'lbe', nama: 'Literasi dalam Bahasa Inggris', singkatan: 'LBE', durasiDetik: 1200, targetSoal: 20),
  Subtes(id: 'pm', nama: 'Penalaran Matematika', singkatan: 'PM', durasiDetik: 2550, targetSoal: 20),
];

final _acak = Random.secure();

/// ID pendek acak, aman dipakai sebagai ID dokumen atau ID pilihan jawaban.
String idAcak([String awalan = '']) {
  const huruf = 'abcdefghijkmnpqrstuvwxyz23456789';
  return awalan + List.generate(8, (_) => huruf[_acak.nextInt(huruf.length)]).join();
}

/// Huruf A, B, C, ... untuk urutan pilihan jawaban yang ditampilkan.
String hurufOpsi(int i) => String.fromCharCode(65 + i);
