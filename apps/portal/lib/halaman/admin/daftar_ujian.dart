import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/template.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';

class HalamanDaftarUjian extends ConsumerWidget {
  const HalamanDaftarUjian({super.key});

  Future<void> _buat(BuildContext context, WidgetRef ref) async {
    final hasil = await showDialog<({String judul, bool template})>(context: context, builder: (_) => const _DialogBuat());
    if (hasil == null || !context.mounted) return;
    final uid = ref.read(authProvider).value?.uid ?? '';
    final besok = DateTime.now().add(const Duration(days: 7));
    final buka = dariWib(DateTime(besok.year, besok.month, besok.day), const TimeOfDay(hour: 8, minute: 0));
    try {
      final id = await ref
          .read(repoProvider)
          .buatUjian(
            judul: hasil.judul,
            subtes: hasil.template ? templateUtbk : const [],
            buka: buka,
            tutup: buka.add(const Duration(days: 2)),
            uid: uid,
          );
      if (context.mounted) context.go('/admin/ujian/$id');
    } catch (e) {
      if (context.mounted) tampilkanPesan(context, 'Gagal membuat tryout: $e', galat: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ujian = ref.watch(semuaUjianProvider);
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Tryout'), actions: const [MenuAkun()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buat(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Buat tryout'),
      ),
      body: ujian.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Gagal memuat: $e'),
        data: (daftar) => ListView(
          children: [
            Lebar(
              child: daftar.isEmpty
                  ? Kosong(
                      ikon: Icons.edit_note,
                      judul: 'Belum ada tryout',
                      pesan: 'Buat tryout pertama dengan template UTBK-SNBT: 7 subtes, 160 soal, 195 menit.',
                      aksi: FilledButton(onPressed: () => _buat(context, ref), child: const Text('Buat tryout')),
                    )
                  : Column(
                      children: [
                        for (final u in daftar)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _KartuUjianAdmin(ujian: u, sekarang: sekarang),
                          ),
                        const SizedBox(height: 72),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KartuUjianAdmin extends StatelessWidget {
  const _KartuUjianAdmin({required this.ujian, required this.sekarang});

  final Ujian ujian;
  final DateTime sekarang;

  @override
  Widget build(BuildContext context) {
    final target = ujian.subtes.fold(0, (s, t) => s + t.targetSoal);
    final (label, warna) = !ujian.terbit
        ? ('Draf', Colors.blueGrey)
        : ujian.belumDibuka(sekarang)
        ? ('Terbit · belum dibuka', Warna.tinta)
        : ujian.sedangBuka(sekarang)
        ? ('Sedang berlangsung', Warna.ragu)
        : ('Ditutup', Warna.benar);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        onTap: () => context.go('/admin/ujian/${ujian.id}'),
        title: Text(ujian.judul, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${formatTanggalSingkat(ujian.buka)} - ${formatTanggalSingkat(ujian.tutup)}'),
              Text(
                '${ujian.subtes.length} subtes · ${ujian.totalSoal}${target > 0 ? '/$target' : ''} soal · ${formatDurasi(ujian.totalDetik)}',
              ),
              const SizedBox(height: 6),
              Label(label, warna: warna),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DialogBuat extends StatefulWidget {
  const _DialogBuat();

  @override
  State<_DialogBuat> createState() => _DialogBuatState();
}

class _DialogBuatState extends State<_DialogBuat> {
  final _judul = TextEditingController(text: 'Tryout ');
  bool _template = true;

  @override
  void dispose() {
    _judul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buat tryout'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _judul,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Judul', hintText: 'Contoh: Tryout 1 Bimbel Ayo Kuliah 2027'),
          ),
          const SizedBox(height: 16),
          RadioGroup<bool>(
            groupValue: _template,
            onChanged: (v) => setState(() => _template = v ?? true),
            child: const Column(
              children: [
                RadioListTile(
                  value: true,
                  title: Text('Template UTBK-SNBT'),
                  subtitle: Text('PU, PPU, PBM, PK, Literasi Indonesia, Literasi Inggris, Penalaran Matematika'),
                ),
                RadioListTile(value: false, title: Text('Kosong'), subtitle: Text('Atur subtes sendiri')),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(
        onPressed: () {
          final judul = _judul.text.trim();
          if (judul.isEmpty) return;
          Navigator.pop(context, (judul: judul, template: _template));
        },
        child: const Text('Buat'),
      ),
    ],
  );
}
