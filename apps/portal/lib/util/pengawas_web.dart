import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Pengawasan tryout di browser.
///
/// Browser tidak bisa benar-benar mencegah tangkapan layar (itu fitur sistem operasi), jadi
/// pengawas ini menyulitkan dan mencatat: memblokir salin, klik kanan, dan cetak; mendeteksi
/// pindah tab, meninggalkan jendela, tombol Print Screen, dan keluar dari layar penuh.
class Pengawas {
  Pengawas({required this.onPelanggaran, required this.onFokus});

  final void Function(String jenis) onPelanggaran;
  final void Function(bool fokus) onFokus;

  final _pendengar = <(web.EventTarget, String, JSFunction)>[];
  bool _wajibLayarPenuh = false;
  bool _aktif = false;
  DateTime _terakhirFokus = DateTime.fromMillisecondsSinceEpoch(0);

  bool get didukungLayarPenuh => web.document.fullscreenEnabled;
  bool get layarPenuh => web.document.fullscreenElement != null;

  void _dengar(web.EventTarget target, String jenis, void Function(web.Event e) fn) {
    final f = fn.toJS;
    target.addEventListener(jenis, f);
    _pendengar.add((target, jenis, f));
  }

  /// Pindah tab dan blur jendela sering terjadi bersamaan; catat sekali saja.
  void _kehilanganFokus(String jenis) {
    onFokus(false);
    final sekarang = DateTime.now();
    if (sekarang.difference(_terakhirFokus) < const Duration(milliseconds: 1500)) return;
    _terakhirFokus = sekarang;
    onPelanggaran(jenis);
  }

  void mulai({bool wajibLayarPenuh = false}) {
    if (_aktif) return;
    _aktif = true;
    _wajibLayarPenuh = wajibLayarPenuh;
    web.document.body?.classList.add('sedang-ujian');

    _dengar(web.document, 'visibilitychange', (_) {
      if (web.document.visibilityState == 'hidden') _kehilanganFokus('keluarTab');
    });
    _dengar(web.window, 'blur', (_) => _kehilanganFokus('keluarJendela'));
    _dengar(web.document, 'contextmenu', (e) => e.preventDefault());
    for (final jenis in ['copy', 'cut']) {
      _dengar(web.document, jenis, (e) {
        e.preventDefault();
        onPelanggaran('salin');
      });
    }
    _dengar(web.window, 'beforeprint', (_) => onPelanggaran('cetak'));
    _dengar(web.document, 'fullscreenchange', (_) {
      if (_wajibLayarPenuh && !layarPenuh) {
        onFokus(false);
        onPelanggaran('keluarLayarPenuh');
      }
    });
    _dengar(web.document, 'keydown', (e) {
      final k = e as web.KeyboardEvent;
      final tombol = k.key.toLowerCase();
      final modifikasi = k.ctrlKey || k.metaKey;
      if (tombol == 'f12' || (modifikasi && k.shiftKey && ['i', 'j', 'c'].contains(tombol))) {
        k.preventDefault();
        onPelanggaran('alatPengembang');
      } else if (modifikasi && ['c', 'x'].contains(tombol)) {
        k.preventDefault();
        onPelanggaran('salin');
      } else if (modifikasi && tombol == 'p') {
        k.preventDefault();
        onPelanggaran('cetak');
      } else if (modifikasi && ['s', 'u'].contains(tombol)) {
        k.preventDefault();
        onPelanggaran('pintasan');
      }
    });
    _dengar(web.document, 'keyup', (e) {
      final k = e as web.KeyboardEvent;
      if (k.key == 'PrintScreen') {
        onPelanggaran('tangkapLayar');
        // Kosongkan clipboard supaya hasil tangkapan tidak langsung bisa ditempel (bila diizinkan browser).
        web.window.navigator.clipboard.writeText('').toDart.ignore();
      }
    });
    _dengar(web.window, 'focus', (_) => onFokus(true));
  }

  void berhenti() {
    for (final (target, jenis, f) in _pendengar) {
      target.removeEventListener(jenis, f);
    }
    _pendengar.clear();
    _aktif = false;
    web.document.body?.classList.remove('sedang-ujian');
  }

  Future<bool> masukLayarPenuh() async {
    if (!didukungLayarPenuh) return false;
    try {
      await web.document.documentElement?.requestFullscreen().toDart;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> keluarLayarPenuh() async {
    if (!layarPenuh) return;
    try {
      await web.document.exitFullscreen().toDart;
    } catch (_) {}
  }
}
