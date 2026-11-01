import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../layanan/fungsi.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/form_pendaftaran.dart';
import '../../widget/konten.dart';
import '../../widget/umum.dart';

/// Detail program (seminar/bimbel) untuk siswa: informasi, status pendaftaran, dan formulir.
class HalamanDetailProgram extends ConsumerStatefulWidget {
  const HalamanDetailProgram({super.key, required this.programId});

  final String programId;

  @override
  ConsumerState<HalamanDetailProgram> createState() => _HalamanDetailProgramState();
}

class _HalamanDetailProgramState extends ConsumerState<HalamanDetailProgram> {
  bool _mengubah = false;
  bool _sibuk = false;

  Future<void> _kirim(Map<String, Object?> data) async {
    setState(() => _sibuk = true);
    try {
      final status = await ref.read(fungsiProvider).daftarProgram(widget.programId, data);
      if (!mounted) return;
      setState(() => _mengubah = false);
      tampilkanPesan(
        context,
        status == StatusPendaftar.diterima ? 'Pendaftaran berhasil. Kamu terdaftar.' : 'Pendaftaran tersimpan. Tunggu verifikasi panitia.',
      );
    } catch (e) {
      if (mounted) tampilkanPesan(context, pesanGalat(e), galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _batal() async {
    final ya = await konfirmasi(
      context,
      judul: 'Batalkan pendaftaran?',
      isi: 'Pendaftaranmu di program ini akan dihapus.',
      ya: 'Batalkan',
      bahaya: true,
    );
    if (!ya) return;
    try {
      await ref.read(fungsiProvider).batalDaftarProgram(widget.programId);
      if (mounted) tampilkanPesan(context, 'Pendaftaran dibatalkan.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, pesanGalat(e), galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final program = ref.watch(programProvider(widget.programId));
    final saya = (ref.watch(pendaftaranSayaProvider).value ?? const <Pendaftar>[])
        .where((p) => p.programId == widget.programId)
        .firstOrNull;
    final profil = ref.watch(penggunaProvider).value;
    final email = ref.watch(authProvider).value?.email ?? '';
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/ujian')),
        title: const Text('Pendaftaran'),
        actions: const [MenuAkun()],
      ),
      body: program.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Program tidak dapat dimuat: $e'),
        data: (p) {
          if (p == null) return const PesanGalat('Program tidak ditemukan atau belum dibuka.');
          final dibuka = p.sedangDibuka(sekarang);
          final bisaUbah = dibuka && saya != null && saya.status != StatusPendaftar.ditolak;
          final tampilForm = dibuka && profil != null && ((saya == null && !p.penuh) || _mengubah);
          final tema = Theme.of(context);

          return ListView(
            children: [
              Lebar(
                maks: 760,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Label(p.jenis.label),
                    const SizedBox(height: 8),
                    Text(p.judul, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    if (p.waktuAcara.isNotEmpty) _Baris(Icons.event, p.waktuAcara),
                    if (p.tempat.isNotEmpty) _Baris(Icons.place_outlined, p.tempat),
                    _Baris(Icons.how_to_reg, 'Pendaftaran ${formatTanggalSingkat(p.buka)} sampai ${formatTanggalSingkat(p.tutup)}'),
                    if (p.kuota > 0) _Baris(Icons.groups_outlined, 'Kuota ${p.kuota} peserta${p.penuh ? ' (penuh)' : ''}'),
                    if (p.deskripsi.trim().isNotEmpty) ...[const SizedBox(height: 12), Konten(p.deskripsi)],
                    const SizedBox(height: 20),
                    if (saya != null) _KartuStatus(pendaftar: saya, program: p),
                    if (saya != null && bisaUbah && !_mengubah) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => setState(() => _mengubah = true),
                            icon: const Icon(Icons.edit),
                            label: const Text('Ubah data'),
                          ),
                          if (saya.status == StatusPendaftar.menunggu || !p.seleksiManual)
                            TextButton(
                              onPressed: _batal,
                              style: TextButton.styleFrom(foregroundColor: Warna.salah),
                              child: const Text('Batalkan pendaftaran'),
                            ),
                        ],
                      ),
                    ],
                    if (saya == null && !dibuka)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.schedule, color: Warna.tinta),
                          title: Text(
                            sekarang.isBefore(p.buka) ? 'Pendaftaran dibuka ${formatTanggalJam(p.buka)}.' : 'Pendaftaran sudah ditutup.',
                          ),
                        ),
                      ),
                    if (saya == null && dibuka && p.penuh)
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.block, color: Warna.salah),
                          title: Text('Kuota pendaftaran sudah penuh.'),
                        ),
                      ),
                    if (tampilForm) ...[
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                saya == null ? 'Formulir pendaftaran' : 'Ubah data pendaftaran',
                                style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Data diisi otomatis dari profil atau pendaftaran sebelumnya. Periksa dan lengkapi sebelum mengirim.',
                              ),
                              const SizedBox(height: 16),
                              FormPendaftaran(
                                key: ValueKey('form-${saya?.uid ?? 'baru'}-$_mengubah'),
                                jenis: p.jenis,
                                awal: saya?.data ?? profil,
                                email: email,
                                tombol: saya == null ? 'Daftar' : 'Simpan perubahan',
                                sibuk: _sibuk,
                                onKirim: _kirim,
                              ),
                              if (_mengubah) ...[
                                const SizedBox(height: 8),
                                TextButton(onPressed: () => setState(() => _mengubah = false), child: const Text('Batal mengubah')),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
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

class _Baris extends StatelessWidget {
  const _Baris(this.ikon, this.teks);

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(ikon, size: 18, color: Warna.tinta),
        const SizedBox(width: 8),
        Expanded(child: Text(teks)),
      ],
    ),
  );
}

class _KartuStatus extends StatelessWidget {
  const _KartuStatus({required this.pendaftar, required this.program});

  final Pendaftar pendaftar;
  final Program program;

  @override
  Widget build(BuildContext context) {
    final (warna, ikon) = switch (pendaftar.status) {
      StatusPendaftar.diterima => (Warna.benar, Icons.verified),
      StatusPendaftar.menunggu => (Warna.ragu, Icons.hourglass_top),
      StatusPendaftar.ditolak => (Warna.salah, Icons.cancel_outlined),
    };
    final pesan = switch (pendaftar.status) {
      StatusPendaftar.diterima =>
        program.jenis == JenisProgram.bimbel
            ? (pendaftar.kelas == null
                  ? 'Kamu diterima. Pembagian kelas akan diumumkan panitia.'
                  : 'Kamu diterima di Kelas ${pendaftar.kelas}.')
            : 'Kamu sudah terdaftar. Sampai jumpa di acara!',
      StatusPendaftar.menunggu => 'Pendaftaranmu sudah masuk dan sedang diverifikasi panitia.',
      StatusPendaftar.ditolak => 'Mohon maaf, pendaftaranmu di program ini tidak diterima.',
    };
    return Card(
      color: warna.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ikon, color: warna, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pendaftar.status.label,
                    style: TextStyle(color: warna, fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(pesan),
                  if (pendaftar.catatanAdmin.isNotEmpty) ...[const SizedBox(height: 6), Text('Catatan panitia: ${pendaftar.catatanAdmin}')],
                  if (pendaftar.status == StatusPendaftar.diterima && program.jenis == JenisProgram.bimbel) ...[
                    const SizedBox(height: 10),
                    FilledButton.icon(
                      onPressed: () => context.push('/jadwal'),
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('Lihat jadwal bimbel'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
