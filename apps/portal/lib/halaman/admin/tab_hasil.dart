import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../layanan/fungsi.dart';
import '../../tema.dart';
import '../../util/unduh.dart';
import '../../util/waktu.dart';
import '../../widget/umum.dart';

class TabHasil extends ConsumerStatefulWidget {
  const TabHasil({super.key, required this.ujian});

  final Ujian ujian;

  @override
  ConsumerState<TabHasil> createState() => _TabHasilState();
}

class _TabHasilState extends ConsumerState<TabHasil> {
  bool _menghitung = false;

  Future<void> _hitung() async {
    final ya = await konfirmasi(
      context,
      judul: 'Hitung skor?',
      isi:
          'Semua jawaban dinilai ulang dengan kunci terbaru, lalu skor berbobot (200-1000) dihitung dari tingkat kesulitan '
          'tiap soal. Proses ini bisa diulang kapan saja, misalnya setelah memperbaiki kunci.',
      ya: 'Hitung',
    );
    if (!ya) return;
    setState(() => _menghitung = true);
    try {
      final n = await ref.read(fungsiProvider).hitungSkor(widget.ujian.id);
      if (mounted) tampilkanPesan(context, 'Skor $n peserta sudah dihitung.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, pesanGalat(e), galat: true);
    } finally {
      if (mounted) setState(() => _menghitung = false);
    }
  }

  List<Sesi> _urutkan(List<Sesi> sesi) => [...sesi]
    ..sort((a, b) {
      final skor = (b.skorRata ?? -1).compareTo(a.skorRata ?? -1);
      if (skor != 0) return skor;
      final benar = b.totalBenar.compareTo(a.totalBenar);
      return benar != 0 ? benar : a.nama.compareTo(b.nama);
    });

  String _csv(List<Sesi> sesi) {
    final u = widget.ujian;
    String sel(Object? v) {
      final t = '${v ?? ''}';
      return t.contains(RegExp('[",;\n]')) ? '"${t.replaceAll('"', '""')}"' : t;
    }

    final kepala = [
      'Peringkat',
      'Nama',
      'Sekolah',
      'Status',
      for (final s in u.subtes) ...[
        '${s.singkatan.isEmpty ? s.nama : s.singkatan} benar',
        '${s.singkatan.isEmpty ? s.nama : s.singkatan} skor',
      ],
      'Total benar',
      'Skor rata-rata',
    ];
    final baris = <List<Object?>>[];
    for (var i = 0; i < sesi.length; i++) {
      final x = sesi[i];
      baris.add([
        i + 1,
        x.nama,
        x.sekolah,
        x.selesai ? 'Selesai' : 'Belum selesai',
        for (final s in u.subtes) ...[x.hasil[s.id]?.benar, x.hasil[s.id]?.skor?.toStringAsFixed(2)],
        x.totalBenar,
        x.skorRata?.toStringAsFixed(2),
      ]);
    }
    return [kepala, ...baris].map((r) => r.map(sel).join(';')).join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.ujian;
    final sesi = ref.watch(sesiUjianProvider(u.id));
    final sekarang = ref.watch(detakProvider).value ?? DateTime.now();
    final tutup = u.sudahTutup(sekarang);
    final tema = Theme.of(context);

    return sesi.when(
      loading: () => const Memuat(),
      error: (e, _) => PesanGalat('Gagal memuat hasil: $e'),
      data: (daftar) {
        final terurut = _urutkan(daftar);
        final selesai = daftar.where((s) => s.selesai).length;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Label('${daftar.length} peserta', warna: Warna.tinta),
                Label('$selesai selesai', warna: Warna.benar),
                if (u.skorDihitung != null) Label('Skor dihitung ${formatTanggalSingkat(u.skorDihitung!)}', warna: Colors.deepPurple),
                Tooltip(
                  message: tutup ? '' : 'Bisa dihitung setelah tryout ditutup (${formatTanggalSingkat(u.tutup)}).',
                  child: FilledButton.icon(
                    onPressed: tutup && !_menghitung && daftar.isNotEmpty ? _hitung : null,
                    icon: _menghitung
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.calculate_outlined),
                    label: Text(u.skorDihitung == null ? 'Hitung skor' : 'Hitung ulang skor'),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: daftar.isEmpty
                      ? null
                      : () => unduhTeks('hasil-${u.judul.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-')}.csv', _csv(terurut), mime: 'text/csv'),
                  icon: const Icon(Icons.download),
                  label: const Text('Unduh CSV'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sebelum skor dihitung, tabel menampilkan jumlah benar. Skor berbobot memberi nilai lebih pada soal yang jarang '
              'dijawab benar, dengan skala 200-1000 seperti laporan UTBK. Ini perkiraan, bukan IRT resmi.',
              style: tema.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            if (daftar.isEmpty)
              const Kosong(
                ikon: Icons.groups_outlined,
                judul: 'Belum ada peserta',
                pesan: 'Hasil peserta muncul di sini begitu mereka mulai mengerjakan.',
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(Warna.tintaMuda),
                    columns: [
                      const DataColumn(label: Text('#')),
                      const DataColumn(label: Text('Nama')),
                      const DataColumn(label: Text('Sekolah')),
                      for (final s in u.subtes) DataColumn(label: Text(s.singkatan.isEmpty ? s.nama : s.singkatan), numeric: true),
                      const DataColumn(label: Text('Benar'), numeric: true),
                      const DataColumn(label: Text('Skor'), numeric: true),
                    ],
                    rows: [
                      for (var i = 0; i < terurut.length; i++)
                        DataRow(
                          cells: [
                            DataCell(Text('${i + 1}')),
                            DataCell(
                              Row(
                                children: [
                                  Text(terurut[i].nama),
                                  if (!terurut[i].selesai)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 8),
                                      child: Label('belum selesai', warna: Warna.ragu),
                                    ),
                                ],
                              ),
                            ),
                            DataCell(Text(terurut[i].sekolah)),
                            for (final s in u.subtes) DataCell(Text(_sel(terurut[i].hasil[s.id]))),
                            DataCell(Text('${terurut[i].totalBenar}')),
                            DataCell(Text(terurut[i].skorRata == null ? '-' : formatAngka(terurut[i].skorRata!, desimal: 2))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _sel(HasilSubtes? h) {
    if (h == null) return '-';
    return h.skor != null ? '${h.skor!.toStringAsFixed(0)} (${h.benar})' : '${h.benar}/${h.jumlah}';
  }
}
