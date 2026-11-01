import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../data/model.dart';

/// Akses Firestore dan Storage.
class Repo {
  Repo(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;

  CollectionReference<Json> get _pengguna => _db.collection('pengguna');
  CollectionReference<Json> get _ujian => _db.collection('ujian');
  CollectionReference<Json> _soal(String ujianId) => _ujian.doc(ujianId).collection('soal');
  CollectionReference<Json> _stimulus(String ujianId) => _ujian.doc(ujianId).collection('stimulus');

  // Pengguna

  Stream<Pengguna?> pantauPengguna(String uid) => _pengguna.doc(uid).snapshots().map((d) => d.exists ? Pengguna.dariDok(d) : null);

  Future<void> simpanProfilBaru({
    required String uid,
    required String email,
    required String nama,
    required String sekolah,
    required String kelas,
    required String kota,
    required String noHp,
  }) => _pengguna.doc(uid).set({
    'nama': nama,
    'email': email,
    'peran': 'siswa',
    'sekolah': sekolah,
    'kelas': kelas,
    'kota': kota,
    'noHp': noHp,
    'setujuData': true,
    'dibuat': FieldValue.serverTimestamp(),
    'diperbarui': FieldValue.serverTimestamp(),
  });

  Future<void> perbaruiProfil(
    String uid, {
    required String nama,
    required String sekolah,
    required String kelas,
    required String kota,
    required String noHp,
  }) => _pengguna.doc(uid).update({
    'nama': nama,
    'sekolah': sekolah,
    'kelas': kelas,
    'kota': kota,
    'noHp': noHp,
    'diperbarui': FieldValue.serverTimestamp(),
  });

  Stream<List<Pengguna>> pantauSemuaPengguna() => _pengguna.orderBy('nama').snapshots().map((s) => s.docs.map(Pengguna.dariDok).toList());

  Future<void> aturPeran(String uid, Peran peran) =>
      _pengguna.doc(uid).update({'peran': peran.name, 'diperbarui': FieldValue.serverTimestamp()});

  // Ujian

  Stream<List<Ujian>> pantauUjianTerbit() => _ujian
      .where('status', isEqualTo: 'terbit')
      .snapshots()
      .map((s) => s.docs.map(Ujian.dariDok).toList()..sort((a, b) => b.buka.compareTo(a.buka)));

  Stream<List<Ujian>> pantauSemuaUjian() =>
      _ujian.snapshots().map((s) => s.docs.map(Ujian.dariDok).toList()..sort((a, b) => b.buka.compareTo(a.buka)));

  Stream<Ujian?> pantauUjian(String id) => _ujian.doc(id).snapshots().map((d) => d.exists ? Ujian.dariDok(d) : null);

  Future<String> buatUjian({
    required String judul,
    required List<Subtes> subtes,
    required DateTime buka,
    required DateTime tutup,
    required String uid,
  }) async {
    final ref = await _ujian.add({
      'judul': judul,
      'deskripsi': '',
      'status': 'draf',
      'buka': Timestamp.fromDate(buka),
      'tutup': Timestamp.fromDate(tutup),
      'subtes': subtes.map((s) => s.keMap()).toList(),
      'pengaturan': const PengaturanUjian(acakOpsi: true).keMap(),
      'jumlahSoal': {for (final s in subtes) s.id: 0},
      'dibuatOleh': uid,
      'dibuat': FieldValue.serverTimestamp(),
      'diperbarui': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> perbaruiUjian(String id, Json data) => _ujian.doc(id).update({...data, 'diperbarui': FieldValue.serverTimestamp()});

  Future<void> simpanSubtes(String id, List<Subtes> subtes) => perbaruiUjian(id, {'subtes': subtes.map((s) => s.keMap()).toList()});

  Future<bool> adaPeserta(String ujianId) async =>
      (await _db.collection('sesi').where('ujianId', isEqualTo: ujianId).limit(1).get()).docs.isNotEmpty;

  Future<void> hapusUjian(String id) async {
    for (final koleksi in [_soal(id), _stimulus(id)]) {
      final snap = await koleksi.get();
      final batch = _db.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
    await _ujian.doc(id).delete();
  }

  // Soal dan stimulus

  Stream<List<Soal>> pantauSoal(String ujianId) =>
      _soal(ujianId).snapshots().map((s) => s.docs.map(Soal.dariDok).toList()..sort((a, b) => a.urutan.compareTo(b.urutan)));

  Future<Soal?> ambilSoal(String ujianId, String soalId) async {
    final d = await _soal(ujianId).doc(soalId).get();
    return d.exists ? Soal.dariDok(d) : null;
  }

  Future<String> simpanSoal(String ujianId, Soal soal) async {
    if (soal.id.isEmpty) {
      final ref = await _soal(ujianId).add(soal.keMap());
      await sinkronJumlahSoal(ujianId);
      return ref.id;
    }
    await _soal(ujianId).doc(soal.id).set(soal.keMap());
    await sinkronJumlahSoal(ujianId);
    return soal.id;
  }

  Future<void> hapusSoal(String ujianId, String soalId) async {
    await _soal(ujianId).doc(soalId).delete();
    await sinkronJumlahSoal(ujianId);
  }

  /// Simpan urutan baru (1, 2, 3, ...) untuk daftar soal satu subtes.
  Future<void> aturUrutanSoal(String ujianId, List<Soal> terurut) async {
    final batch = _db.batch();
    for (var i = 0; i < terurut.length; i++) {
      batch.update(_soal(ujianId).doc(terurut[i].id), {'urutan': i + 1});
    }
    await batch.commit();
  }

  Future<void> sinkronJumlahSoal(String ujianId) async {
    final snap = await _soal(ujianId).get();
    final jumlah = <String, int>{};
    for (final d in snap.docs) {
      final subtes = d.data()['subtesId'] as String? ?? '';
      jumlah[subtes] = (jumlah[subtes] ?? 0) + 1;
    }
    await _ujian.doc(ujianId).update({'jumlahSoal': jumlah});
  }

  Stream<List<Stimulus>> pantauStimulus(String ujianId) =>
      _stimulus(ujianId).snapshots().map((s) => s.docs.map(Stimulus.dariDok).toList()..sort((a, b) => a.judul.compareTo(b.judul)));

  Future<String> simpanStimulus(String ujianId, Stimulus s) async {
    if (s.id.isEmpty) return (await _stimulus(ujianId).add(s.keMap())).id;
    await _stimulus(ujianId).doc(s.id).set(s.keMap());
    return s.id;
  }

  Future<void> hapusStimulus(String ujianId, String id) => _stimulus(ujianId).doc(id).delete();

  // Sesi dan jawaban

  Stream<List<Sesi>> pantauSesiSaya(String uid) =>
      _db.collection('sesi').where('uid', isEqualTo: uid).snapshots().map((s) => s.docs.map(Sesi.dariDok).toList());

  Stream<Sesi?> pantauSesi(String ujianId, String uid) =>
      _db.doc('sesi/${ujianId}_$uid').snapshots().map((d) => d.exists ? Sesi.dariDok(d) : null);

  Stream<List<Sesi>> pantauSesiUjian(String ujianId) => _db
      .collection('sesi')
      .where('ujianId', isEqualTo: ujianId)
      .snapshots()
      .map((s) => s.docs.map(Sesi.dariDok).where((s) => !s.uji).toList());

  DocumentReference<Json> _pengerjaan(String ujianId, String uid, String subtesId) => _db.doc('sesi/${ujianId}_$uid/pengerjaan/$subtesId');

  /// Simpan satu jawaban. `null` menghapus jawaban.
  Future<void> simpanJawaban(String ujianId, String uid, String subtesId, String soalId, Object? jawaban) =>
      _pengerjaan(ujianId, uid, subtesId).update({
        FieldPath(['jawaban', soalId]): jawaban ?? FieldValue.delete(),
      });

  Future<void> simpanRagu(String ujianId, String uid, String subtesId, String soalId, bool ragu) =>
      _pengerjaan(ujianId, uid, subtesId).update({
        FieldPath(['ragu', soalId]): ragu ? true : FieldValue.delete(),
      });

  // Gambar soal

  Future<String> unggahGambar(String ujianId, Uint8List data, String namaBerkas, String tipeMime) async {
    final aman = namaBerkas.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = _storage.ref('soal/$ujianId/${DateTime.now().millisecondsSinceEpoch}-$aman');
    await ref.putData(data, SettableMetadata(contentType: tipeMime));
    return ref.getDownloadURL();
  }
}
