import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../widget/editor_konten.dart';
import '../../widget/umum.dart';

/// Buat atau ubah bacaan (stimulus) yang bisa dipakai beberapa soal. Mengembalikan ID bacaan.
Future<String?> bukaDialogStimulus(
  BuildContext context,
  WidgetRef ref, {
  required String ujianId,
  required String subtesId,
  Stimulus? lama,
}) => showDialog<String>(
  context: context,
  builder: (_) => _DialogStimulus(ujianId: ujianId, subtesId: subtesId, lama: lama),
);

class _DialogStimulus extends ConsumerStatefulWidget {
  const _DialogStimulus({required this.ujianId, required this.subtesId, this.lama});

  final String ujianId;
  final String subtesId;
  final Stimulus? lama;

  @override
  ConsumerState<_DialogStimulus> createState() => _DialogStimulusState();
}

class _DialogStimulusState extends ConsumerState<_DialogStimulus> {
  late final _judul = TextEditingController(text: widget.lama?.judul ?? '');
  late final _teks = TextEditingController(text: widget.lama?.teks ?? '');
  bool _sibuk = false;

  @override
  void dispose() {
    _judul.dispose();
    _teks.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_judul.text.trim().isEmpty || _teks.text.trim().isEmpty) {
      tampilkanPesan(context, 'Judul dan isi bacaan wajib diisi.', galat: true);
      return;
    }
    setState(() => _sibuk = true);
    try {
      final id = await ref
          .read(repoProvider)
          .simpanStimulus(
            widget.ujianId,
            Stimulus(id: widget.lama?.id ?? '', subtesId: widget.subtesId, judul: _judul.text.trim(), teks: _teks.text.trim()),
          );
      if (mounted) Navigator.pop(context, id);
    } catch (e) {
      if (mounted) {
        setState(() => _sibuk = false);
        tampilkanPesan(context, 'Gagal menyimpan bacaan: $e', galat: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.lama == null ? 'Tambah bacaan' : 'Ubah bacaan'),
    content: SizedBox(
      width: 720,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Bacaan, tabel, atau grafik yang dipakai beberapa soal sekaligus, seperti soal literasi UTBK. '
              'Peserta melihatnya di samping soal.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _judul,
              decoration: const InputDecoration(labelText: 'Judul (untuk peserta dan admin)', hintText: 'Contoh: Teks 1 - Sampah Plastik'),
            ),
            const SizedBox(height: 12),
            EditorKonten(controller: _teks, label: 'Isi bacaan', ujianId: widget.ujianId, minBaris: 8),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(onPressed: _sibuk ? null : () => Navigator.pop(context), child: const Text('Batal')),
      FilledButton(onPressed: _sibuk ? null : _simpan, child: const Text('Simpan')),
    ],
  );
}
