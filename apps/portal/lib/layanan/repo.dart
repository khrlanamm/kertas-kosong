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

  /// Catat satu kejadian pengawasan (pindah tab, salin, ...). Hanya bisa bertambah (lihat rules).
  Future<void> catatPelanggaran(String ujianId, String uid, String subtesId, String jenis) => _pengerjaan(ujianId, uid, subtesId).update({
    'pelanggaran': FieldValue.increment(1),
    'jejak': FieldValue.arrayUnion(['$jenis@${DateTime.now().millisecondsSinceEpoch}']),
  });

  /// Rincian catatan pengawasan satu peserta, untuk admin.
  Future<List<({String subtesId, String jenis, DateTime waktu})>> ambilJejak(String sesiId) async {
    final snap = await _db.collection('sesi/$sesiId/pengerjaan').get();
    final hasil = <({String subtesId, String jenis, DateTime waktu})>[];
    for (final d in snap.docs) {
      for (final j in (d.data()['jejak'] as List? ?? const [])) {
        final bagian = '$j'.split('@');
        if (bagian.length != 2) continue;
        hasil.add((subtesId: d.id, jenis: bagian[0], waktu: DateTime.fromMillisecondsSinceEpoch(int.tryParse(bagian[1]) ?? 0)));
      }
    }
    return hasil..sort((a, b) => a.waktu.compareTo(b.waktu));
  }

  // Program, pendaftar, dan jadwal

  CollectionReference<Json> get _program => _db.collection('program');

  Stream<List<Program>> pantauProgramTerbit() => _program
      .where('status', isEqualTo: 'terbit')
      .snapshots()
      .map((s) => s.docs.map(Program.dariDok).toList()..sort((a, b) => b.buka.compareTo(a.buka)));

  Stream<List<Program>> pantauSemuaProgram() =>
      _program.snapshots().map((s) => s.docs.map(Program.dariDok).toList()..sort((a, b) => b.buka.compareTo(a.buka)));

  Stream<Program?> pantauProgram(String id) => _program.doc(id).snapshots().map((d) => d.exists ? Program.dariDok(d) : null);

  Future<String> buatProgram({required JenisProgram jenis, required String judul, required String uid}) async {
    final buka = DateTime.now();
    final ref = await _program.add({
      'jenis': jenis.name,
      'judul': judul,
      'deskripsi': '',
      'status': 'draf',
      'buka': Timestamp.fromDate(buka),
      'tutup': Timestamp.fromDate(buka.add(const Duration(days: 14))),
      'kuota': 0,
      'seleksi': jenis == JenisProgram.bimbel ? 'manual' : 'otomatis',
      'kelas': jenis == JenisProgram.bimbel ? ['A', 'B'] : <String>[],
      'jumlahPendaftar': 0,
      'waktuAcara': '',
      'tempat': '',
      'dibuatOleh': uid,
      'dibuat': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> perbaruiProgram(String id, Json data) => _program.doc(id).update({...data, 'diperbarui': FieldValue.serverTimestamp()});

  Future<void> hapusProgram(String id) async {
    final jadwal = await _program.doc(id).collection('jadwal').get();
    final batch = _db.batch();
    for (final d in jadwal.docs) {
      batch.delete(d.reference);
    }
    batch.delete(_program.doc(id));
    await batch.commit();
  }

  Stream<List<Pendaftar>> pantauPendaftar(String programId) =>
      _program.doc(programId).collection('pendaftar').snapshots().map((s) => s.docs.map(Pendaftar.dariDok).toList());

  Future<void> aturPendaftar(String programId, String uid, {required StatusPendaftar status, String? kelas, String? catatanAdmin}) =>
      _program.doc(programId).collection('pendaftar').doc(uid).update({
        'status': status.name,
        'kelas': kelas,
        'catatanAdmin': ?catatanAdmin,
        'diperbarui': FieldValue.serverTimestamp(),
      });

  /// Atur banyak pendaftar sekaligus (mis. bagi kelas). Maksimal 500 per batch.
  Future<void> aturBanyakPendaftar(String programId, Map<String, ({StatusPendaftar status, String? kelas})> perubahan) async {
    final entri = perubahan.entries.toList();
    for (var i = 0; i < entri.length; i += 450) {
      final batch = _db.batch();
      for (final e in entri.skip(i).take(450)) {
        batch.update(_program.doc(programId).collection('pendaftar').doc(e.key), {
          'status': e.value.status.name,
          'kelas': e.value.kelas,
          'diperbarui': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    }
  }

  Stream<List<Pendaftar>> pantauPendaftaranSaya(String uid) =>
      _db.collectionGroup('pendaftar').where('uid', isEqualTo: uid).snapshots().map((s) => s.docs.map(Pendaftar.dariDok).toList());

  Stream<List<Jadwal>> pantauJadwal(String programId) => _program
      .doc(programId)
      .collection('jadwal')
      .snapshots()
      .map((s) => s.docs.map(Jadwal.dariDok).toList()..sort((a, b) => a.mulai.compareTo(b.mulai)));

  Future<void> simpanJadwal(String programId, Jadwal j) async {
    final koleksi = _program.doc(programId).collection('jadwal');
    if (j.id.isEmpty) {
      await koleksi.add(j.keMap());
    } else {
      await koleksi.doc(j.id).set(j.keMap());
    }
  }

  Future<void> hapusJadwal(String programId, String id) => _program.doc(programId).collection('jadwal').doc(id).delete();

  // Gambar soal

  Future<String> unggahGambar(String ujianId, Uint8List data, String namaBerkas, String tipeMime) async {
    final aman = namaBerkas.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final ref = _storage.ref('soal/$ujianId/${DateTime.now().millisecondsSinceEpoch}-$aman');
    await ref.putData(data, SettableMetadata(contentType: tipeMime));
    return ref.getDownloadURL();
  }
}
