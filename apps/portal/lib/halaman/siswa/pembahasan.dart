import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../layanan/fungsi.dart';
import '../../tema.dart';
import '../../widget/jawaban.dart';
import '../../widget/konten.dart';
import '../../widget/umum.dart';

final _pembahasanProvider = FutureProvider.autoDispose.family((ref, String ujianId) => ref.watch(fungsiProvider).pembahasan(ujianId));

class HalamanPembahasan extends ConsumerStatefulWidget {
  const HalamanPembahasan({super.key, required this.ujianId});

  final String ujianId;

  @override
  ConsumerState<HalamanPembahasan> createState() => _HalamanPembahasanState();
}

class _HalamanPembahasanState extends ConsumerState<HalamanPembahasan> {
  String? _subtes;
  bool _hanyaSalah = false;

  @override
  Widget build(BuildContext context) {
    final ujian = ref.watch(ujianProvider(widget.ujianId)).value;
    final data = ref.watch(_pembahasanProvider(widget.ujianId));
    final sesi = ref.watch(sesiProvider(widget.ujianId)).value;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/ujian/${widget.ujianId}')),
        title: Text('Pembahasan ${ujian?.judul ?? ''}'),
      ),
      body: data.when(
        loading: () => const Memuat(pesan: 'Memuat pembahasan...'),
        error: (e, _) => PesanGalat(pesanGalat(e), ulangi: () => ref.invalidate(_pembahasanProvider(widget.ujianId))),
        data: (d) {
          final subtes = ujian?.subtes ?? const <Subtes>[];
          final pilihan = _subtes ?? (subtes.isNotEmpty ? subtes.first.id : null);
          final daftar = d.soal.where((s) => s.subtesId == pilihan && (!_hanyaSalah || !s.benar)).toList();
          final semuaDiSubtes = d.soal.where((s) => s.subtesId == pilihan).toList();
          final hasil = pilihan == null ? null : sesi?.hasil[pilihan];
          return ListView(
            children: [
              Lebar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final s in subtes)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(s.singkatan.isEmpty ? s.nama : s.singkatan),
                                selected: s.id == pilihan,
                                onSelected: (_) => setState(() => _subtes = s.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (hasil != null)
                          Label(
                            '${hasil.benar} dari ${hasil.jumlah} benar${hasil.skor != null ? ' · skor ${hasil.skor!.toStringAsFixed(0)}' : ''}',
                            warna: Warna.benar,
                          ),
                        FilterChip(
                          label: const Text('Hanya yang salah'),
                          selected: _hanyaSalah,
                          onSelected: (v) => setState(() => _hanyaSalah = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (daftar.isEmpty) const Kosong(ikon: Icons.check_circle_outline, judul: 'Tidak ada soal untuk ditampilkan.'),
                    for (final s in daftar)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _KartuPembahasan(
                          nomor: semuaDiSubtes.indexOf(s) + 1,
                          data: s,
                          stimulus: s.soal.stimulusId == null ? null : d.stimulus[s.soal.stimulusId],
                        ),
                      ),
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

class _KartuPembahasan extends StatelessWidget {
  const _KartuPembahasan({required this.nomor, required this.data, required this.stimulus});

  final int nomor;
  final SoalPembahasan data;
  final StimulusPeserta? stimulus;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Soal $nomor', style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                data.benar
                    ? const Label('Benar', warna: Warna.benar)
                    : Label(data.jawaban == null ? 'Tidak dijawab' : 'Salah', warna: Warna.salah),
                const Spacer(),
                Text(data.soal.tipe.label, style: tema.textTheme.bodySmall),
              ],
            ),
            if (stimulus != null) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                shape: const Border(),
                title: Text(stimulus!.judul.isEmpty ? 'Bacaan' : stimulus!.judul),
                children: [Konten(stimulus!.teks)],
              ),
            ],
            const SizedBox(height: 12),
            Konten(data.soal.teks),
            const SizedBox(height: 16),
            InputJawaban(soal: data.soal, jawaban: data.jawaban, kunci: data.kunci),
            if (data.pembahasan.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Warna.tintaMuda.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pembahasan', style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Konten(data.pembahasan),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
