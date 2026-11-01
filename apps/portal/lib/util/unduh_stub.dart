/// Unduh berkas teks. Belum didukung di luar web.
Future<void> unduhTeks(String namaBerkas, String isi, {String mime = 'text/plain'}) async {
  throw UnsupportedError('Unduh berkas hanya tersedia di versi web.');
}
