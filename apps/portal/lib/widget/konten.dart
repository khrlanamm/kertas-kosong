import 'package:material_ui/material_ui.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

/// Menampilkan teks soal, bacaan, atau pembahasan: Markdown, tabel, gambar, dan rumus LaTeX.
///
/// Rumus ditulis di antara tanda dolar: `$\frac{a}{b}$` untuk rumus dalam kalimat,
/// atau `$$x^2 + y^2 = r^2$$` untuk rumus di baris sendiri.
class Konten extends StatelessWidget {
  const Konten(this.teks, {super.key, this.style});

  final String teks;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final gaya = style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6);
    return GptMarkdown(
      teks,
      style: gaya,
      useDollarSignsForLatex: true,
      imageBuilder: (context, url, lebar, tinggi) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: Image.network(
            url,
            width: lebar,
            height: tinggi,
            fit: BoxFit.contain,
            // Gambar dari Firebase Storage dimuat lewat elemen <img> jika CORS belum diatur.
            webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
            errorBuilder: (context, error, stack) => const Text('[Gambar tidak dapat dimuat]'),
          ),
        ),
      ),
    );
  }
}
