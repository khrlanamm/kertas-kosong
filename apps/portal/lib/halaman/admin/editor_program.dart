import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';
import 'tab_jadwal.dart';
import 'tab_pendaftar.dart';

class HalamanEditorProgram extends ConsumerWidget {
  const HalamanEditorProgram({super.key, required this.programId, this.tab});

  final String programId;
  final String? tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(programProvider(programId));
    return program.when(
      loading: () => const Scaffold(body: Memuat()),
      error: (e, _) => Scaffold(body: PesanGalat('Gagal memuat program: $e')),
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.go('/admin/program'))),
            body: const PesanGalat('Program tidak ditemukan.'),
          );
        }
        final bimbel = p.jenis == JenisProgram.bimbel;
        final tabs = ['Pengaturan', 'Pendaftar', if (bimbel) 'Jadwal'];
        final awal = switch (tab) {
          'pendaftar' => 1,
          'jadwal' when bimbel => 2,
          _ => 0,
        };
        return DefaultTabController(
          key: ValueKey('tab-$awal'),
          length: tabs.length,
          initialIndex: awal,
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/admin/program')),
              title: Text(p.judul, overflow: TextOverflow.ellipsis),
              actions: [
                TextButton.icon(
                  onPressed: () => context.push('/program/${p.id}'),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Lihat sebagai siswa'),
                ),
                const MenuAkun(),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [for (final t in tabs) Tab(text: t)],
              ),
            ),
            body: TabBarView(
              children: [
                _TabPengaturanProgram(program: p),
                TabPendaftar(program: p),
                if (bimbel) TabJadwal(program: p),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabPengaturanProgram extends ConsumerStatefulWidget {
  const _TabPengaturanProgram({required this.program});

  final Program program;

  @override
  ConsumerState<_TabPengaturanProgram> createState() => _TabPengaturanProgramState();
}

class _TabPengaturanProgramState extends ConsumerState<_TabPengaturanProgram> {
  late final _judul = TextEditingController(text: widget.program.judul);
  late final _deskripsi = TextEditingController(text: widget.program.deskripsi);
  late final _kuota = TextEditingController(text: '${widget.program.kuota}');
  late final _waktuAcara = TextEditingController(text: widget.program.waktuAcara);
  late final _tempat = TextEditingController(text: widget.program.tempat);
  late DateTime _buka = widget.program.buka;
  late DateTime _tutup = widget.program.tutup;
  late bool _manual = widget.program.seleksiManual;
  late final List<String> _kelas = [...widget.program.kelas];
  bool _berubah = false;
  bool _sibuk = false;

  Program get _p => widget.program;

  @override
  void dispose() {
    for (final c in [_judul, _deskripsi, _kuota, _waktuAcara, _tempat]) {
      c.dispose();
    }
    super.dispose();
  }

  void _tandai() => setState(() => _berubah = true);

  Future<DateTime?> _pilihWaktu(DateTime awal) async {
    final wib = keWib(awal);
    final tanggal = await showDatePicker(
      context: context,
      initialDate: DateTime(wib.year, wib.month, wib.day),
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      helpText: 'Pilih tanggal (WIB)',
    );
    if (tanggal == null || !mounted) return null;
    final jam = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: wib.hour, minute: wib.minute),
      helpText: 'Pilih jam (WIB)',
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return jam == null ? null : dariWib(tanggal, jam);
  }

  Future<void> _simpan() async {
    final kuota = int.tryParse(_kuota.text.trim());
    if (_judul.text.trim().isEmpty || kuota == null || kuota < 0) {
      tampilkanPesan(context, 'Periksa judul dan kuota (angka, 0 = tanpa batas).', galat: true);
      return;
    }
    if (!_tutup.isAfter(_buka)) {
      tampilkanPesan(context, 'Pendaftaran harus ditutup setelah dibuka.', galat: true);
      return;
    }
    setState(() => _sibuk = true);
    try {
      await ref.read(repoProvider).perbaruiProgram(_p.id, {
        'judul': _judul.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'buka': Timestamp.fromDate(_buka),
        'tutup': Timestamp.fromDate(_tutup),
        'kuota': kuota,
        'seleksi': _manual ? 'manual' : 'otomatis',
        'kelas': _kelas,
        'waktuAcara': _waktuAcara.text.trim(),
        'tempat': _tempat.text.trim(),
      });
      if (mounted) {
        setState(() => _berubah = false);
        tampilkanPesan(context, 'Pengaturan program tersimpan.');
      }
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan: $e', galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _ubahStatus(bool terbit) async {
    if (_berubah) {
      tampilkanPesan(context, 'Simpan perubahan terlebih dahulu.', galat: true);
      return;
    }
    final ya = await konfirmasi(
      context,
      judul: terbit ? 'Terbitkan program?' : 'Jadikan draf?',
      isi: terbit
          ? 'Siswa akan melihat program ini dan bisa mendaftar mulai ${formatTanggalJam(_p.buka)}.'
          : 'Program akan disembunyikan dari siswa. Data pendaftar tetap tersimpan.',
      ya: terbit ? 'Terbitkan' : 'Jadikan draf',
    );
    if (!ya) return;
    await ref.read(repoProvider).perbaruiProgram(_p.id, {'status': terbit ? 'terbit' : 'draf'});
  }

  Future<void> _tambahKelas() async {
    final c = TextEditingController();
    final nama = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah kelas'),
        content: TextField(
          controller: c,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(labelText: 'Nama kelas', hintText: 'C'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Tambah')),
        ],
      ),
    );
    c.dispose();
    if (nama == null || nama.isEmpty || _kelas.contains(nama)) return;
    setState(() {
      _kelas.add(nama);
      _berubah = true;
    });
  }

  Future<void> _hapus() async {
    if (_p.jumlahPendaftar > 0) {
      tampilkanPesan(context, 'Program yang sudah memiliki pendaftar tidak bisa dihapus. Jadikan draf saja.', galat: true);
      return;
    }
    final ya = await konfirmasi(
      context,
      judul: 'Hapus program?',
      isi: '"${_p.judul}" beserta jadwalnya akan dihapus.',
      ya: 'Hapus',
      bahaya: true,
    );
    if (!ya) return;
    await ref.read(repoProvider).hapusProgram(_p.id);
    if (mounted) context.go('/admin/program');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final bimbel = _p.jenis == JenisProgram.bimbel;
    final judulBagian = tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return ListView(
      children: [
        Lebar(
          maks: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: Icon(_p.terbit ? Icons.public : Icons.edit_document, color: _p.terbit ? Warna.benar : Colors.blueGrey),
                  title: Text(_p.terbit ? 'Terbit' : 'Draf'),
                  subtitle: Text(
                    _p.terbit ? 'Siswa bisa melihat dan mendaftar sesuai periode.' : 'Hanya admin yang bisa melihat program ini.',
                  ),
                  trailing: _p.terbit
                      ? OutlinedButton(onPressed: () => _ubahStatus(false), child: const Text('Jadikan draf'))
                      : FilledButton(onPressed: () => _ubahStatus(true), child: const Text('Terbitkan')),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _judul,
                decoration: const InputDecoration(labelText: 'Judul'),
                onChanged: (_) => _tandai(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deskripsi,
                minLines: 3,
                maxLines: 10,
                decoration: const InputDecoration(labelText: 'Deskripsi dan syarat (mendukung Markdown)', alignLabelWithHint: true),
                onChanged: (_) => _tandai(),
              ),
              if (!bimbel) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _waktuAcara,
                  decoration: const InputDecoration(labelText: 'Waktu acara', hintText: 'Sabtu, 23 Januari 2027, 08.00-12.00 WIB'),
                  onChanged: (_) => _tandai(),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tempat,
                  decoration: const InputDecoration(labelText: 'Tempat', hintText: 'Aula SMAN 1 Dukun, Gresik'),
                  onChanged: (_) => _tandai(),
                ),
              ],
              const SizedBox(height: 20),
              Text('Periode pendaftaran (WIB)', style: judulBagian),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_open),
                      title: const Text('Dibuka'),
                      subtitle: Text(formatTanggalJam(_buka)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final t = await _pilihWaktu(_buka);
                        if (t == null) return;
                        setState(() {
                          _buka = t;
                          _berubah = true;
                        });
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_clock),
                      title: const Text('Ditutup'),
                      subtitle: Text(formatTanggalJam(_tutup)),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final t = await _pilihWaktu(_tutup);
                        if (t == null) return;
                        setState(() {
                          _tutup = t;
                          _berubah = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('Penerimaan', style: judulBagian),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Kuota pendaftar'),
                      subtitle: Text('Terisi ${_p.jumlahPendaftar}. Isi 0 jika tanpa batas.'),
                      trailing: SizedBox(
                        width: 100,
                        child: TextField(controller: _kuota, keyboardType: TextInputType.number, onChanged: (_) => _tandai()),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text('Perlu verifikasi panitia'),
                      subtitle: Text(_manual ? 'Pendaftar menunggu sampai admin menerima.' : 'Pendaftar langsung diterima.'),
                      value: _manual,
                      onChanged: (v) => setState(() {
                        _manual = v;
                        _berubah = true;
                      }),
                    ),
                  ],
                ),
              ),
              if (bimbel) ...[
                const SizedBox(height: 20),
                Text('Kelas', style: judulBagian),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in _kelas)
                      InputChip(
                        label: Text('Kelas $k'),
                        onDeleted: () => setState(() {
                          _kelas.remove(k);
                          _berubah = true;
                        }),
                      ),
                    ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Tambah kelas'), onPressed: _tambahKelas),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _sibuk || !_berubah ? null : _simpan,
                child: _sibuk
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_berubah ? 'Simpan perubahan' : 'Tersimpan'),
              ),
              const SizedBox(height: 40),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _hapus,
                  style: TextButton.styleFrom(foregroundColor: Warna.salah),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Hapus program'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
