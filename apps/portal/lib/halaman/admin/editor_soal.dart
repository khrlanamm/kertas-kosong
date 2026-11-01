import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../util/template.dart';
import '../../widget/editor_konten.dart';
import '../../widget/jawaban.dart';
import '../../widget/konten.dart';
import '../../widget/umum.dart';
import 'dialog_stimulus.dart';

/// Tambah atau ubah satu soal. [soalId] "baru" untuk soal baru.
class HalamanEditorSoal extends ConsumerStatefulWidget {
  const HalamanEditorSoal({super.key, required this.ujianId, required this.soalId, this.subtesId});

  final String ujianId;
  final String soalId;
  final String? subtesId;

  @override
  ConsumerState<HalamanEditorSoal> createState() => _HalamanEditorSoalState();
}

class _BarisTeks {
  _BarisTeks(this.id, String teks) : c = TextEditingController(text: teks);

  final String id;
  final TextEditingController c;
}

class _HalamanEditorSoalState extends ConsumerState<HalamanEditorSoal> {
  bool _siap = false;
  bool _sibuk = false;
  bool _berubah = false;
  String? _galat;

  late String _subtesId;
  int _urutan = 0;
  TipeSoal _tipe = TipeSoal.pg;
  String? _stimulusId;
  final _teks = TextEditingController();
  final _pembahasan = TextEditingController();
  final List<_BarisTeks> _opsi = [];
  final List<_BarisTeks> _pernyataan = [];
  List<String> _labelBs = const ['Benar', 'Salah'];
  String? _kunciPg;
  final Set<String> _kunciPgk = {};
  final Map<String, bool> _kunciBs = {};
  final _isian = TextEditingController();
  bool _isianAngka = true;
  final _toleransi = TextEditingController(text: '0');

  bool get _baru => widget.soalId == 'baru';

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    for (final c in [_teks, _pembahasan, _isian, _toleransi, ..._opsi.map((o) => o.c), ..._pernyataan.map((p) => p.c)]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _muat() async {
    try {
      if (_baru) {
        _subtesId = widget.subtesId ?? '';
        final semua = await ref.read(repoProvider).pantauSoal(widget.ujianId).first;
        final di = semua.where((s) => s.subtesId == _subtesId);
        _urutan = di.isEmpty ? 1 : di.map((s) => s.urutan).reduce((a, b) => a > b ? a : b) + 1;
        for (var i = 0; i < 5; i++) {
          _opsi.add(_BarisTeks(String.fromCharCode(97 + i), ''));
        }
        _pernyataan.addAll([_BarisTeks(idAcak('p'), ''), _BarisTeks(idAcak('p'), ''), _BarisTeks(idAcak('p'), '')]);
      } else {
        final s = await ref.read(repoProvider).ambilSoal(widget.ujianId, widget.soalId);
        if (s == null) {
          setState(() => _galat = 'Soal tidak ditemukan.');
          return;
        }
        _subtesId = s.subtesId;
        _urutan = s.urutan;
        _tipe = s.tipe;
        _stimulusId = s.stimulusId;
        _teks.text = s.teks;
        _pembahasan.text = s.pembahasan;
        _opsi.addAll(s.opsi.map((o) => _BarisTeks(o.id, o.teks)));
        if (_opsi.isEmpty) {
          for (var i = 0; i < 5; i++) {
            _opsi.add(_BarisTeks(String.fromCharCode(97 + i), ''));
          }
        }
        _pernyataan.addAll(s.pernyataan.map((p) => _BarisTeks(p.id, p.teks)));
        if (_pernyataan.isEmpty) _pernyataan.addAll([_BarisTeks(idAcak('p'), ''), _BarisTeks(idAcak('p'), '')]);
        _labelBs = s.labelBs;
        _kunciPg = s.kunciPg;
        _kunciPgk.addAll(s.kunciPgk);
        _kunciBs.addAll(s.kunciBs);
        _isian.text = s.kunciIsian.jawaban.join('\n');
        _isianAngka = s.tipe == TipeSoal.isian ? s.kunciIsian.numerik : true;
        _toleransi.text = s.kunciIsian.toleransi == 0 ? '0' : s.kunciIsian.toleransi.toString().replaceAll('.', ',');
      }
      setState(() => _siap = true);
    } catch (e) {
      setState(() => _galat = 'Gagal memuat soal: $e');
    }
  }

  /// Dipanggil setiap kali isian berubah, supaya pratinjau ikut diperbarui.
  void _tandai() => setState(() => _berubah = true);

  Soal _bentukSoal() => Soal(
    id: _baru ? '' : widget.soalId,
    subtesId: _subtesId,
    urutan: _urutan,
    tipe: _tipe,
    stimulusId: _stimulusId,
    teks: _teks.text.trim(),
    opsi: _opsi.map((o) => Opsi(o.id, o.c.text.trim())).toList(),
    pernyataan: _pernyataan.map((p) => Opsi(p.id, p.c.text.trim())).toList(),
    labelBs: _labelBs,
    kunciPg: _kunciPg,
    kunciPgk: _opsi.map((o) => o.id).where(_kunciPgk.contains).toList(),
    kunciBs: {
      for (final p in _pernyataan)
        if (_kunciBs.containsKey(p.id)) p.id: _kunciBs[p.id]!,
    },
    kunciIsian: KunciIsian(
      jawaban: _isian.text.split('\n').map((j) => j.trim()).where((j) => j.isNotEmpty).toList(),
      numerik: _isianAngka,
      toleransi: double.tryParse(_toleransi.text.trim().replaceAll(',', '.'))?.abs() ?? 0,
    ),
    pembahasan: _pembahasan.text.trim(),
  );

  Future<void> _simpan({bool lanjut = false}) async {
    final soal = _bentukSoal();
    final masalah = soal.periksa();
    if (masalah != null) {
      tampilkanPesan(context, masalah, galat: true);
      return;
    }
    setState(() => _sibuk = true);
    try {
      await ref.read(repoProvider).simpanSoal(widget.ujianId, soal);
      if (!mounted) return;
      tampilkanPesan(context, 'Soal tersimpan.');
      if (lanjut) {
        context.go('/admin/ujian/${widget.ujianId}/soal/baru?subtes=$_subtesId&n=${DateTime.now().millisecondsSinceEpoch}');
      } else {
        context.go('/admin/ujian/${widget.ujianId}?tab=soal&subtes=$_subtesId');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _sibuk = false);
        tampilkanPesan(context, 'Gagal menyimpan: $e', galat: true);
      }
    }
  }

  Future<void> _kembali() async {
    if (_berubah) {
      final ya = await konfirmasi(
        context,
        judul: 'Buang perubahan?',
        isi: 'Perubahan pada soal ini belum disimpan.',
        ya: 'Buang',
        bahaya: true,
      );
      if (!ya || !mounted) return;
    }
    context.go('/admin/ujian/${widget.ujianId}?tab=soal&subtes=$_subtesId');
  }

  @override
  Widget build(BuildContext context) {
    if (_galat != null) return Scaffold(appBar: AppBar(), body: PesanGalat(_galat!));
    if (!_siap) return const Scaffold(body: Memuat());

    final ujian = ref.watch(ujianProvider(widget.ujianId)).value;
    final stimulus = (ref.watch(stimulusProvider(widget.ujianId)).value ?? const <Stimulus>[])
        .where((s) => s.subtesId == _subtesId)
        .toList();
    final subtes = ujian?.subtes.where((s) => s.id == _subtesId).firstOrNull;
    final lebar = MediaQuery.sizeOf(context).width >= 1200;

    final form = _formulir(context, stimulus);
    final pratinjau = _Pratinjau(soal: _bentukSoal(), stimulus: stimulus.where((s) => s.id == _stimulusId).firstOrNull);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: _kembali),
        title: Text(
          '${_baru ? 'Soal baru' : 'Ubah soal'}${subtes == null ? '' : ' · ${subtes.singkatan.isEmpty ? subtes.nama : subtes.singkatan}'}',
        ),
        actions: [
          if (_baru) TextButton(onPressed: _sibuk ? null : () => _simpan(lanjut: true), child: const Text('Simpan & tambah lagi')),
          const SizedBox(width: 8),
          FilledButton(onPressed: _sibuk ? null : _simpan, child: const Text('Simpan')),
          const SizedBox(width: 16),
        ],
      ),
      body: lebar
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ListView(padding: const EdgeInsets.all(20), children: [form]),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 480,
                  child: ListView(padding: const EdgeInsets.all(20), children: [pratinjau]),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [form, const SizedBox(height: 24), pratinjau, const SizedBox(height: 40)],
            ),
    );
  }

  Widget _formulir(BuildContext context, List<Stimulus> stimulus) {
    final tema = Theme.of(context);
    final judulBagian = tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Tipe soal', style: judulBagian),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in TipeSoal.values)
              ChoiceChip(
                label: Text(t.label),
                selected: _tipe == t,
                onSelected: (_) => setState(() {
                  _tipe = t;
                  _berubah = true;
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(_keteranganTipe(_tipe), style: tema.textTheme.bodySmall),
        const SizedBox(height: 20),
        Text('Bacaan / stimulus (opsional)', style: judulBagian),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                initialValue: stimulus.any((s) => s.id == _stimulusId) ? _stimulusId : null,
                decoration: const InputDecoration(labelText: 'Bacaan yang dipakai soal ini'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Tanpa bacaan')),
                  for (final s in stimulus)
                    DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.judul, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (v) => setState(() {
                  _stimulusId = v;
                  _berubah = true;
                }),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Bacaan baru',
              icon: const Icon(Icons.add),
              onPressed: () async {
                final id = await bukaDialogStimulus(context, ref, ujianId: widget.ujianId, subtesId: _subtesId);
                if (id != null) {
                  setState(() {
                    _stimulusId = id;
                    _berubah = true;
                  });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        EditorKonten(controller: _teks, label: 'Pertanyaan', ujianId: widget.ujianId, minBaris: 4, onChanged: _tandai),
        const SizedBox(height: 20),
        ..._bagianJawaban(context, judulBagian),
        const SizedBox(height: 20),
        EditorKonten(
          controller: _pembahasan,
          label: 'Pembahasan (dibuka setelah tryout ditutup)',
          ujianId: widget.ujianId,
          minBaris: 3,
          onChanged: _tandai,
        ),
      ],
    );
  }

  String _keteranganTipe(TipeSoal t) => switch (t) {
    TipeSoal.pg => 'Lima pilihan A-E dengan satu jawaban benar. Bentuk paling umum di UTBK.',
    TipeSoal.pgk => 'Peserta mencentang semua pilihan yang benar. Dinilai benar hanya jika semua pilihannya tepat.',
    TipeSoal.bs =>
      'Bentuk tabel pilihan majemuk kompleks UTBK: setiap pernyataan dijawab dengan salah satu dari dua kolom. '
          'Dinilai benar hanya jika semua baris tepat.',
    TipeSoal.isian => 'Jawaban singkat berupa angka, kata, atau frasa, biasanya di PK dan Penalaran Matematika.',
  };

  List<Widget> _bagianJawaban(BuildContext context, TextStyle? judulBagian) {
    switch (_tipe) {
      case TipeSoal.pg:
      case TipeSoal.pgk:
        final jamak = _tipe == TipeSoal.pgk;
        return [
          Text(jamak ? 'Pilihan jawaban (centang semua yang benar)' : 'Pilihan jawaban (pilih satu kunci)', style: judulBagian),
          const SizedBox(height: 8),
          for (var i = 0; i < _opsi.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: jamak
                        ? Checkbox(
                            value: _kunciPgk.contains(_opsi[i].id),
                            onChanged: (v) => setState(() {
                              v == true ? _kunciPgk.add(_opsi[i].id) : _kunciPgk.remove(_opsi[i].id);
                              _berubah = true;
                            }),
                          )
                        : IconButton(
                            tooltip: 'Jadikan kunci',
                            icon: Icon(
                              _kunciPg == _opsi[i].id ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: _kunciPg == _opsi[i].id ? Warna.benar : null,
                            ),
                            onPressed: () => setState(() {
                              _kunciPg = _opsi[i].id;
                              _berubah = true;
                            }),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18, right: 8),
                    child: Text(hurufOpsi(i), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: EditorKonten(
                      controller: _opsi[i].c,
                      label: 'Pilihan ${hurufOpsi(i)}',
                      ujianId: widget.ujianId,
                      minBaris: 1,
                      ringkas: true,
                      onChanged: _tandai,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus pilihan',
                    icon: const Icon(Icons.close),
                    onPressed: _opsi.length <= 2
                        ? null
                        : () => setState(() {
                            final o = _opsi.removeAt(i);
                            _kunciPgk.remove(o.id);
                            if (_kunciPg == o.id) _kunciPg = null;
                            _berubah = true;
                          }),
                  ),
                ],
              ),
            ),
          if (_opsi.length < 8)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _opsi.add(_BarisTeks(idAcak('o'), ''));
                  _berubah = true;
                }),
                icon: const Icon(Icons.add),
                label: const Text('Tambah pilihan'),
              ),
            ),
        ];
      case TipeSoal.bs:
        return [
          Text('Pernyataan dan kunci', style: judulBagian),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _labelBs.join('|'),
            decoration: const InputDecoration(labelText: 'Label kolom'),
            items: [
              for (final l in {...pilihanLabelBs.map((p) => p.join('|')), _labelBs.join('|')})
                DropdownMenuItem(value: l, child: Text(l.replaceAll('|', ' / '))),
            ],
            onChanged: (v) => setState(() {
              _labelBs = v!.split('|');
              _berubah = true;
            }),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _pernyataan.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18, right: 8),
                    child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: EditorKonten(
                      controller: _pernyataan[i].c,
                      label: 'Pernyataan ${i + 1}',
                      ujianId: widget.ujianId,
                      minBaris: 1,
                      ringkas: true,
                      onChanged: _tandai,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: SegmentedButton<bool>(
                      emptySelectionAllowed: true,
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(value: true, label: Text(_labelBs[0])),
                        ButtonSegment(value: false, label: Text(_labelBs[1])),
                      ],
                      selected: {if (_kunciBs.containsKey(_pernyataan[i].id)) _kunciBs[_pernyataan[i].id]!},
                      onSelectionChanged: (v) => setState(() {
                        v.isEmpty ? _kunciBs.remove(_pernyataan[i].id) : _kunciBs[_pernyataan[i].id] = v.first;
                        _berubah = true;
                      }),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus pernyataan',
                    icon: const Icon(Icons.close),
                    onPressed: _pernyataan.length <= 1
                        ? null
                        : () => setState(() {
                            final p = _pernyataan.removeAt(i);
                            _kunciBs.remove(p.id);
                            _berubah = true;
                          }),
                  ),
                ],
              ),
            ),
          if (_pernyataan.length < 8)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _pernyataan.add(_BarisTeks(idAcak('p'), ''));
                  _berubah = true;
                }),
                icon: const Icon(Icons.add),
                label: const Text('Tambah pernyataan'),
              ),
            ),
        ];
      case TipeSoal.isian:
        return [
          Text('Kunci jawaban isian', style: judulBagian),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Jawaban berupa angka'),
            subtitle: const Text('Dinilai sebagai bilangan: "2,5", "2.5", dan "5/2" dianggap sama.'),
            value: _isianAngka,
            onChanged: (v) => setState(() {
              _isianAngka = v;
              _berubah = true;
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _isian,
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: 'Jawaban yang diterima (satu per baris)',
              hintText: _isianAngka ? '12\n12,0' : 'fotosintesis\nfoto sintesis',
              alignLabelWithHint: true,
              helperText: _isianAngka ? null : 'Tidak membedakan huruf besar/kecil dan spasi berlebih.',
            ),
            onChanged: (_) => _tandai(),
          ),
          if (_isianAngka) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: 220,
              child: TextField(
                controller: _toleransi,
                decoration: const InputDecoration(labelText: 'Toleransi (±)', helperText: 'Isi 0 jika harus persis.'),
                onChanged: (_) => _tandai(),
              ),
            ),
          ],
        ];
    }
  }
}

class _Pratinjau extends StatelessWidget {
  const _Pratinjau({required this.soal, required this.stimulus});

  final Soal soal;
  final Stimulus? stimulus;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final peserta = soalUntukPratinjau(soal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Pratinjau (seperti dilihat peserta, dengan kunci)', style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (stimulus != null)
          Card(
            child: ExpansionTile(
              shape: const Border(),
              title: Text(stimulus!.judul),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [Konten(stimulus!.teks)],
            ),
          ),
        if (stimulus != null) const SizedBox(height: 12),
        Text(
          soal.tipe.petunjuk,
          style: tema.textTheme.bodySmall?.copyWith(color: Warna.tinta, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        soal.teks.isEmpty ? const Text('(pertanyaan masih kosong)') : Konten(soal.teks),
        const SizedBox(height: 16),
        InputJawaban(soal: peserta, jawaban: null, kunci: soal.kunci),
        if (soal.pembahasan.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Pembahasan', style: tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Konten(soal.pembahasan),
        ],
      ],
    );
  }
}
