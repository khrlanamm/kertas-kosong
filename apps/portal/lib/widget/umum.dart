import 'package:material_ui/material_ui.dart';

import '../tema.dart';

/// Lebar konten maksimum supaya nyaman dibaca di layar lebar.
class Lebar extends StatelessWidget {
  const Lebar({super.key, required this.child, this.maks = 960, this.padding = const EdgeInsets.all(20)});

  final Widget child;
  final double maks;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maks),
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Memuat extends StatelessWidget {
  const Memuat({super.key, this.pesan});

  final String? pesan;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        if (pesan != null) ...[const SizedBox(height: 16), Text(pesan!)],
      ],
    ),
  );
}

class PesanGalat extends StatelessWidget {
  const PesanGalat(this.pesan, {super.key, this.ulangi});

  final String pesan;
  final VoidCallback? ulangi;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Warna.salah),
          const SizedBox(height: 12),
          Text(pesan, textAlign: TextAlign.center),
          if (ulangi != null) ...[const SizedBox(height: 16), OutlinedButton(onPressed: ulangi, child: const Text('Coba lagi'))],
        ],
      ),
    ),
  );
}

class Kosong extends StatelessWidget {
  const Kosong({super.key, required this.ikon, required this.judul, this.pesan, this.aksi});

  final IconData ikon;
  final String judul;
  final String? pesan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(ikon, size: 40, color: Warna.tinta),
          const SizedBox(height: 12),
          Text(judul, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          if (pesan != null) ...[const SizedBox(height: 6), Text(pesan!, textAlign: TextAlign.center)],
          if (aksi != null) ...[const SizedBox(height: 16), aksi!],
        ],
      ),
    ),
  );
}

class Label extends StatelessWidget {
  const Label(this.teks, {super.key, this.warna = Warna.tinta, this.latar});

  final String teks;
  final Color warna;
  final Color? latar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: latar ?? warna.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
    child: Text(
      teks,
      style: TextStyle(color: warna, fontWeight: FontWeight.w600, fontSize: 12),
    ),
  );
}

void tampilkanPesan(BuildContext context, String pesan, {bool galat = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(pesan), backgroundColor: galat ? Warna.salah : null, behavior: SnackBarBehavior.floating));
}

Future<bool> konfirmasi(BuildContext context, {required String judul, required String isi, String ya = 'Ya', bool bahaya = false}) async {
  final hasil = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(judul),
      content: Text(isi),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
        FilledButton(
          style: bahaya ? FilledButton.styleFrom(backgroundColor: Warna.salah) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(ya),
        ),
      ],
    ),
  );
  return hasil ?? false;
}
