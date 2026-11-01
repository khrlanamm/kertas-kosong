import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/umum.dart';

class TabPengaturan extends ConsumerStatefulWidget {
  const TabPengaturan({super.key, required this.ujian});

  final Ujian ujian;

  @override
  ConsumerState<TabPengaturan> createState() => _TabPengaturanState();
}

class _TabPengaturanState extends ConsumerState<TabPengaturan> {
  late final _judul = TextEditingController(text: widget.ujian.judul);
  late final _deskripsi = TextEditingController(text: widget.ujian.deskripsi);
  late DateTime _buka = widget.ujian.buka;
  late DateTime _tutup = widget.ujian.tutup;
  late PengaturanUjian _atur = widget.ujian.pengaturan;
  bool _sibuk = false;
  bool _berubah = false;

  @override
  void dispose() {
    _judul.dispose();
    _deskripsi.dispose();
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
    if (jam == null) return null;
    return dariWib(tanggal, jam);
  }

  Future<void> _simpan() async {
    if (_judul.text.trim().isEmpty) {
      tampilkanPesan(context, 'Judul tidak boleh kosong.', galat: true);
      return;
    }
    if (!_tutup.isAfter(_buka)) {
      tampilkanPesan(context, 'Waktu tutup harus setelah waktu buka.', galat: true);
      return;
    }
    setState(() => _sibuk = true);
    try {
      await ref.read(repoProvider).perbaruiUjian(widget.ujian.id, {
        'judul': _judul.text.trim(),
        'deskripsi': _deskripsi.text.trim(),
        'buka': Timestamp.fromDate(_buka),
        'tutup': Timestamp.fromDate(_tutup),
        'pengaturan': _atur.keMap(),
      });
      if (mounted) {
        setState(() => _berubah = false);
        tampilkanPesan(context, 'Pengaturan tersimpan.');
      }
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan: $e', galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  List<String> _masalahTerbit() {
    final u = widget.ujian;
    return [
      if (u.subtes.isEmpty) 'Belum ada subtes.',
      for (final s in u.subtes)
        if ((u.jumlahSoal[s.id] ?? 0) == 0) '${s.nama} belum memiliki soal.',
      if (!u.tutup.isAfter(u.buka)) 'Waktu tutup harus setelah waktu buka.',
      if (_berubah) 'Simpan perubahan pengaturan terlebih dahulu.',
    ];
  }

  Future<void> _ubahStatus(bool terbit) async {
    final repo = ref.read(repoProvider);
    final u = widget.ujian;
    if (terbit) {
      final masalah = _masalahTerbit();
      if (masalah.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Belum bisa diterbitkan'),
            content: Text(masalah.map((m) => '• $m').join('\n')),
            actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Mengerti'))],
          ),
        );
        return;
      }
      final kurang = [
        for (final s in u.subtes)
          if (s.targetSoal > 0 && (u.jumlahSoal[s.id] ?? 0) != s.targetSoal)
            '${s.singkatan.isEmpty ? s.nama : s.singkatan}: ${u.jumlahSoal[s.id] ?? 0}/${s.targetSoal}',
      ];
      if (!mounted) return;
      final ya = await konfirmasi(
        context,
        judul: 'Terbitkan tryout?',
        isi:
            'Siswa akan melihat tryout ini dan bisa mengerjakannya mulai ${formatTanggalJam(u.buka)}.'
            '${kurang.isEmpty ? '' : '\n\nJumlah soal belum sesuai target: ${kurang.join(', ')}.'}',
        ya: 'Terbitkan',
      );
      if (!ya) return;
    } else {
      final ada = await repo.adaPeserta(u.id);
      if (!mounted) return;
      final ya = await konfirmasi(
        context,
        judul: 'Jadikan draf?',
        isi: ada
            ? 'Sudah ada peserta yang mengerjakan. Tryout akan disembunyikan dari siswa dan peserta tidak bisa melanjutkan.'
            : 'Tryout akan disembunyikan dari siswa.',
        ya: 'Jadikan draf',
        bahaya: ada,
      );
      if (!ya) return;
    }
    try {
      await repo.perbaruiUjian(u.id, {'status': terbit ? 'terbit' : 'draf'});
      if (mounted) tampilkanPesan(context, terbit ? 'Tryout diterbitkan.' : 'Tryout dijadikan draf.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal: $e', galat: true);
    }
  }

  Future<void> _hapus() async {
    final repo = ref.read(repoProvider);
    if (await repo.adaPeserta(widget.ujian.id)) {
      if (mounted) tampilkanPesan(context, 'Tryout yang sudah dikerjakan peserta tidak bisa dihapus.', galat: true);
      return;
    }
    if (!mounted) return;
    final ya = await konfirmasi(
      context,
      judul: 'Hapus tryout?',
      isi: 'Tryout "${widget.ujian.judul}" beserta semua soal dan bacaannya akan dihapus permanen.',
      ya: 'Hapus',
      bahaya: true,
    );
    if (!ya) return;
    await repo.hapusUjian(widget.ujian.id);
    if (mounted) context.go('/admin/ujian');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final u = widget.ujian;
    return ListView(
      children: [
        Lebar(
          maks: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: ListTile(
                  leading: Icon(u.terbit ? Icons.public : Icons.edit_document, color: u.terbit ? Warna.benar : Colors.blueGrey),
                  title: Text(u.terbit ? 'Terbit' : 'Draf'),
                  subtitle: Text(u.terbit ? 'Siswa bisa melihat tryout ini.' : 'Hanya admin yang bisa melihat tryout ini.'),
                  trailing: u.terbit
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
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi atau petunjuk tambahan (opsional, mendukung Markdown)',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _tandai(),
              ),
              const SizedBox(height: 20),
              Text('Jadwal (WIB)', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
              const SizedBox(height: 6),
              Text(
                'Peserta bisa mulai kapan saja di antara kedua waktu ini. Subtes yang dimulai mendekati waktu tutup '
                'akan berakhir saat tryout ditutup.',
                style: tema.textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              Text('Aturan pengerjaan', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Acak urutan soal'),
                      subtitle: const Text('Setiap peserta mendapat urutan berbeda. Soal satu bacaan tetap berdampingan.'),
                      value: _atur.acakSoal,
                      onChanged: (v) => setState(() {
                        _atur = _atur.salin(acakSoal: v);
                        _berubah = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Acak urutan pilihan jawaban'),
                      subtitle: const Text('Untuk pilihan ganda dan pilihan ganda kompleks.'),
                      value: _atur.acakOpsi,
                      onChanged: (v) => setState(() {
                        _atur = _atur.salin(acakOpsi: v);
                        _berubah = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Urutan subtes bebas'),
                      subtitle: const Text('Matikan agar subtes dikerjakan berurutan seperti UTBK.'),
                      value: _atur.urutanBebas,
                      onChanged: (v) => setState(() {
                        _atur = _atur.salin(urutanBebas: v);
                        _berubah = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Tampilkan jumlah benar segera'),
                      subtitle: const Text('Jika mati, hasil baru terlihat setelah tryout ditutup.'),
                      value: _atur.hasilSegera,
                      onChanged: (v) => setState(() {
                        _atur = _atur.salin(hasilSegera: v);
                        _berubah = true;
                      }),
                    ),
                    SwitchListTile(
                      title: const Text('Buka pembahasan setelah ditutup'),
                      subtitle: const Text('Peserta bisa melihat kunci, jawabannya, dan pembahasan.'),
                      value: _atur.tampilkanPembahasan,
                      onChanged: (v) => setState(() {
                        _atur = _atur.salin(tampilkanPembahasan: v);
                        _berubah = true;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
                  label: const Text('Hapus tryout'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
