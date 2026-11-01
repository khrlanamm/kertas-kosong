import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';

class HalamanDaftarProgram extends ConsumerWidget {
  const HalamanDaftarProgram({super.key});

  Future<void> _buat(BuildContext context, WidgetRef ref) async {
    final hasil = await showDialog<({String judul, JenisProgram jenis})>(context: context, builder: (_) => const _DialogBuat());
    if (hasil == null || !context.mounted) return;
    try {
      final id = await ref
          .read(repoProvider)
          .buatProgram(jenis: hasil.jenis, judul: hasil.judul, uid: ref.read(authProvider).value?.uid ?? '');
      if (context.mounted) context.go('/admin/program/$id');
    } catch (e) {
      if (context.mounted) tampilkanPesan(context, 'Gagal membuat program: $e', galat: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final program = ref.watch(semuaProgramProvider);
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    return Scaffold(
      appBar: AppBar(title: const Text('Program & pendaftaran'), actions: const [MenuAkun()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _buat(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Buat program'),
      ),
      body: program.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Gagal memuat: $e'),
        data: (daftar) => ListView(
          children: [
            Lebar(
              child: daftar.isEmpty
                  ? Kosong(
                      ikon: Icons.app_registration,
                      judul: 'Belum ada program',
                      pesan: 'Buat program seminar atau bimbel untuk membuka pendaftaran di portal.',
                      aksi: FilledButton(onPressed: () => _buat(context, ref), child: const Text('Buat program')),
                    )
                  : Column(
                      children: [
                        for (final p in daftar)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                onTap: () => context.go('/admin/program/${p.id}'),
                                leading: Icon(
                                  p.jenis == JenisProgram.bimbel ? Icons.school_outlined : Icons.campaign_outlined,
                                  color: Warna.tinta,
                                ),
                                title: Text(p.judul, style: const TextStyle(fontWeight: FontWeight.w700)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Pendaftaran ${formatTanggalSingkat(p.buka)} - ${formatTanggalSingkat(p.tutup)}'),
                                      Text('${p.jumlahPendaftar}${p.kuota > 0 ? '/${p.kuota}' : ''} pendaftar'),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        children: [
                                          Label(p.jenis.label, warna: Warna.tintaTua),
                                          !p.terbit
                                              ? const Label('Draf', warna: Colors.blueGrey)
                                              : p.sedangDibuka(sekarang)
                                              ? const Label('Pendaftaran dibuka', warna: Warna.benar)
                                              : sekarang.isBefore(p.buka)
                                              ? const Label('Terbit, belum dibuka', warna: Warna.tinta)
                                              : const Label('Pendaftaran ditutup', warna: Colors.blueGrey),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                              ),
                            ),
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

class _DialogBuat extends StatefulWidget {
  const _DialogBuat();

  @override
  State<_DialogBuat> createState() => _DialogBuatState();
}

class _DialogBuatState extends State<_DialogBuat> {
  final _judul = TextEditingController();
  JenisProgram _jenis = JenisProgram.bimbel;

  @override
  void dispose() {
    _judul.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buat program'),
    content: SizedBox(
      width: 440,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RadioGroup<JenisProgram>(
            groupValue: _jenis,
            onChanged: (v) => setState(() => _jenis = v ?? _jenis),
            child: const Column(
              children: [
                RadioListTile(
                  value: JenisProgram.bimbel,
                  title: Text('Bimbel'),
                  subtitle: Text('Data lengkap (tanggal lahir, SNBP), verifikasi panitia, kelas A/B, jadwal'),
                ),
                RadioListTile(
                  value: JenisProgram.seminar,
                  title: Text('Seminar'),
                  subtitle: Text('Data dasar dan minat jurusan, langsung terdaftar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _judul,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Judul',
              hintText: _jenis == JenisProgram.bimbel ? 'Bimbel Ayo Kuliah 2027' : 'Seminar Ayo Kuliah 2027',
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
          Navigator.pop(context, (judul: judul, jenis: _jenis));
        },
        child: const Text('Buat'),
      ),
    ],
  );
}
