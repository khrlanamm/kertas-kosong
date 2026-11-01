import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';

import '../data/model.dart';
import '../tema.dart';
import 'form_profil.dart';

/// Formulir pendaftaran seminar atau bimbel.
///
/// Diisi otomatis dari profil (atau pendaftaran sebelumnya), sehingga siswa yang sudah mendaftar
/// seminar tidak perlu mengetik ulang saat mendaftar bimbel.
class FormPendaftaran extends ConsumerStatefulWidget {
  const FormPendaftaran({
    super.key,
    required this.jenis,
    required this.awal,
    required this.email,
    required this.tombol,
    required this.sibuk,
    required this.onKirim,
  });

  final JenisProgram jenis;
  final Pengguna awal;
  final String email;
  final String tombol;
  final bool sibuk;
  final Future<void> Function(Map<String, Object?> data) onKirim;

  @override
  ConsumerState<FormPendaftaran> createState() => _FormPendaftaranState();
}

class _BarisMinat {
  _BarisMinat(Minat m) : jurusan = TextEditingController(text: m.jurusan), kampus = TextEditingController(text: m.kampus);

  final TextEditingController jurusan;
  final TextEditingController kampus;
}

class _FormPendaftaranState extends ConsumerState<FormPendaftaran> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.awal.nama);
  late final _sekolah = TextEditingController(text: widget.awal.sekolah);
  late final _kota = TextEditingController(text: widget.awal.kota);
  late final _noHp = TextEditingController(text: widget.awal.noHp);
  late final _alamat = TextEditingController(text: widget.awal.alamat);
  late final _nomorSnbp = TextEditingController(text: widget.awal.nomorSnbp);
  late String? _kelas = widget.awal.kelas.isEmpty ? null : widget.awal.kelas;
  late String? _tanggalLahir = widget.awal.tanggalLahir.isEmpty ? null : widget.awal.tanggalLahir;
  late String? _eligible = widget.awal.eligibleSnbp.isEmpty ? null : widget.awal.eligibleSnbp;
  late final List<_BarisMinat> _minat = [
    for (final m in widget.awal.minat.take(3)) _BarisMinat(m),
    if (widget.awal.minat.isEmpty) _BarisMinat(const Minat('', '')),
  ];

  bool get _bimbel => widget.jenis == JenisProgram.bimbel;

  @override
  void dispose() {
    for (final c in [
      _nama,
      _sekolah,
      _kota,
      _noHp,
      _alamat,
      _nomorSnbp,
      ..._minat.expand((m) => [m.jurusan, m.kampus]),
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _wajib(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label wajib diisi.' : null;

  Future<void> _pilihTanggal() async {
    final awal = DateTime.tryParse(_tanggalLahir ?? '') ?? DateTime(DateTime.now().year - 17, 1, 1);
    final t = await showDatePicker(
      context: context,
      initialDate: awal,
      firstDate: DateTime(DateTime.now().year - 30),
      lastDate: DateTime(DateTime.now().year - 12, 12, 31),
      initialEntryMode: DatePickerEntryMode.input,
      helpText: 'Tanggal lahir',
    );
    if (t != null) setState(() => _tanggalLahir = DateFormat('yyyy-MM-dd').format(t));
  }

  Future<void> _kirim() async {
    if (!_form.currentState!.validate()) return;
    await widget.onKirim({
      'nama': _nama.text.trim(),
      'sekolah': _sekolah.text.trim(),
      'kelas': _kelas ?? '',
      'kota': _kota.text.trim(),
      'noHp': _noHp.text.trim(),
      'alamat': _alamat.text.trim(),
      'minat': [
        for (final m in _minat)
          if (m.jurusan.text.trim().isNotEmpty || m.kampus.text.trim().isNotEmpty)
            {'jurusan': m.jurusan.text.trim(), 'kampus': m.kampus.text.trim()},
      ],
      if (_bimbel) ...{
        'tanggalLahir': _tanggalLahir,
        'eligibleSnbp': _eligible,
        'nomorSnbp': _eligible == 'ya' ? _nomorSnbp.text.trim() : '',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final judul = tema.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);
    final kelas = {...pilihanKelas, ?_kelas}.toList();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Data diri', style: judul),
          const SizedBox(height: 10),
          TextFormField(
            controller: _nama,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nama lengkap', counterText: ''),
            validator: (v) => _wajib(v, 'Nama'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: widget.email,
            readOnly: true,
            decoration: const InputDecoration(labelText: 'Email', helperText: 'Sesuai akun yang dipakai masuk.'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noHp,
            keyboardType: TextInputType.phone,
            maxLength: 20,
            decoration: const InputDecoration(labelText: 'Nomor HP/WhatsApp', hintText: '08xxxxxxxxxx', counterText: ''),
            validator: (v) {
              final n = (v ?? '').replaceAll(RegExp(r'[\s().-]'), '');
              return RegExp(r'^(\+62|62|0)8\d{7,12}$').hasMatch(n) ? null : 'Nomor HP tidak valid.';
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sekolah,
            maxLength: 150,
            decoration: const InputDecoration(labelText: 'Asal sekolah', hintText: 'Contoh: SMAN 1 Dukun', counterText: ''),
            validator: (v) => _wajib(v, 'Asal sekolah'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _kelas,
            decoration: const InputDecoration(labelText: 'Kelas'),
            items: [for (final k in kelas) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _kelas = v),
            validator: (v) => v == null ? 'Pilih kelas.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kota,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Kota/kabupaten', counterText: ''),
            validator: (v) => _wajib(v, 'Kota/kabupaten'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _alamat,
            minLines: 2,
            maxLines: 4,
            maxLength: 300,
            decoration: const InputDecoration(labelText: 'Alamat lengkap', alignLabelWithHint: true, counterText: ''),
            validator: (v) => (v ?? '').trim().length < 5 ? 'Alamat wajib diisi.' : null,
          ),
          const SizedBox(height: 20),
          Text('Minat jurusan dan kampus', style: judul),
          const SizedBox(height: 4),
          const Text('Isi 1-3 pilihan, urut dari yang paling diminati.'),
          const SizedBox(height: 10),
          for (var i = 0; i < _minat.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 8),
                    child: Text('${i + 1}.', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _minat[i].jurusan,
                      decoration: const InputDecoration(labelText: 'Jurusan', hintText: 'Contoh: Kedokteran'),
                      validator: (v) => i == 0 && (v ?? '').trim().isEmpty ? 'Wajib diisi.' : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minat[i].kampus,
                      decoration: const InputDecoration(labelText: 'Kampus', hintText: 'Contoh: UNAIR'),
                      validator: (v) {
                        final jurusan = _minat[i].jurusan.text.trim();
                        if (i == 0 && (v ?? '').trim().isEmpty) return 'Wajib diisi.';
                        if (jurusan.isNotEmpty && (v ?? '').trim().isEmpty) return 'Isi kampusnya.';
                        return null;
                      },
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus pilihan',
                    onPressed: _minat.length <= 1 ? null : () => setState(() => _minat.removeAt(i)),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          if (_minat.length < 3)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _minat.add(_BarisMinat(const Minat('', '')))),
                icon: const Icon(Icons.add),
                label: const Text('Tambah pilihan'),
              ),
            ),
          if (_bimbel) ...[
            const SizedBox(height: 20),
            Text('Data pelengkap bimbel', style: judul),
            const SizedBox(height: 10),
            FormField<String>(
              validator: (_) => _tanggalLahir == null ? 'Tanggal lahir wajib diisi.' : null,
              builder: (field) => Semantics(
                button: true,
                label: 'Tanggal lahir',
                child: InkWell(
                  onTap: _pilihTanggal,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Tanggal lahir',
                      helperText: 'Dipakai untuk membantu mengakses hasil UTBK nanti.',
                      errorText: field.errorText,
                      suffixIcon: const Icon(Icons.calendar_month),
                    ),
                    child: Text(
                      _tanggalLahir == null ? 'Pilih tanggal' : DateFormat('d MMMM y', 'id_ID').format(DateTime.parse(_tanggalLahir!)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FormField<String>(
              validator: (_) => _eligible == null ? 'Pilih salah satu.' : null,
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Apakah sekolahmu eligible (punya kuota) SNBP, dan kamu termasuk siswa eligible?'),
                  RadioGroup<String>(
                    groupValue: _eligible,
                    onChanged: (v) => setState(() => _eligible = v),
                    child: const Column(
                      children: [
                        RadioListTile(value: 'ya', title: Text('Ya, saya eligible SNBP'), contentPadding: EdgeInsets.zero),
                        RadioListTile(value: 'tidak', title: Text('Tidak eligible'), contentPadding: EdgeInsets.zero),
                        RadioListTile(value: 'belumTahu', title: Text('Belum tahu'), contentPadding: EdgeInsets.zero),
                      ],
                    ),
                  ),
                  if (field.hasError) Text(field.errorText!, style: const TextStyle(color: Warna.salah, fontSize: 12)),
                ],
              ),
            ),
            if (_eligible == 'ya') ...[
              const SizedBox(height: 8),
              TextFormField(
                controller: _nomorSnbp,
                maxLength: 30,
                decoration: const InputDecoration(
                  labelText: 'Nomor pendaftaran SNBP',
                  helperText: 'Nomor dari akun SNPMB saat mendaftar SNBP.',
                  counterText: '',
                ),
                validator: (v) {
                  final n = (v ?? '').replaceAll(' ', '');
                  return RegExp(r'^[0-9A-Za-z-]{5,30}$').hasMatch(n) ? null : 'Isi nomor pendaftaran SNBP.';
                },
              ),
            ],
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: widget.sibuk ? null : _kirim,
            child: widget.sibuk
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(widget.tombol),
          ),
        ],
      ),
    );
  }
}
