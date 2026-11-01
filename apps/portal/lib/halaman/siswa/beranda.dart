import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';
import '../program/jadwal.dart';

class HalamanBeranda extends ConsumerWidget {
  const HalamanBeranda({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengguna = ref.watch(penggunaProvider).value;
    final ujian = ref.watch(ujianTerbitProvider);
    final sesi = ref.watch(sesiSayaProvider).value ?? const [];
    final program = ref.watch(programTerbitProvider).value ?? const <Program>[];
    final pendaftaran = ref.watch(pendaftaranSayaProvider).value ?? const <Pendaftar>[];
    final jadwal = ref.watch(jadwalSayaProvider).value ?? const <PertemuanSaya>[];
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    final tema = Theme.of(context);
    final judulBagian = tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700);

    final diterima = pendaftaran.where((p) => p.status == StatusPendaftar.diterima).map((p) => p.programId).toSet();
    final programTampil = program
        .where((p) => p.sedangDibuka(sekarang) || pendaftaran.any((d) => d.programId == p.id) || sekarang.isBefore(p.buka))
        .toList();
    final berikutnya = jadwal.where((j) => j.jadwal.selesai.isAfter(sekarang)).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [Image.asset('assets/logo.png', height: 32), const SizedBox(width: 12), const Text('Portal Bimbel')]),
        actions: const [MenuAkun()],
      ),
      body: ListView(
        children: [
          Lebar(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Halo, ${pengguna?.nama.split(' ').first ?? ''}!',
                  style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                const Text('Semangat, adik pejuang. Daftar program, cek jadwal kelas, dan kerjakan tryout di sini.'),
                if (berikutnya.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('Jadwal terdekat', style: judulBagian)),
                      TextButton(onPressed: () => context.push('/jadwal'), child: const Text('Semua jadwal')),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (final j in berikutnya) KartuPertemuan(data: j, sekarang: sekarang),
                ],
                if (programTampil.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('Pendaftaran', style: judulBagian),
                  const SizedBox(height: 12),
                  for (final p in programTampil)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _KartuProgram(program: p, saya: pendaftaran.where((d) => d.programId == p.id).firstOrNull, sekarang: sekarang),
                    ),
                ],
                const SizedBox(height: 24),
                Text('Tryout', style: judulBagian),
                const SizedBox(height: 12),
                ujian.when(
                  loading: () => const Padding(padding: EdgeInsets.all(40), child: Memuat()),
                  error: (e, _) => PesanGalat('Gagal memuat daftar tryout: $e'),
                  data: (semua) {
                    final daftar = semua.where((u) => u.programId == null || diterima.contains(u.programId)).toList();
                    return daftar.isEmpty
                        ? const Kosong(
                            ikon: Icons.event_note_outlined,
                            judul: 'Belum ada tryout',
                            pesan: 'Tryout akan muncul di sini setelah diumumkan panitia. Tryout bimbel hanya untuk peserta yang diterima.',
                          )
                        : Column(
                            children: [
                              for (final u in daftar)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _KartuUjian(ujian: u, sesi: sesi.where((s) => s.ujianId == u.id).firstOrNull, sekarang: sekarang),
                                ),
                            ],
                          );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KartuProgram extends StatelessWidget {
  const _KartuProgram({required this.program, required this.saya, required this.sekarang});

  final Program program;
  final Pendaftar? saya;
  final DateTime sekarang;

  @override
  Widget build(BuildContext context) {
    final p = program;
    final (label, warna) = switch (saya?.status) {
      StatusPendaftar.diterima => (saya!.kelas == null ? 'Diterima' : 'Diterima · Kelas ${saya!.kelas}', Warna.benar),
      StatusPendaftar.menunggu => ('Menunggu verifikasi', Warna.ragu),
      StatusPendaftar.ditolak => ('Tidak diterima', Warna.salah),
      null =>
        sekarang.isBefore(p.buka)
            ? ('Dibuka ${formatTanggalSingkat(p.buka)}', Colors.blueGrey)
            : p.penuh
            ? ('Kuota penuh', Colors.blueGrey)
            : ('Pendaftaran dibuka sampai ${formatTanggalSingkat(p.tutup)}', Warna.tinta),
    };
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/program/${p.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Warna.stabilo.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: Icon(p.jenis == JenisProgram.bimbel ? Icons.school_outlined : Icons.campaign_outlined, color: Warna.tintaTua),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.judul, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    if (p.waktuAcara.isNotEmpty) Text(p.waktuAcara, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Label(p.jenis.label, warna: Warna.tintaTua),
                        Label(label, warna: warna),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(saya == null && p.sedangDibuka(sekarang) && !p.penuh ? Icons.app_registration : Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _KartuUjian extends StatelessWidget {
  const _KartuUjian({required this.ujian, required this.sesi, required this.sekarang});

  final Ujian ujian;
  final Sesi? sesi;
  final DateTime sekarang;

  @override
  Widget build(BuildContext context) {
    final (label, warna) = statusUjianSiswa(ujian, sesi, sekarang);
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/ujian/${ujian.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: Warna.tintaMuda, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_note, color: Warna.tinta),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ujian.judul, style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('${formatTanggalSingkat(ujian.buka)} - ${formatTanggalSingkat(ujian.tutup)}', style: tema.textTheme.bodySmall),
                    Text(
                      '${ujian.subtes.length} subtes · ${ujian.totalSoal} soal · ${formatDurasi(ujian.totalDetik)}',
                      style: tema.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Label(label, warna: warna),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label status tryout dari sudut pandang peserta.
(String, Color) statusUjianSiswa(Ujian u, Sesi? s, DateTime sekarang) {
  if (s?.selesai ?? false) return ('Selesai dikerjakan', Warna.benar);
  if (u.belumDibuka(sekarang)) return ('Dibuka ${formatTanggalSingkat(u.buka)}', Colors.blueGrey);
  if (u.sudahTutup(sekarang)) return (s == null ? 'Ditutup' : 'Ditutup, sebagian dikerjakan', Colors.blueGrey);
  if (s != null) return ('Sedang dikerjakan', Warna.ragu);
  return ('Bisa dikerjakan sekarang', Warna.tinta);
}
