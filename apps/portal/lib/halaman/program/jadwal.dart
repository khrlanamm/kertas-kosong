import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';

/// Pertemuan bimbel milik peserta: dari program bimbel tempat ia diterima, untuk kelasnya.
typedef PertemuanSaya = ({Program program, String? kelas, Jadwal jadwal});

final jadwalSayaProvider = Provider<AsyncValue<List<PertemuanSaya>>>((ref) {
  final pendaftaran = ref.watch(pendaftaranSayaProvider);
  return pendaftaran.whenData((daftar) {
    final hasil = <PertemuanSaya>[];
    for (final p in daftar.where((p) => p.status == StatusPendaftar.diterima)) {
      final program = ref.watch(programProvider(p.programId)).value;
      if (program == null || program.jenis != JenisProgram.bimbel) continue;
      for (final j in ref.watch(jadwalProvider(p.programId)).value ?? const <Jadwal>[]) {
        if (j.untukKelas(p.kelas)) hasil.add((program: program, kelas: p.kelas, jadwal: j));
      }
    }
    return hasil..sort((a, b) => a.jadwal.mulai.compareTo(b.jadwal.mulai));
  });
});

class HalamanJadwal extends ConsumerWidget {
  const HalamanJadwal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jadwal = ref.watch(jadwalSayaProvider);
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/ujian')),
        title: const Text('Jadwal bimbel'),
        actions: const [MenuAkun()],
      ),
      body: jadwal.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Jadwal tidak dapat dimuat: $e'),
        data: (daftar) {
          if (daftar.isEmpty) {
            return const Lebar(
              child: Kosong(
                ikon: Icons.calendar_month,
                judul: 'Belum ada jadwal',
                pesan: 'Jadwal muncul di sini setelah kamu diterima di bimbel dan panitia mengatur jadwal kelasmu.',
              ),
            );
          }
          final akanDatang = daftar.where((d) => d.jadwal.selesai.isAfter(sekarang)).toList();
          final lewat = daftar.where((d) => !d.jadwal.selesai.isAfter(sekarang)).toList().reversed.toList();
          final kelas = daftar.map((d) => d.kelas).whereType<String>().toSet();
          return ListView(
            children: [
              Lebar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (kelas.isNotEmpty)
                      Text('Kelas ${kelas.join(', ')}', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    if (akanDatang.isEmpty) const Kosong(ikon: Icons.event_available, judul: 'Tidak ada pertemuan berikutnya.'),
                    for (final d in akanDatang) KartuPertemuan(data: d, sekarang: sekarang),
                    if (lewat.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text('Sudah lewat', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      for (final d in lewat)
                        Opacity(
                          opacity: 0.6,
                          child: KartuPertemuan(data: d, sekarang: sekarang),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class KartuPertemuan extends StatelessWidget {
  const KartuPertemuan({super.key, required this.data, required this.sekarang});

  final PertemuanSaya data;
  final DateTime sekarang;

  @override
  Widget build(BuildContext context) {
    final j = data.jadwal;
    final wib = keWib(j.mulai);
    final berlangsung = !sekarang.isBefore(j.mulai.subtract(const Duration(minutes: 15))) && sekarang.isBefore(j.selesai);
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 58,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: berlangsung ? Warna.tinta : Warna.tintaMuda, borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    Text(
                      DateFormat('EEE', 'id_ID').format(wib),
                      style: TextStyle(fontSize: 12, color: berlangsung ? Colors.white : Warna.tintaTua),
                    ),
                    Text(
                      '${wib.day}',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: berlangsung ? Colors.white : Warna.tintaTua),
                    ),
                    Text(
                      DateFormat('MMM', 'id_ID').format(wib),
                      style: TextStyle(fontSize: 12, color: berlangsung ? Colors.white : Warna.tintaTua),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(j.judul, style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('${formatJam(j.mulai).replaceAll(' WIB', '')}-${formatJam(j.selesai)} · ${data.program.judul}'),
                    Text(j.kelas.isEmpty ? 'Semua kelas' : 'Kelas ${j.kelas.join(', ')}', style: tema.textTheme.bodySmall),
                    if (j.catatan.isNotEmpty) ...[const SizedBox(height: 4), Text(j.catatan, style: tema.textTheme.bodySmall)],
                    if (j.tautan.isNotEmpty && j.selesai.isAfter(sekarang)) ...[
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => launchUrl(Uri.parse(j.tautan), webOnlyWindowName: '_blank'),
                        icon: const Icon(Icons.videocam_outlined),
                        label: Text(berlangsung ? 'Masuk kelas sekarang' : 'Tautan kelas'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
