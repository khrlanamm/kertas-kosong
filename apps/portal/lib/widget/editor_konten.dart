import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/providers.dart';
import '../tema.dart';
import 'konten.dart';
import 'umum.dart';

/// Kolom teks dengan dukungan Markdown, rumus LaTeX, tabel, dan gambar, lengkap dengan pratinjau.
class EditorKonten extends ConsumerStatefulWidget {
  const EditorKonten({
    super.key,
    required this.controller,
    required this.label,
    required this.ujianId,
    this.minBaris = 3,
    this.onChanged,
    this.ringkas = false,
  });

  final TextEditingController controller;
  final String label;
  final String ujianId;
  final int minBaris;
  final VoidCallback? onChanged;

  /// Untuk kolom pendek seperti pilihan jawaban: tanpa pratinjau berdampingan.
  final bool ringkas;

  @override
  ConsumerState<EditorKonten> createState() => _EditorKontenState();
}

class _EditorKontenState extends ConsumerState<EditorKonten> {
  bool _pratinjau = false;
  bool _mengunggah = false;

  void _sisipkan(String teks) {
    final c = widget.controller;
    final pilihan = c.selection.isValid ? c.selection : TextSelection.collapsed(offset: c.text.length);
    c.value = c.value.copyWith(
      text: c.text.replaceRange(pilihan.start, pilihan.end, teks),
      selection: TextSelection.collapsed(offset: pilihan.start + teks.length),
    );
    widget.onChanged?.call();
  }

  Future<void> _unggahGambar() async {
    final berkas = await FilePicker.pickFiles(type: FileType.image);
    if (berkas.isEmpty) return;
    final f = berkas.first;
    final data = await f.readAsBytes();
    if (data.length > 2 * 1024 * 1024) {
      if (mounted) tampilkanPesan(context, 'Ukuran gambar maksimal 2 MB.', galat: true);
      return;
    }
    setState(() => _mengunggah = true);
    try {
      final ext = (f.extension ?? 'png').toLowerCase();
      final mime = switch (ext) {
        '.jpg' || 'jpg' || '.jpeg' || 'jpeg' => 'image/jpeg',
        '.gif' || 'gif' => 'image/gif',
        '.webp' || 'webp' => 'image/webp',
        _ => 'image/png',
      };
      final url = await ref.read(repoProvider).unggahGambar(widget.ujianId, data, f.name, mime);
      _sisipkan('\n![gambar]($url)\n');
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal mengunggah gambar: $e', galat: true);
    } finally {
      if (mounted) setState(() => _mengunggah = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kolom = TextField(
      controller: widget.controller,
      minLines: widget.minBaris,
      maxLines: widget.ringkas ? 6 : 24,
      decoration: InputDecoration(labelText: widget.label, alignLabelWithHint: true),
      onChanged: (_) {
        widget.onChanged?.call();
        if (_pratinjau) setState(() {});
      },
    );

    final Widget alat = widget.ringkas
        ? Row(
            children: [
              IconButton(
                tooltip: 'Sisipkan gambar',
                visualDensity: VisualDensity.compact,
                icon: _mengunggah
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.image_outlined, size: 18),
                onPressed: _mengunggah ? null : _unggahGambar,
              ),
              IconButton(
                tooltip: 'Sisipkan rumus',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.functions, size: 18),
                onPressed: () => _sisipkan(r'$\frac{a}{b}$'),
              ),
            ],
          )
        : Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _Alat(ikon: Icons.image_outlined, label: _mengunggah ? 'Mengunggah...' : 'Gambar', onTap: _mengunggah ? null : _unggahGambar),
              _Alat(ikon: Icons.functions, label: 'Rumus', onTap: () => _sisipkan(r'$\frac{a}{b}$')),
              _Alat(
                ikon: Icons.table_chart_outlined,
                label: 'Tabel',
                onTap: () => _sisipkan('\n| Kolom 1 | Kolom 2 |\n|---|---|\n| isi | isi |\n'),
              ),
              _Alat(ikon: Icons.help_outline, label: 'Bantuan', onTap: () => bantuanFormat(context)),
              _Alat(
                ikon: _pratinjau ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                label: _pratinjau ? 'Tutup pratinjau' : 'Pratinjau',
                onTap: () => setState(() => _pratinjau = !_pratinjau),
              ),
            ],
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        kolom,
        if (!widget.ringkas) const SizedBox(height: 4),
        alat,
        if (_pratinjau)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Warna.tintaMuda),
            ),
            child: widget.controller.text.trim().isEmpty ? const Text('(kosong)') : Konten(widget.controller.text),
          ),
      ],
    );
  }
}

class _Alat extends StatelessWidget {
  const _Alat({required this.ikon, required this.label, this.onTap});

  final IconData ikon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onTap,
    style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 8)),
    icon: Icon(ikon, size: 18),
    label: Text(label),
  );
}

Future<void> bantuanFormat(BuildContext context) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Format teks soal'),
    content: const SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: SelectableText(
          'Tebal: **teks**\n'
          'Miring: *teks*\n'
          'Daftar: baris diawali "- " atau "1. "\n'
          'Baris baru: tekan Enter dua kali untuk paragraf baru.\n\n'
          'Rumus dalam kalimat: \$\\frac{3}{4}\$, \$x^2\$, \$\\sqrt{2}\$, \$\\pi r^2\$\n'
          'Rumus di baris sendiri: \$\$x = \\frac{-b \\pm \\sqrt{b^2-4ac}}{2a}\$\$\n'
          'Pangkat dan indeks: \$a^{n+1}\$, \$x_1\$\n'
          'Lainnya: \\times \\div \\leq \\geq \\neq \\cdot \\angle \\degree\n\n'
          'Tabel:\n'
          '| Tahun | Jumlah |\n'
          '|---|---|\n'
          '| 2024 | 120 |\n\n'
          'Gambar (grafik, diagram): tekan tombol Gambar. Ukuran maksimal 2 MB.',
        ),
      ),
    ),
    actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
  ),
);
