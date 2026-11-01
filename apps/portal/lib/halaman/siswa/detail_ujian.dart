import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/waktu.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/konten.dart';
import '../../widget/umum.dart';

class HalamanDetailUjian extends ConsumerWidget {
  const HalamanDetailUjian({super.key, required this.ujianId});

  final String ujianId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ujian = ref.watch(ujianProvider(ujianId));
    final sesi = ref.watch(sesiProvider(ujianId)).value;
    final pengguna = ref.watch(penggunaProvider).value;
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/ujian')),
        title: const Text('Tryout'),
        actions: const [MenuAkun()],
      ),
      body: ujian.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Tryout tidak dapat dimuat: $e'),
        data: (u) => u == null
            ? const PesanGalat('Tryout tidak ditemukan atau belum dibuka.')
            : _Isi(ujian: u, sesi: sesi, sekarang: sekarang, admin: pengguna?.admin ?? false),
      ),
    );
  }
}

enum _StatusSubtes { selesai, aktif, berikutnya, terkunci, tersedia }

class _Isi extends StatelessWidget {
  const _Isi({required this.ujian, required this.sesi, required this.sekarang, required this.admin});

  final Ujian ujian;
  final Sesi? sesi;
  final DateTime sekarang;
  final bool admin;

  bool get _bisaMengerjakan => admin || ujian.sedangBuka(sekarang);

  _StatusSubtes _status(int i) {
    final s = ujian.subtes[i];
    final selesai = sesi?.subtesSelesai ?? const [];
    if (selesai.contains(s.id)) return _StatusSubtes.selesai;
    if (sesi?.subtesAktif == s.id) return _StatusSubtes.aktif;
    if (ujian.pengaturan.urutanBebas) return _StatusSubtes.tersedia;
    final pertamaBelum = ujian.subtes.indexWhere((t) => !selesai.contains(t.id));
    return i == pertamaBelum ? _StatusSubtes.berikutnya : _StatusSubtes.terkunci;
  }

  Future<void> _mulai(BuildContext context, Subtes s, {required bool lanjut}) async {
    if (!lanjut) {
      final ya = await konfirmasi(
        context,
        judul: 'Mulai ${s.nama}?',
        isi:
            'Waktu ${formatDurasi(s.durasiDetik)} langsung berjalan setelah kamu menekan Mulai dan tidak bisa dijeda. '
            'Pastikan koneksi internet stabil.',
        ya: 'Mulai',
      );
      if (!ya || !context.mounted) return;
    }
    context.push('/ujian/${ujian.id}/kerjakan/${s.id}');
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final tutup = ujian.sudahTutup(sekarang);
    final tampilHasil = ujian.pengaturan.hasilSegera || tutup;
    final selesaiSemua = sesi?.selesai ?? false;

    return ListView(
      children: [
        Lebar(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (admin)
                Card(
                  color: Warna.stabilo.withValues(alpha: 0.5),
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Text('Mode uji admin: kamu bisa mencoba tryout ini kapan saja. Percobaan admin tidak ikut dinilai.'),
                  ),
                ),
              if (admin) const SizedBox(height: 16),
              Text(ujian.judul, style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _Info(Icons.event, '${formatTanggalJam(ujian.buka)} sampai ${formatTanggalJam(ujian.tutup)}'),
                  _Info(Icons.quiz_outlined, '${ujian.subtes.length} subtes · ${ujian.totalSoal} soal'),
                  _Info(Icons.timer_outlined, formatDurasi(ujian.totalDetik)),
                ],
              ),
              if (ujian.deskripsi.trim().isNotEmpty) ...[const SizedBox(height: 16), Konten(ujian.deskripsi)],
              const SizedBox(height: 20),
              if (!admin && ujian.belumDibuka(sekarang)) _Pemberitahuan(Icons.schedule, 'Tryout dibuka ${formatTanggalJam(ujian.buka)}.'),
              if (!admin && tutup) _Pemberitahuan(Icons.lock_clock, 'Tryout sudah ditutup.'),
              if (selesaiSemua) _Pemberitahuan(Icons.verified, 'Kamu sudah menyelesaikan semua subtes. Terima kasih!', warna: Warna.benar),
              if (sesi != null && tutup && ujian.pengaturan.tampilkanPembahasan) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => context.push('/ujian/${ujian.id}/pembahasan'),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Lihat pembahasan'),
                ),
              ],
              if (sesi != null && tampilHasil && sesi!.skorRata != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.emoji_events_outlined, color: Warna.tinta),
                    title: Text('Skor rata-rata: ${formatAngka(sesi!.skorRata!, desimal: 2)}'),
                    subtitle: const Text('Skor berbobot tingkat kesulitan, skala 200-1000.'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('Subtes', style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              for (var i = 0; i < ujian.subtes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _KartuSubtes(
                    nomor: i + 1,
                    subtes: ujian.subtes[i],
                    jumlahSoal: ujian.jumlahSoal[ujian.subtes[i].id] ?? 0,
                    status: _status(i),
                    hasil: tampilHasil ? sesi?.hasil[ujian.subtes[i].id] : null,
                    bisa: _bisaMengerjakan,
                    onMulai: (lanjut) => _mulai(context, ujian.subtes[i], lanjut: lanjut),
                  ),
                ),
              const SizedBox(height: 16),
              _Petunjuk(urutanBebas: ujian.pengaturan.urutanBebas),
            ],
          ),
        ),
      ],
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.ikon, this.teks);

  final IconData ikon;
  final String teks;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(ikon, size: 18, color: Warna.tinta),
      const SizedBox(width: 6),
      Flexible(child: Text(teks)),
    ],
  );
}

class _Pemberitahuan extends StatelessWidget {
  const _Pemberitahuan(this.ikon, this.teks, {this.warna = Warna.tinta});

  final IconData ikon;
  final String teks;
  final Color warna;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Card(
      child: ListTile(
        leading: Icon(ikon, color: warna),
        title: Text(teks),
      ),
    ),
  );
}

class _KartuSubtes extends StatelessWidget {
  const _KartuSubtes({
    required this.nomor,
    required this.subtes,
    required this.jumlahSoal,
    required this.status,
    required this.hasil,
    required this.bisa,
    required this.onMulai,
  });

  final int nomor;
  final Subtes subtes;
  final int jumlahSoal;
  final _StatusSubtes status;
  final HasilSubtes? hasil;
  final bool bisa;
  final void Function(bool lanjut) onMulai;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final Widget aksi = switch (status) {
      _StatusSubtes.selesai =>
        hasil == null
            ? const Label('Selesai', warna: Warna.benar)
            : Label(
                hasil!.skor != null ? 'Skor ${formatAngka(hasil!.skor!, desimal: 0)}' : '${hasil!.benar}/${hasil!.jumlah} benar',
                warna: Warna.benar,
              ),
      _StatusSubtes.aktif => FilledButton(onPressed: bisa ? () => onMulai(true) : null, child: const Text('Lanjutkan')),
      _StatusSubtes.berikutnya ||
      _StatusSubtes.tersedia => FilledButton(onPressed: bisa && jumlahSoal > 0 ? () => onMulai(false) : null, child: const Text('Mulai')),
      _StatusSubtes.terkunci => const Tooltip(
        message: 'Selesaikan subtes sebelumnya dulu',
        child: Icon(Icons.lock_outline, color: Colors.black38),
      ),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: status == _StatusSubtes.selesai ? Warna.benar : Warna.tintaMuda,
              child: status == _StatusSubtes.selesai
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : Text(
                      '$nomor',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Warna.tinta),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(subtes.label, style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                  Text('$jumlahSoal soal · ${formatDurasi(subtes.durasiDetik)}', style: tema.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 12),
            aksi,
          ],
        ),
      ),
    );
  }
}

class _Petunjuk extends StatelessWidget {
  const _Petunjuk({required this.urutanBebas});

  final bool urutanBebas;

  @override
  Widget build(BuildContext context) {
    final butir = [
      urutanBebas
          ? 'Subtes boleh dikerjakan dalam urutan apa saja. Waktu tiap subtes mulai berjalan saat kamu menekan Mulai dan tidak bisa dijeda.'
          : 'Subtes dikerjakan berurutan seperti UTBK. Waktu tiap subtes mulai berjalan saat kamu menekan Mulai dan tidak bisa dijeda.',
      'Jawaban tersimpan otomatis setiap kali kamu memilih atau mengetik jawaban.',
      'Jika koneksi terputus atau halaman tertutup, buka lagi halaman ini lalu tekan Lanjutkan. Waktu tetap berjalan.',
      'Saat waktu habis, subtes dikumpulkan otomatis.',
      'Tidak ada pengurangan nilai untuk jawaban salah, jadi usahakan semua soal terisi.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Petunjuk', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final b in butir)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
