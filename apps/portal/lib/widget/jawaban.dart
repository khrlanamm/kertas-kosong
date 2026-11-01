import 'package:material_ui/material_ui.dart';

import '../data/model.dart';
import '../tema.dart';
import '../util/template.dart';
import 'konten.dart';

/// Ubah soal versi admin menjadi tampilan peserta (untuk pratinjau).
SoalPeserta soalUntukPratinjau(Soal s) => SoalPeserta(
  id: s.id,
  tipe: s.tipe,
  teks: s.teks,
  stimulusId: s.stimulusId,
  opsi: s.opsi,
  pernyataan: s.pernyataan,
  labelBs: s.labelBs,
  isianAngka: s.kunciIsian.numerik,
);

/// Input jawaban untuk semua tipe soal.
///
/// Jika [onUbah] null, tampil hanya-baca. Jika [kunci] diisi, jawaban benar dan salah ditandai
/// (dipakai di pembahasan dan pratinjau admin).
class InputJawaban extends StatelessWidget {
  const InputJawaban({super.key, required this.soal, required this.jawaban, this.onUbah, this.kunci});

  final SoalPeserta soal;
  final Object? jawaban;
  final ValueChanged<Object?>? onUbah;
  final Object? kunci;

  @override
  Widget build(BuildContext context) => switch (soal.tipe) {
    TipeSoal.pg || TipeSoal.pgk => _Pilihan(soal: soal, jawaban: jawaban, onUbah: onUbah, kunci: kunci),
    TipeSoal.bs => _TabelBs(soal: soal, jawaban: jawaban, onUbah: onUbah, kunci: kunci),
    TipeSoal.isian => _Isian(key: ValueKey('isian-${soal.id}'), soal: soal, jawaban: jawaban, onUbah: onUbah, kunci: kunci),
  };
}

class _Pilihan extends StatelessWidget {
  const _Pilihan({required this.soal, required this.jawaban, required this.onUbah, required this.kunci});

  final SoalPeserta soal;
  final Object? jawaban;
  final ValueChanged<Object?>? onUbah;
  final Object? kunci;

  bool get _jamak => soal.tipe == TipeSoal.pgk;

  Set<String> get _dipilih => switch (jawaban) {
    final String s => {s},
    final List l => l.map((e) => '$e').toSet(),
    _ => <String>{},
  };

  Set<String>? get _benar => switch (kunci) {
    final String s => {s},
    final List l => l.map((e) => '$e').toSet(),
    _ => null,
  };

  void _pilih(String id) {
    final ubah = onUbah;
    if (ubah == null) return;
    if (_jamak) {
      final baru = {..._dipilih};
      baru.contains(id) ? baru.remove(id) : baru.add(id);
      ubah(baru.isEmpty ? null : (baru.toList()..sort()));
    } else {
      ubah(_dipilih.contains(id) ? null : id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dipilih = _dipilih;
    final benar = _benar;
    return Column(
      children: [
        for (var i = 0; i < soal.opsi.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _KartuOpsi(
              huruf: hurufOpsi(i),
              teks: soal.opsi[i].teks,
              dipilih: dipilih.contains(soal.opsi[i].id),
              jamak: _jamak,
              status: benar == null
                  ? null
                  : benar.contains(soal.opsi[i].id)
                  ? true
                  : (dipilih.contains(soal.opsi[i].id) ? false : null),
              onTap: onUbah == null ? null : () => _pilih(soal.opsi[i].id),
            ),
          ),
      ],
    );
  }
}

class _KartuOpsi extends StatelessWidget {
  const _KartuOpsi({required this.huruf, required this.teks, required this.dipilih, required this.jamak, this.status, this.onTap});

  final String huruf;
  final String teks;
  final bool dipilih;
  final bool jamak;

  /// true = kunci jawaban, false = dipilih tetapi salah, null = biasa.
  final bool? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final warnaTepi = switch (status) {
      true => Warna.benar,
      false => Warna.salah,
      null => dipilih ? Warna.tinta : Warna.tintaMuda,
    };
    return Semantics(
      button: true,
      selected: dipilih,
      label: 'Pilihan $huruf',
      child: Material(
        color: dipilih ? Warna.tintaMuda.withValues(alpha: 0.6) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: warnaTepi, width: dipilih || status != null ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: dipilih ? Warna.tinta : Colors.white,
                    shape: jamak ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: jamak ? BorderRadius.circular(8) : null,
                    border: Border.all(color: dipilih ? Warna.tinta : Colors.black26),
                  ),
                  child: jamak && dipilih
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                          huruf,
                          style: TextStyle(fontWeight: FontWeight.w700, color: dipilih ? Colors.white : Warna.tintaTua),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Padding(padding: const EdgeInsets.only(top: 4), child: Konten(teks)),
                ),
                if (status != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Icon(status! ? Icons.check_circle : Icons.cancel, color: status! ? Warna.benar : Warna.salah),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabelBs extends StatelessWidget {
  const _TabelBs({required this.soal, required this.jawaban, required this.onUbah, required this.kunci});

  final SoalPeserta soal;
  final Object? jawaban;
  final ValueChanged<Object?>? onUbah;
  final Object? kunci;

  Map<String, bool> get _isi => jawaban is Map ? (jawaban as Map).map((k, v) => MapEntry('$k', v == true)) : {};
  Map<String, bool>? get _kunci => kunci is Map ? (kunci as Map).map((k, v) => MapEntry('$k', v == true)) : null;

  @override
  Widget build(BuildContext context) {
    final isi = _isi;
    final kunciBs = _kunci;
    final tema = Theme.of(context);
    final kolom = MediaQuery.sizeOf(context).width < 520 ? 76.0 : 104.0;
    return Card(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Warna.tintaMuda,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(child: Text('Pernyataan', style: tema.textTheme.labelLarge)),
                for (final l in soal.labelBs)
                  SizedBox(
                    width: kolom,
                    child: Text(l, textAlign: TextAlign.center, style: tema.textTheme.labelLarge),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < soal.pernyataan.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Konten(soal.pernyataan[i].teks)),
                  for (final nilai in [true, false])
                    SizedBox(
                      width: kolom,
                      child: Center(
                        child: _PilihBs(
                          label: '${soal.labelBs[nilai ? 0 : 1]} untuk pernyataan ${i + 1}',
                          dipilih: isi[soal.pernyataan[i].id] == nilai,
                          kunci: kunciBs == null ? null : kunciBs[soal.pernyataan[i].id] == nilai,
                          onTap: onUbah == null
                              ? null
                              : () {
                                  final baru = {...isi};
                                  final id = soal.pernyataan[i].id;
                                  if (baru[id] == nilai) {
                                    baru.remove(id);
                                  } else {
                                    baru[id] = nilai;
                                  }
                                  onUbah!(baru.isEmpty ? null : baru);
                                },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PilihBs extends StatelessWidget {
  const _PilihBs({required this.label, required this.dipilih, this.kunci, this.onTap});

  final String label;
  final bool dipilih;

  /// true jika kolom ini kunci jawabannya (mode pembahasan).
  final bool? kunci;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tepi = kunci == true ? Warna.benar : (dipilih ? Warna.tinta : Colors.black26);
    return Semantics(
      button: true,
      selected: dipilih,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dipilih ? (kunci == false ? Warna.salah : Warna.tinta) : Colors.white,
            border: Border.all(color: tepi, width: kunci == true ? 3 : 2),
          ),
          child: dipilih ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
        ),
      ),
    );
  }
}

class _Isian extends StatefulWidget {
  const _Isian({super.key, required this.soal, required this.jawaban, required this.onUbah, required this.kunci});

  final SoalPeserta soal;
  final Object? jawaban;
  final ValueChanged<Object?>? onUbah;
  final Object? kunci;

  @override
  State<_Isian> createState() => _IsianState();
}

class _IsianState extends State<_Isian> {
  late final _c = TextEditingController(text: widget.jawaban is String ? widget.jawaban as String : '');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kunci = widget.kunci is Map ? KunciIsian.dariMap(widget.kunci) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 360,
          child: TextField(
            controller: _c,
            readOnly: widget.onUbah == null,
            maxLength: 100,
            keyboardType: widget.soal.isianAngka ? const TextInputType.numberWithOptions(decimal: true, signed: true) : TextInputType.text,
            decoration: InputDecoration(
              labelText: 'Jawaban',
              hintText: widget.soal.isianAngka ? 'Contoh: 12, 2,5, atau 3/4' : 'Ketik jawaban singkat',
              counterText: '',
            ),
            onChanged: (v) => widget.onUbah?.call(v.trim().isEmpty ? null : v),
          ),
        ),
        if (kunci != null) ...[
          const SizedBox(height: 10),
          Text(
            'Jawaban yang diterima: ${kunci.jawaban.join(' / ')}${kunci.numerik && kunci.toleransi > 0 ? ' (toleransi ±${kunci.toleransi})' : ''}',
            style: const TextStyle(color: Warna.benar, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
