/// Pengawas untuk platform selain web (belum dipakai). Di Android nanti layar tryout memakai
/// FLAG_SECURE supaya tidak bisa di-screenshot atau direkam.
class Pengawas {
  Pengawas({required this.onPelanggaran, required this.onFokus});

  final void Function(String jenis) onPelanggaran;
  final void Function(bool fokus) onFokus;

  bool get didukungLayarPenuh => false;
  bool get layarPenuh => false;

  void mulai({bool wajibLayarPenuh = false}) {}
  void berhenti() {}
  Future<bool> masukLayarPenuh() async => false;
  Future<void> keluarLayarPenuh() async {}
}
