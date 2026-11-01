import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../layanan/fungsi.dart';
import '../../tema.dart';
import '../../util/pengawas.dart';
import '../../util/waktu.dart';
import '../../widget/jawaban.dart';
import '../../widget/konten.dart';
import '../../widget/umum.dart';

enum _StatusSimpan { tersimpan, menyimpan, gagal }

/// Halaman pengerjaan satu subtes, mirip tampilan CBT UTBK.
class HalamanPengerjaan extends ConsumerStatefulWidget {
  const HalamanPengerjaan({super.key, required this.ujianId, required this.subtesId});

  final String ujianId;
  final String subtesId;

  @override
  ConsumerState<HalamanPengerjaan> createState() => _HalamanPengerjaanState();
}

class _HalamanPengerjaanState extends ConsumerState<HalamanPengerjaan> {
  DataPengerjaan? _data;
  String? _galat;
  int _indeks = 0;
  final Map<String, Object?> _jawaban = {};
  final Map<String, bool> _ragu = {};

  /// Selisih jam server dan jam perangkat, supaya hitung mundur tidak bergantung pada jam HP.
  Duration _selisih = Duration.zero;
  Duration _sisa = Duration.zero;
  Timer? _detik;
  final Map<String, Timer> _tunda = {};
  final Set<String> _antrean = {};
  _StatusSimpan _simpan = _StatusSimpan.tersimpan;
  bool _mengumpulkan = false;

  // Pengawasan
  Pengawas? _pengawas;
  int _pelanggaran = 0;

  /// Soal ditutup setelah peserta meninggalkan halaman, sampai ia kembali dan menekan Lanjutkan.
  bool _tertutup = false;

  /// Menunggu peserta masuk layar penuh (jika diwajibkan).
  bool _menungguLayarPenuh = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _detik?.cancel();
    for (final t in _tunda.values) {
      t.cancel();
    }
    _hentikanPengawasan();
    super.dispose();
  }

  void _hentikanPengawasan() {
    _pengawas?.berhenti();
    _pengawas?.keluarLayarPenuh();
    _pengawas = null;
  }

  void _mulaiPengawasan(DataPengerjaan data) {
    if (!data.pengawasan) return;
    final p = Pengawas(onPelanggaran: _catatPelanggaran, onFokus: _ubahFokus)..mulai(wajibLayarPenuh: data.layarPenuh);
    _pengawas = p;
    _pelanggaran = data.pelanggaran;
    _menungguLayarPenuh = data.layarPenuh && p.didukungLayarPenuh && !p.layarPenuh;
  }

  void _ubahFokus(bool fokus) {
    if (!fokus && mounted && !_mengumpulkan) setState(() => _tertutup = true);
  }

  void _catatPelanggaran(String jenis) {
    final data = _data;
    if (data == null || _mengumpulkan || !mounted) return;
    setState(() => _pelanggaran++);
    ref.read(repoProvider).catatPelanggaran(widget.ujianId, _uid, widget.subtesId, jenis).catchError((_) {});
    final batas = data.batasPelanggaran;
    final label = labelPelanggaran[jenis] ?? jenis;
    if (batas > 0 && _pelanggaran >= batas) {
      _kumpulkan(otomatis: true, sebab: 'pelanggaran');
      return;
    }
    tampilkanPesan(
      context,
      'Tercatat: $label${batas > 0 ? ' ($_pelanggaran dari $batas, subtes dikumpulkan otomatis jika mencapai batas)' : ''}.',
      galat: true,
    );
  }

  Future<void> _lanjutkan() async {
    if (_data?.layarPenuh ?? false) await _pengawas?.masukLayarPenuh();
    if (mounted) setState(() => _tertutup = false);
  }

  Future<void> _masukLayarPenuh() async {
    final ok = await _pengawas?.masukLayarPenuh() ?? false;
    if (!mounted) return;
    if (ok) {
      setState(() => _menungguLayarPenuh = false);
    } else {
      tampilkanPesan(
        context,
        'Browser ini tidak mengizinkan layar penuh. Kamu tetap bisa mengerjakan, tetapi jangan meninggalkan halaman.',
      );
      setState(() => _menungguLayarPenuh = false);
    }
  }

  String get _uid => ref.read(authProvider).value?.uid ?? '';

  Future<void> _muat() async {
    setState(() => _galat = null);
    try {
      final data = await ref.read(fungsiProvider).mulaiSubtes(widget.ujianId, widget.subtesId);
      if (!mounted) return;
      if (data.status == 'waktuHabis') {
        await _selesai(pesan: 'Waktu subtes ini sudah habis. Jawaban yang tersimpan sudah dikumpulkan.');
        return;
      }
      _selisih = data.sekarang.difference(DateTime.now());
      _mulaiPengawasan(data);
      setState(() {
        _data = data;
        _jawaban
          ..clear()
          ..addAll(data.jawaban);
        _ragu
          ..clear()
          ..addAll(data.ragu);
      });
      _perbaruiSisa();
      _detik = Timer.periodic(const Duration(seconds: 1), (_) => _perbaruiSisa());
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalat(e));
    }
  }

  void _perbaruiSisa() {
    final data = _data;
    if (data == null || !mounted) return;
    final sisa = data.batas.difference(DateTime.now().add(_selisih));
    setState(() => _sisa = sisa);
    if (sisa <= Duration.zero && !_mengumpulkan) _kumpulkan(otomatis: true);
  }

  void _ubahJawaban(SoalPeserta soal, Object? nilai) {
    setState(() {
      if (nilai == null) {
        _jawaban.remove(soal.id);
      } else {
        _jawaban[soal.id] = nilai;
      }
    });
    // Isian disimpan setelah berhenti mengetik; pilihan langsung disimpan.
    _jadwalkanSimpan(soal.id, soal.tipe == TipeSoal.isian ? const Duration(milliseconds: 700) : Duration.zero);
  }

  void _jadwalkanSimpan(String soalId, Duration jeda) {
    _tunda[soalId]?.cancel();
    _antrean.add(soalId);
    setState(() => _simpan = _StatusSimpan.menyimpan);
    _tunda[soalId] = Timer(jeda, () => _simpanSatu(soalId));
  }

  Future<void> _simpanSatu(String soalId) async {
    _tunda.remove(soalId);
    try {
      await ref.read(repoProvider).simpanJawaban(widget.ujianId, _uid, widget.subtesId, soalId, _jawaban[soalId]);
      _antrean.remove(soalId);
      if (mounted && _antrean.isEmpty) setState(() => _simpan = _StatusSimpan.tersimpan);
    } catch (_) {
      if (mounted) setState(() => _simpan = _StatusSimpan.gagal);
    }
  }

  /// Simpan semua jawaban yang masih tertunda sebelum dikumpulkan.
  Future<void> _simpanSemua() async {
    for (final t in _tunda.values) {
      t.cancel();
    }
    _tunda.clear();
    await Future.wait(_antrean.toList().map(_simpanSatu));
  }

  Future<void> _ubahRagu(String soalId) async {
    final baru = !(_ragu[soalId] ?? false);
    setState(() => baru ? _ragu[soalId] = true : _ragu.remove(soalId));
    try {
      await ref.read(repoProvider).simpanRagu(widget.ujianId, _uid, widget.subtesId, soalId, baru);
    } catch (_) {
      // Tanda ragu-ragu hanya penanda pribadi; gagal simpan tidak memengaruhi nilai.
    }
  }

  bool _terisi(SoalPeserta s) => jawabanTerisi(s.tipe, _jawaban[s.id], jumlahPernyataan: s.pernyataan.length);

  Future<void> _kumpulkan({bool otomatis = false, String sebab = 'waktu'}) async {
    final data = _data;
    if (data == null || _mengumpulkan) return;
    if (!otomatis) {
      final kosong = data.soal.where((s) => !_terisi(s)).length;
      final ragu = data.soal.where((s) => _ragu[s.id] ?? false).length;
      final ya = await konfirmasi(
        context,
        judul: 'Kumpulkan ${data.namaSubtes}?',
        isi: [
          'Terjawab: ${data.soal.length - kosong} dari ${data.soal.length} soal.',
          if (kosong > 0) 'Belum dijawab: $kosong soal.',
          if (ragu > 0) 'Ditandai ragu-ragu: $ragu soal.',
          'Setelah dikumpulkan, jawaban subtes ini tidak bisa diubah lagi.',
        ].join('\n'),
        ya: 'Kumpulkan',
      );
      if (!ya) return;
    }
    setState(() => _mengumpulkan = true);
    _detik?.cancel();
    try {
      await _simpanSemua();
    } catch (_) {
      // Jawaban yang sudah tersimpan tetap dinilai.
    }
    try {
      final hasil = await ref.read(fungsiProvider).kumpulkanSubtes(widget.ujianId, widget.subtesId);
      final teksHasil = hasil.benar != null ? ' Hasil: ${hasil.benar} dari ${hasil.jumlah} benar.' : '';
      final pesan = !otomatis
          ? 'Subtes dikumpulkan.'
          : sebab == 'pelanggaran'
          ? 'Subtes dikumpulkan otomatis karena catatan pelanggaran mencapai batas.'
          : 'Waktu habis. Jawabanmu sudah dikumpulkan otomatis.';
      await _selesai(pesan: '$pesan$teksHasil');
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengumpulkan = false);
      tampilkanPesan(context, '${pesanGalat(e)}${otomatis ? ' Mencoba lagi...' : ''}', galat: true);
      if (otomatis) {
        // Waktu sudah habis: terus coba kumpulkan sampai berhasil.
        Timer(const Duration(seconds: 3), () => _kumpulkan(otomatis: true, sebab: sebab));
      } else {
        _detik = Timer.periodic(const Duration(seconds: 1), (_) => _perbaruiSisa());
      }
    }
  }

  Future<void> _selesai({required String pesan}) async {
    _hentikanPengawasan();
    if (!mounted) return;
    tampilkanPesan(context, pesan);
    context.go('/ujian/${widget.ujianId}');
  }

  String _tandaAir() {
    final p = ref.read(penggunaProvider).value;
    return '${p?.nama ?? ''} · ${p?.email ?? ''} · ${formatTanggalSingkat(DateTime.now())}';
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    if (_galat != null) {
      return Scaffold(
        appBar: AppBar(leading: BackButton(onPressed: () => context.go('/ujian/${widget.ujianId}'))),
        body: PesanGalat(_galat!, ulangi: _muat),
      );
    }
    if (data == null) return const Scaffold(body: Memuat(pesan: 'Menyiapkan soal...'));
    if (data.soal.isEmpty) return const Scaffold(body: PesanGalat('Subtes ini belum memiliki soal.'));

    final lebar = MediaQuery.sizeOf(context).width >= 1000;
    final soal = data.soal[_indeks];
    final navigasi = _Navigasi(
      soal: data.soal,
      indeks: _indeks,
      terisi: _terisi,
      ragu: (id) => _ragu[id] ?? false,
      onPilih: (i) {
        setState(() => _indeks = i);
        if (!lebar) Navigator.of(context).maybePop();
      },
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) tampilkanPesan(context, 'Gunakan tombol Kumpulkan untuk menyelesaikan subtes.');
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Text(data.namaSubtes, overflow: TextOverflow.ellipsis),
          actions: [
            if (data.pengawasan && _pelanggaran > 0)
              Tooltip(
                message: 'Catatan pengawasan: $_pelanggaran${data.batasPelanggaran > 0 ? ' dari batas ${data.batasPelanggaran}' : ''}',
                child: Label('$_pelanggaran pelanggaran', warna: Warna.salah),
              ),
            const SizedBox(width: 8),
            _IndikatorSimpan(status: _simpan, ulangi: () => Future.wait(_antrean.toList().map(_simpanSatu))),
            const SizedBox(width: 8),
            _Pewaktu(sisa: _sisa),
            const SizedBox(width: 8),
            if (!lebar)
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Daftar soal',
                  icon: const Icon(Icons.grid_view_rounded),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
        endDrawer: lebar ? null : Drawer(child: SafeArea(child: navigasi)),
        body: _mengumpulkan
            ? const Memuat(pesan: 'Mengumpulkan jawaban...')
            : _BingkaiPengawasan(
                aktif: data.pengawasan,
                tandaAir: _tandaAir(),
                tertutup: _tertutup,
                menungguLayarPenuh: _menungguLayarPenuh,
                onLanjutkan: _lanjutkan,
                onLayarPenuh: _masukLayarPenuh,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _TampilanSoal(
                        key: ValueKey(soal.id),
                        nomor: _indeks + 1,
                        jumlah: data.soal.length,
                        soal: soal,
                        stimulus: soal.stimulusId == null ? null : data.stimulus[soal.stimulusId],
                        jawaban: _jawaban[soal.id],
                        lebar: lebar,
                        onUbah: (v) => _ubahJawaban(soal, v),
                      ),
                    ),
                    if (lebar)
                      SizedBox(
                        width: 300,
                        child: Material(color: Colors.white, child: navigasi),
                      ),
                  ],
                ),
              ),
        bottomNavigationBar: _mengumpulkan
            ? null
            : SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Warna.tintaMuda)),
                  ),
                  child: Row(
                    children: [
                      lebar
                          ? OutlinedButton.icon(
                              onPressed: _indeks == 0 ? null : () => setState(() => _indeks--),
                              icon: const Icon(Icons.chevron_left),
                              label: const Text('Sebelumnya'),
                            )
                          : IconButton.outlined(
                              tooltip: 'Soal sebelumnya',
                              onPressed: _indeks == 0 ? null : () => setState(() => _indeks--),
                              icon: const Icon(Icons.chevron_left),
                            ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Center(
                          heightFactor: 1,
                          child: FilterChip(
                            selected: _ragu[soal.id] ?? false,
                            selectedColor: Warna.ragu.withValues(alpha: 0.35),
                            label: const Text('Ragu-ragu'),
                            onSelected: (_) => _ubahRagu(soal.id),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _indeks == data.soal.length - 1
                          ? FilledButton.icon(onPressed: () => _kumpulkan(), icon: const Icon(Icons.send), label: const Text('Kumpulkan'))
                          : lebar
                          ? FilledButton.icon(
                              onPressed: () => setState(() => _indeks++),
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Berikutnya'),
                            )
                          : IconButton.filled(
                              tooltip: 'Soal berikutnya',
                              onPressed: () => setState(() => _indeks++),
                              icon: const Icon(Icons.chevron_right),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _TampilanSoal extends StatelessWidget {
  const _TampilanSoal({
    super.key,
    required this.nomor,
    required this.jumlah,
    required this.soal,
    required this.stimulus,
    required this.jawaban,
    required this.lebar,
    required this.onUbah,
  });

  final int nomor;
  final int jumlah;
  final SoalPeserta soal;
  final StimulusPeserta? stimulus;
  final Object? jawaban;
  final bool lebar;
  final ValueChanged<Object?> onUbah;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bagianSoal = ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Text('Soal $nomor', style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            Text('  dari $jumlah', style: tema.textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          soal.tipe.petunjuk,
          style: tema.textTheme.bodySmall?.copyWith(color: Warna.tinta, fontWeight: FontWeight.w600),
        ),
        if (!lebar && stimulus != null) ...[
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              initiallyExpanded: true,
              shape: const Border(),
              title: Text(stimulus!.judul.isEmpty ? 'Bacaan' : stimulus!.judul),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [Konten(stimulus!.teks)],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Konten(soal.teks),
        const SizedBox(height: 20),
        InputJawaban(soal: soal, jawaban: jawaban, onUbah: onUbah),
        const SizedBox(height: 40),
      ],
    );

    if (!lebar || stimulus == null) return bagianSoal;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  stimulus!.judul.isEmpty ? 'Bacaan' : stimulus!.judul,
                  style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Konten(stimulus!.teks),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: bagianSoal),
      ],
    );
  }
}

class _Navigasi extends StatelessWidget {
  const _Navigasi({required this.soal, required this.indeks, required this.terisi, required this.ragu, required this.onPilih});

  final List<SoalPeserta> soal;
  final int indeks;
  final bool Function(SoalPeserta) terisi;
  final bool Function(String) ragu;
  final ValueChanged<int> onPilih;

  @override
  Widget build(BuildContext context) {
    final jumlahTerisi = soal.where(terisi).length;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Daftar soal', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('$jumlahTerisi dari ${soal.length} terjawab'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < soal.length; i++)
              _KotakNomor(nomor: i + 1, aktif: i == indeks, terisi: terisi(soal[i]), ragu: ragu(soal[i].id), onTap: () => onPilih(i)),
          ],
        ),
        const SizedBox(height: 16),
        const Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            _Keterangan(warna: Warna.tinta, teks: 'Terjawab'),
            _Keterangan(warna: Warna.ragu, teks: 'Ragu-ragu'),
            _Keterangan(warna: Colors.white, teks: 'Belum dijawab', tepi: true),
          ],
        ),
      ],
    );
  }
}

class _KotakNomor extends StatelessWidget {
  const _KotakNomor({required this.nomor, required this.aktif, required this.terisi, required this.ragu, required this.onTap});

  final int nomor;
  final bool aktif;
  final bool terisi;
  final bool ragu;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final latar = ragu ? Warna.ragu : (terisi ? Warna.tinta : Colors.white);
    return Material(
      color: latar,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: aktif ? Warna.tintaTua : Colors.black26, width: aktif ? 3 : 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Center(
            child: Text(
              '$nomor',
              style: TextStyle(fontWeight: FontWeight.w700, color: terisi || ragu ? Colors.white : Warna.tintaTua),
            ),
          ),
        ),
      ),
    );
  }
}

class _Keterangan extends StatelessWidget {
  const _Keterangan({required this.warna, required this.teks, this.tepi = false});

  final Color warna;
  final String teks;
  final bool tepi;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: warna,
          borderRadius: BorderRadius.circular(4),
          border: tepi ? Border.all(color: Colors.black26) : null,
        ),
      ),
      const SizedBox(width: 6),
      Text(teks, style: const TextStyle(fontSize: 12)),
    ],
  );
}

class _Pewaktu extends StatelessWidget {
  const _Pewaktu({required this.sisa});

  final Duration sisa;

  @override
  Widget build(BuildContext context) {
    final genting = sisa.inSeconds <= 300;
    return Semantics(
      label: 'Sisa waktu ${formatHitungMundur(sisa)}',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: genting ? Warna.salah : Warna.tintaMuda, borderRadius: BorderRadius.circular(999)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.timer_outlined, size: 18, color: genting ? Colors.white : Warna.tintaTua),
            const SizedBox(width: 6),
            Text(
              formatHitungMundur(sisa),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: genting ? Colors.white : Warna.tintaTua,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndikatorSimpan extends StatelessWidget {
  const _IndikatorSimpan({required this.status, required this.ulangi});

  final _StatusSimpan status;
  final VoidCallback ulangi;

  @override
  Widget build(BuildContext context) => switch (status) {
    _StatusSimpan.tersimpan => const Tooltip(
      message: 'Semua jawaban tersimpan',
      child: Icon(Icons.cloud_done_outlined, color: Warna.benar),
    ),
    _StatusSimpan.menyimpan => const Tooltip(
      message: 'Menyimpan jawaban...',
      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
    ),
    _StatusSimpan.gagal => TextButton.icon(
      onPressed: ulangi,
      icon: const Icon(Icons.cloud_off, color: Warna.salah),
      label: const Text('Gagal menyimpan. Coba lagi', style: TextStyle(color: Warna.salah)),
    ),
  };
}

/// Lapisan pengawasan di atas soal: tanda air berisi identitas peserta, penutup saat peserta
/// meninggalkan halaman, dan ajakan masuk layar penuh.
class _BingkaiPengawasan extends StatelessWidget {
  const _BingkaiPengawasan({
    required this.aktif,
    required this.tandaAir,
    required this.tertutup,
    required this.menungguLayarPenuh,
    required this.onLanjutkan,
    required this.onLayarPenuh,
    required this.child,
  });

  final bool aktif;
  final String tandaAir;
  final bool tertutup;
  final bool menungguLayarPenuh;
  final VoidCallback onLanjutkan;
  final VoidCallback onLayarPenuh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!aktif) return child;
    final tema = Theme.of(context);
    Widget penutup({
      required IconData ikon,
      required String judul,
      required String isi,
      required String tombol,
      required VoidCallback aksi,
    }) => Positioned.fill(
      child: ColoredBox(
        color: Warna.kertas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(ikon, size: 48, color: Warna.tinta),
                  const SizedBox(height: 12),
                  Text(
                    judul,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(isi, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: aksi, child: Text(tombol)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return Stack(
      children: [
        Positioned.fill(child: child),
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _PelukisTandaAir(tandaAir))),
        ),
        if (menungguLayarPenuh)
          penutup(
            ikon: Icons.fullscreen,
            judul: 'Kerjakan dalam layar penuh',
            isi: 'Tryout ini wajib dikerjakan dalam layar penuh. Keluar dari layar penuh atau pindah tab akan tercatat.',
            tombol: 'Masuk layar penuh',
            aksi: onLayarPenuh,
          )
        else if (tertutup)
          penutup(
            ikon: Icons.visibility_off_outlined,
            judul: 'Soal disembunyikan',
            isi: 'Kamu meninggalkan halaman tryout, dan ini sudah tercatat. Waktu tetap berjalan.',
            tombol: 'Lanjutkan mengerjakan',
            aksi: onLanjutkan,
          ),
      ],
    );
  }
}

class _PelukisTandaAir extends CustomPainter {
  _PelukisTandaAir(this.teks);

  final String teks;

  @override
  void paint(Canvas canvas, Size size) {
    final tp = TextPainter(
      text: TextSpan(
        text: teks,
        style: const TextStyle(color: Color(0x14000000), fontSize: 14, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.rotate(-0.35);
    final langkahX = tp.width + 80;
    const langkahY = 110.0;
    for (var y = -size.width; y < size.height + size.width; y += langkahY) {
      final geser = ((y / langkahY).round() % 2) * langkahX / 2;
      for (var x = -size.width; x < size.width * 2; x += langkahX) {
        tp.paint(canvas, Offset(x + geser, y));
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PelukisTandaAir lama) => lama.teks != teks;
}
