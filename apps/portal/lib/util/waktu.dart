import 'package:material_ui/material_ui.dart';
import 'package:intl/intl.dart';

/// Semua jadwal ditampilkan dan diisi dalam WIB (UTC+7), tanpa bergantung pada zona waktu perangkat.
const _wib = Duration(hours: 7);

DateTime keWib(DateTime t) => t.toUtc().add(_wib);

/// Gabungkan tanggal dan jam WIB menjadi waktu absolut.
DateTime dariWib(DateTime tanggal, TimeOfDay jam) =>
    DateTime.utc(tanggal.year, tanggal.month, tanggal.day, jam.hour, jam.minute).subtract(_wib);

String formatTanggalJam(DateTime t) => '${DateFormat('EEEE, d MMMM y, HH.mm', 'id_ID').format(keWib(t))} WIB';
String formatTanggal(DateTime t) => DateFormat('d MMMM y', 'id_ID').format(keWib(t));
String formatTanggalSingkat(DateTime t) => '${DateFormat('d MMM y, HH.mm', 'id_ID').format(keWib(t))} WIB';
String formatJam(DateTime t) => '${DateFormat('HH.mm', 'id_ID').format(keWib(t))} WIB';

/// Contoh: "30 menit", "42,5 menit", "1 jam 15 menit".
String formatDurasi(int detik) {
  if (detik < 3600) {
    final menit = detik / 60;
    final teks = menit == menit.roundToDouble() ? '${menit.round()}' : menit.toStringAsFixed(1).replaceAll('.', ',');
    return '$teks menit';
  }
  final jam = detik ~/ 3600;
  final sisa = detik % 3600;
  return sisa == 0 ? '$jam jam' : '$jam jam ${formatDurasi(sisa)}';
}

/// Hitung mundur, contoh "1:05:09" atau "09:59".
String formatHitungMundur(Duration d) {
  if (d.isNegative) return '00:00';
  final jam = d.inHours;
  final menit = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final detik = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return jam > 0 ? '$jam:$menit:$detik' : '$menit:$detik';
}

String formatAngka(num n, {int desimal = 0}) => NumberFormat.decimalPatternDigits(locale: 'id_ID', decimalDigits: desimal).format(n);
