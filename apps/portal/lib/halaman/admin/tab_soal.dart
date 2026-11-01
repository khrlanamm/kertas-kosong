import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/template.dart';
import '../../util/waktu.dart';
import '../../widget/umum.dart';
import 'dialog_stimulus.dart';

/// Kelola subtes, soal, dan bacaan satu tryout.
class TabSoal extends ConsumerStatefulWidget {
  const TabSoal({super.key, required this.ujian, this.subtesAwal});

  final Ujian ujian;
  final String? subtesAwal;

  @override
  ConsumerState<TabSoal> createState() => _TabSoalState();
}

class _TabSoalState extends ConsumerState<TabSoal> {
  late String? _subtes = widget.subtesAwal;

  Ujian get _u => widget.ujian;

  String? get _terpilih {
    if (_subtes != null && _u.subtes.any((s) => s.id == _subtes)) return _subtes;
    return _u.subtes.isEmpty ? null : _u.subtes.first.id;
  }

  Future<void> _simpanSubtes(List<Subtes> daftar) async {
    try {
      await ref.read(repoProvider).simpanSubtes(_u.id, daftar);
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan subtes: $e', galat: true);
    }
  }

  Future<void> _editSubtes([Subtes? lama]) async {
    final hasil = await showDialog<Subtes>(
      context: context,
      builder: (_) => _DialogSubtes(subtes: lama),
    );
    if (hasil == null) return;
    final daftar = [..._u.subtes];
    final i = daftar.indexWhere((s) => s.id == hasil.id);
    i >= 0 ? daftar[i] = hasil : daftar.add(hasil);
    await _simpanSubtes(daftar);
    setState(() => _subtes = hasil.id);
  }

  Future<void> _hapusSubtes(Subtes s) async {
    if ((_u.jumlahSoal[s.id] ?? 0) > 0) {
      tampilkanPesan(context, 'Hapus dulu semua soal di ${s.nama}.', galat: true);
      return;
    }
    final ya = await konfirmasi(context, judul: 'Hapus subtes?', isi: 'Subtes ${s.nama} akan dihapus.', ya: 'Hapus', bahaya: true);
    if (ya) await _simpanSubtes(_u.subtes.where((t) => t.id != s.id).toList());
  }

  Future<void> _pindahSubtes(int i, int arah) async {
    final daftar = [..._u.subtes];
    final j = i + arah;
    if (j < 0 || j >= daftar.length) return;
    final t = daftar[i];
    daftar[i] = daftar[j];
    daftar[j] = t;
    await _simpanSubtes(daftar);
  }

  @override
  Widget build(BuildContext context) {
    final soal = ref.watch(soalProvider(_u.id));
    final stimulus = ref.watch(stimulusProvider(_u.id)).value ?? const <Stimulus>[];
    final lebar = MediaQuery.sizeOf(context).width >= 1100;
    final terpilih = _terpilih;

    final daftarSubtes = _DaftarSubtes(
      ujian: _u,
      terpilih: terpilih,
      onPilih: (id) => setState(() => _subtes = id),
      onTambah: () => _editSubtes(),
      onEdit: _editSubtes,
      onHapus: _hapusSubtes,
      onPindah: _pindahSubtes,
    );

    final isi = soal.when(
      loading: () => const Memuat(),
      error: (e, _) => PesanGalat('Gagal memuat soal: $e'),
      data: (semua) {
        if (terpilih == null) {
          return const Kosong(ikon: Icons.view_list, judul: 'Belum ada subtes', pesan: 'Tambahkan subtes terlebih dahulu.');
        }
        final subtes = _u.subtes.firstWhere((s) => s.id == terpilih);
        return _DaftarSoal(
          ujianId: _u.id,
          subtes: subtes,
          soal: semua.where((s) => s.subtesId == terpilih).toList(),
          stimulus: stimulus.where((s) => s.subtesId == terpilih).toList(),
        );
      },
    );

    if (lebar) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: daftarSubtes),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: isi),
        ],
      );
    }
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.all(16), child: daftarSubtes),
        ),
        SliverFillRemaining(hasScrollBody: true, child: isi),
      ],
    );
  }
}

class _DaftarSubtes extends StatelessWidget {
  const _DaftarSubtes({
    required this.ujian,
    required this.terpilih,
    required this.onPilih,
    required this.onTambah,
    required this.onEdit,
    required this.onHapus,
    required this.onPindah,
  });

  final Ujian ujian;
  final String? terpilih;
  final ValueChanged<String> onPilih;
  final VoidCallback onTambah;
  final ValueChanged<Subtes> onEdit;
  final ValueChanged<Subtes> onHapus;
  final void Function(int indeks, int arah) onPindah;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Subtes', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ),
            TextButton.icon(onPressed: onTambah, icon: const Icon(Icons.add), label: const Text('Tambah')),
          ],
        ),
        Text('${ujian.totalSoal} soal · ${formatDurasi(ujian.totalDetik)}', style: tema.textTheme.bodySmall),
        const SizedBox(height: 8),
        for (var i = 0; i < ujian.subtes.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _KartuSubtes(
              subtes: ujian.subtes[i],
              jumlah: ujian.jumlahSoal[ujian.subtes[i].id] ?? 0,
              terpilih: ujian.subtes[i].id == terpilih,
              onTap: () => onPilih(ujian.subtes[i].id),
              onAksi: (aksi) => switch (aksi) {
                'edit' => onEdit(ujian.subtes[i]),
                'naik' => onPindah(i, -1),
                'turun' => onPindah(i, 1),
                'hapus' => onHapus(ujian.subtes[i]),
                _ => null,
              },
            ),
          ),
      ],
    );
  }
}

class _KartuSubtes extends StatelessWidget {
  const _KartuSubtes({required this.subtes, required this.jumlah, required this.terpilih, required this.onTap, required this.onAksi});

  final Subtes subtes;
  final int jumlah;
  final bool terpilih;
  final VoidCallback onTap;
  final ValueChanged<String> onAksi;

  @override
  Widget build(BuildContext context) {
    final cukup = subtes.targetSoal == 0 || jumlah == subtes.targetSoal;
    return Card(
      color: terpilih ? Warna.tintaMuda : Colors.white,
      child: ListTile(
        onTap: onTap,
        title: Text(subtes.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$jumlah${subtes.targetSoal > 0 ? '/${subtes.targetSoal}' : ''} soal · ${formatDurasi(subtes.durasiDetik)}',
          style: TextStyle(color: cukup ? null : Colors.orange.shade800),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Aksi subtes',
          onSelected: onAksi,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Ubah')),
            PopupMenuItem(value: 'naik', child: Text('Pindah ke atas')),
            PopupMenuItem(value: 'turun', child: Text('Pindah ke bawah')),
            PopupMenuItem(value: 'hapus', child: Text('Hapus')),
          ],
        ),
      ),
    );
  }
}

class _DaftarSoal extends ConsumerWidget {
  const _DaftarSoal({required this.ujianId, required this.subtes, required this.soal, required this.stimulus});

  final String ujianId;
  final Subtes subtes;
  final List<Soal> soal;
  final List<Stimulus> stimulus;

  Future<void> _pindah(BuildContext context, WidgetRef ref, int i, int arah) async {
    final j = i + arah;
    if (j < 0 || j >= soal.length) return;
    final daftar = [...soal];
    final t = daftar[i];
    daftar[i] = daftar[j];
    daftar[j] = t;
    await ref.read(repoProvider).aturUrutanSoal(ujianId, daftar);
  }

  Future<void> _hapus(BuildContext context, WidgetRef ref, Soal s, int nomor) async {
    final ya = await konfirmasi(context, judul: 'Hapus soal $nomor?', isi: 'Soal ini akan dihapus permanen.', ya: 'Hapus', bahaya: true);
    if (!ya) return;
    final repo = ref.read(repoProvider);
    await repo.hapusSoal(ujianId, s.id);
    await repo.aturUrutanSoal(ujianId, soal.where((x) => x.id != s.id).toList());
  }

  Future<void> _hapusStimulus(BuildContext context, WidgetRef ref, Stimulus st) async {
    final dipakai = soal.where((s) => s.stimulusId == st.id).length;
    if (dipakai > 0) {
      tampilkanPesan(context, 'Bacaan ini masih dipakai $dipakai soal.', galat: true);
      return;
    }
    final ya = await konfirmasi(context, judul: 'Hapus bacaan?', isi: '"${st.judul}" akan dihapus.', ya: 'Hapus', bahaya: true);
    if (ya) await ref.read(repoProvider).hapusStimulus(ujianId, st.id);
  }

  String _cuplikan(String teks) {
    final polos = teks
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), '[gambar]')
        .replaceAll(RegExp(r'[#*_>`|$\\]'), '')
        .replaceAll(RegExp(r'-{3,}'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return polos.length > 140 ? '${polos.substring(0, 140)}...' : polos;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final namaStimulus = {for (final s in stimulus) s.id: s.judul};
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(subtes.nama, style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            FilledButton.icon(
              onPressed: () => context.go('/admin/ujian/$ujianId/soal/baru?subtes=${subtes.id}'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah soal'),
            ),
            OutlinedButton.icon(
              onPressed: () => bukaDialogStimulus(context, ref, ujianId: ujianId, subtesId: subtes.id),
              icon: const Icon(Icons.article_outlined),
              label: const Text('Tambah bacaan'),
            ),
          ],
        ),
        if (stimulus.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Bacaan / stimulus', style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (final st in stimulus)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.article_outlined, color: Warna.tinta),
                title: Text(st.judul),
                subtitle: Text(
                  'Dipakai ${soal.where((s) => s.stimulusId == st.id).length} soal · ${_cuplikan(st.teks)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () => bukaDialogStimulus(context, ref, ujianId: ujianId, subtesId: subtes.id, lama: st),
                trailing: IconButton(
                  tooltip: 'Hapus bacaan',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _hapusStimulus(context, ref, st),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        Text(
          'Soal (${soal.length}${subtes.targetSoal > 0 ? '/${subtes.targetSoal}' : ''})',
          style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        if (soal.isEmpty)
          const Kosong(
            ikon: Icons.quiz_outlined,
            judul: 'Belum ada soal',
            pesan: 'Tekan "Tambah soal" untuk mulai menyusun soal subtes ini.',
          ),
        for (var i = 0; i < soal.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Warna.tintaMuda,
                child: Text('${i + 1}', style: const TextStyle(color: Warna.tintaTua)),
              ),
              title: Text(_cuplikan(soal[i].teks), maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Label(soal[i].tipe.label),
                    if (soal[i].stimulusId != null) Label('Bacaan: ${namaStimulus[soal[i].stimulusId] ?? '?'}', warna: Colors.deepPurple),
                    if (soal[i].pembahasan.trim().isEmpty) const Label('Tanpa pembahasan', warna: Colors.orange),
                  ],
                ),
              ),
              onTap: () => context.go('/admin/ujian/$ujianId/soal/${soal[i].id}'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Aksi soal',
                onSelected: (a) => switch (a) {
                  'naik' => _pindah(context, ref, i, -1),
                  'turun' => _pindah(context, ref, i, 1),
                  'hapus' => _hapus(context, ref, soal[i], i + 1),
                  _ => null,
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'naik', child: Text('Pindah ke atas')),
                  PopupMenuItem(value: 'turun', child: Text('Pindah ke bawah')),
                  PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                ],
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _DialogSubtes extends StatefulWidget {
  const _DialogSubtes({this.subtes});

  final Subtes? subtes;

  @override
  State<_DialogSubtes> createState() => _DialogSubtesState();
}

class _DialogSubtesState extends State<_DialogSubtes> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.subtes?.nama ?? '');
  late final _singkatan = TextEditingController(text: widget.subtes?.singkatan ?? '');
  late final _durasi = TextEditingController(
    text: widget.subtes == null ? '30' : (widget.subtes!.durasiDetik / 60).toString().replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ','),
  );
  late final _target = TextEditingController(text: widget.subtes?.targetSoal.toString() ?? '20');

  @override
  void dispose() {
    for (final c in [_nama, _singkatan, _durasi, _target]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _menit(String v) => double.tryParse(v.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.subtes == null ? 'Tambah subtes' : 'Ubah subtes'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nama,
              decoration: const InputDecoration(labelText: 'Nama subtes'),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Wajib diisi.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _singkatan,
              decoration: const InputDecoration(labelText: 'Singkatan (opsional)', hintText: 'Contoh: PU'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _durasi,
                    decoration: const InputDecoration(labelText: 'Durasi (menit)', hintText: 'Contoh: 42,5'),
                    validator: (v) => (_menit(v ?? '') ?? 0) <= 0 ? 'Isi durasi yang valid.' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _target,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Target jumlah soal'),
                    validator: (v) => int.tryParse(v ?? '') == null ? 'Isi angka.' : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(
        onPressed: () {
          if (!_form.currentState!.validate()) return;
          final detik = (_menit(_durasi.text)! * 60).round();
          final lama = widget.subtes;
          Navigator.pop(
            context,
            Subtes(
              id: lama?.id ?? idAcak('s'),
              nama: _nama.text.trim(),
              singkatan: _singkatan.text.trim(),
              durasiDetik: detik,
              targetSoal: int.parse(_target.text),
            ),
          );
        },
        child: const Text('Simpan'),
      ),
    ],
  );
}
