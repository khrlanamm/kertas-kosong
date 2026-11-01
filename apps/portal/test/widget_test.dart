import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:portal/data/model.dart';
import 'package:portal/util/waktu.dart';
import 'package:portal/widget/jawaban.dart';

void main() {
  test('format durasi dan hitung mundur', () {
    expect(formatDurasi(1800), '30 menit');
    expect(formatDurasi(2550), '42,5 menit');
    expect(formatDurasi(5400), '1 jam 30 menit');
    expect(formatHitungMundur(const Duration(minutes: 9, seconds: 5)), '09:05');
    expect(formatHitungMundur(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
  });

  test('waktu WIB tidak bergantung zona waktu perangkat', () {
    final t = dariWib(DateTime(2027, 3, 1), const TimeOfDay(hour: 8, minute: 0));
    expect(t.toUtc(), DateTime.utc(2027, 3, 1, 1, 0));
    expect(keWib(t).hour, 8);
  });

  test('pemeriksaan kelengkapan soal', () {
    const opsi = [Opsi('a', 'Satu'), Opsi('b', 'Dua')];
    expect(const Soal(id: '', subtesId: 'pu', urutan: 1, tipe: TipeSoal.pg, teks: 'Soal', opsi: opsi).periksa(), 'Pilih kunci jawaban.');
    expect(const Soal(id: '', subtesId: 'pu', urutan: 1, tipe: TipeSoal.pg, teks: 'Soal', opsi: opsi, kunciPg: 'b').periksa(), isNull);
    expect(
      const Soal(id: '', subtesId: 'pu', urutan: 1, tipe: TipeSoal.bs, teks: 'Soal', pernyataan: [Opsi('p1', 'P')]).periksa(),
      'Tentukan kunci untuk setiap pernyataan.',
    );
    expect(
      const Soal(id: '', subtesId: 'pm', urutan: 1, tipe: TipeSoal.isian, teks: 'Soal').periksa(),
      'Isi minimal satu jawaban yang diterima.',
    );
  });

  test('status terisi untuk navigasi soal', () {
    expect(jawabanTerisi(TipeSoal.pg, 'a'), isTrue);
    expect(jawabanTerisi(TipeSoal.pgk, <String>[]), isFalse);
    expect(jawabanTerisi(TipeSoal.bs, {'p1': true}, jumlahPernyataan: 2), isFalse);
    expect(jawabanTerisi(TipeSoal.bs, {'p1': true, 'p2': false}, jumlahPernyataan: 2), isTrue);
    expect(jawabanTerisi(TipeSoal.isian, '  '), isFalse);
  });

  testWidgets('pilihan ganda kompleks bisa memilih lebih dari satu jawaban', (tester) async {
    Object? jawaban;
    const soal = SoalPeserta(id: 's1', tipe: TipeSoal.pgk, teks: 'Pilih', opsi: [Opsi('a', 'Satu'), Opsi('b', 'Dua'), Opsi('c', 'Tiga')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => InputJawaban(soal: soal, jawaban: jawaban, onUbah: (v) => setState(() => jawaban = v)),
          ),
        ),
      ),
    );
    await tester.tap(find.text('A'));
    await tester.pump();
    await tester.tap(find.text('C'));
    await tester.pump();
    expect(jawaban, ['a', 'c']);
  });
}
