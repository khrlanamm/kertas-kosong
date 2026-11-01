import 'package:cloud_functions/cloud_functions.dart';

import '../data/model.dart';

class LayananFungsi {
  LayananFungsi(this._f);

  final FirebaseFunctions _f;

  Future<Map<Object?, Object?>> _panggil(String nama, Map<String, Object?> data) async {
    final hasil = await _f.httpsCallable(nama, options: HttpsCallableOptions(timeout: const Duration(seconds: 120))).call<Object?>(data);
    final d = hasil.data;
    return d is Map ? d : const {};
  }

  Future<DataPengerjaan> mulaiSubtes(String ujianId, String subtesId) async =>
      DataPengerjaan.dariMap(await _panggil('mulaiSubtes', {'ujianId': ujianId, 'subtesId': subtesId}));

  /// Mengembalikan jumlah benar jika ujian mengizinkan hasil segera.
  Future<({bool semuaSelesai, int? benar, int? jumlah})> kumpulkanSubtes(String ujianId, String subtesId) async {
    final d = await _panggil('kumpulkanSubtes', {'ujianId': ujianId, 'subtesId': subtesId});
    return (semuaSelesai: d['semuaSelesai'] == true, benar: (d['benar'] as num?)?.round(), jumlah: (d['jumlah'] as num?)?.round());
  }

  Future<({List<SoalPembahasan> soal, Map<String, StimulusPeserta> stimulus})> pembahasan(String ujianId) async {
    final d = await _panggil('pembahasan', {'ujianId': ujianId});
    final soal = d['soal'];
    final stimulus = d['stimulus'];
    return (
      soal: soal is List ? soal.map(SoalPembahasan.dariMap).toList() : <SoalPembahasan>[],
      stimulus: stimulus is Map
          ? stimulus.map((k, v) => MapEntry('$k', StimulusPeserta((v as Map)['judul'] as String? ?? '', v['teks'] as String? ?? '')))
          : <String, StimulusPeserta>{},
    );
  }

  Future<int> hitungSkor(String ujianId) async {
    final d = await _panggil('hitungSkor', {'ujianId': ujianId});
    return (d['peserta'] as num?)?.round() ?? 0;
  }
}

/// Pesan galat Cloud Functions untuk ditampilkan ke pengguna.
String pesanGalat(Object e) {
  if (e is FirebaseFunctionsException) {
    if (e.code == 'unavailable' || e.code == 'deadline-exceeded') return 'Server tidak dapat dihubungi. Periksa koneksi lalu coba lagi.';
    return e.message ?? 'Terjadi kesalahan (${e.code}).';
  }
  return 'Terjadi kesalahan: $e';
}
