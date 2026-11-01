import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../konfigurasi.dart';
import '../layanan/auth.dart';
import '../layanan/fungsi.dart';
import '../layanan/repo.dart';
import 'model.dart';

final layananAuthProvider = Provider((ref) => LayananAuth(FirebaseAuth.instance));
final repoProvider = Provider((ref) => Repo(FirebaseFirestore.instance, FirebaseStorage.instance));
final fungsiProvider = Provider((ref) => LayananFungsi(FirebaseFunctions.instanceFor(region: Konfigurasi.region)));

final authProvider = StreamProvider<User?>((ref) => ref.watch(layananAuthProvider).perubahan);

/// Profil pengguna yang sedang masuk. `null` jika belum masuk atau profil belum dibuat.
final penggunaProvider = StreamProvider<Pengguna?>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(repoProvider).pantauPengguna(user.uid);
});

final ujianTerbitProvider = StreamProvider<List<Ujian>>((ref) => ref.watch(repoProvider).pantauUjianTerbit());
final semuaUjianProvider = StreamProvider<List<Ujian>>((ref) => ref.watch(repoProvider).pantauSemuaUjian());
final ujianProvider = StreamProvider.family<Ujian?, String>((ref, id) => ref.watch(repoProvider).pantauUjian(id));
final soalProvider = StreamProvider.family<List<Soal>, String>((ref, ujianId) => ref.watch(repoProvider).pantauSoal(ujianId));
final stimulusProvider = StreamProvider.family<List<Stimulus>, String>((ref, ujianId) => ref.watch(repoProvider).pantauStimulus(ujianId));
final sesiUjianProvider = StreamProvider.family<List<Sesi>, String>((ref, ujianId) => ref.watch(repoProvider).pantauSesiUjian(ujianId));
final semuaPenggunaProvider = StreamProvider<List<Pengguna>>((ref) => ref.watch(repoProvider).pantauSemuaPengguna());

final sesiSayaProvider = StreamProvider<List<Sesi>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(repoProvider).pantauSesiSaya(user.uid);
});

final sesiProvider = StreamProvider.family<Sesi?, String>((ref, ujianId) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(repoProvider).pantauSesi(ujianId, user.uid);
});

/// Detak setiap 30 detik untuk memperbarui status "akan dibuka/berlangsung/ditutup".
final detakProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final programTerbitProvider = StreamProvider<List<Program>>((ref) => ref.watch(repoProvider).pantauProgramTerbit());
final semuaProgramProvider = StreamProvider<List<Program>>((ref) => ref.watch(repoProvider).pantauSemuaProgram());
final programProvider = StreamProvider.family<Program?, String>((ref, id) => ref.watch(repoProvider).pantauProgram(id));
final pendaftarProvider = StreamProvider.family<List<Pendaftar>, String>((ref, id) => ref.watch(repoProvider).pantauPendaftar(id));
final jadwalProvider = StreamProvider.family<List<Jadwal>, String>((ref, id) => ref.watch(repoProvider).pantauJadwal(id));

/// Semua pendaftaran milik pengguna yang sedang masuk.
final pendaftaranSayaProvider = StreamProvider<List<Pendaftar>>((ref) {
  final user = ref.watch(authProvider).value;
  if (user == null) return Stream.value(const []);
  return ref.watch(repoProvider).pantauPendaftaranSaya(user.uid);
});
