import 'package:material_ui/material_ui.dart';

typedef DataProfil = ({String nama, String sekolah, String kelas, String kota, String noHp});

const pilihanKelas = ['Kelas XII', 'Kelas XI', 'Kelas X', 'Alumni (lulus 1 tahun lalu)', 'Alumni (lulus 2 tahun lalu)', 'Lainnya'];

class FormProfil extends StatefulWidget {
  const FormProfil({
    super.key,
    this.nama = '',
    this.sekolah = '',
    this.kelas = '',
    this.kota = '',
    this.noHp = '',
    required this.tombol,
    required this.sibuk,
    required this.onSimpan,
    this.mintaPersetujuan = false,
    this.urlPrivasi,
  });

  final String nama;
  final String sekolah;
  final String kelas;
  final String kota;
  final String noHp;
  final String tombol;
  final bool sibuk;
  final bool mintaPersetujuan;
  final String? urlPrivasi;
  final Future<void> Function(DataProfil data) onSimpan;

  @override
  State<FormProfil> createState() => _FormProfilState();
}

class _FormProfilState extends State<FormProfil> {
  final _form = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.nama);
  late final _sekolah = TextEditingController(text: widget.sekolah);
  late final _kota = TextEditingController(text: widget.kota);
  late final _noHp = TextEditingController(text: widget.noHp);
  late String? _kelas = widget.kelas.isEmpty ? null : widget.kelas;
  bool _setuju = false;

  @override
  void dispose() {
    for (final c in [_nama, _sekolah, _kota, _noHp]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _wajib(String? v, String label) => (v == null || v.trim().isEmpty) ? '$label wajib diisi.' : null;

  Future<void> _kirim() async {
    if (!_form.currentState!.validate()) return;
    await widget.onSimpan((
      nama: _nama.text.trim(),
      sekolah: _sekolah.text.trim(),
      kelas: _kelas ?? '',
      kota: _kota.text.trim(),
      noHp: _noHp.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final kelas = {...pilihanKelas, ?_kelas}.toList();
    return Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _nama,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Nama lengkap', counterText: ''),
            validator: (v) => _wajib(v, 'Nama'),
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
            decoration: const InputDecoration(labelText: 'Kelas atau status'),
            items: [for (final k in kelas) DropdownMenuItem(value: k, child: Text(k))],
            onChanged: (v) => setState(() => _kelas = v),
            validator: (v) => v == null ? 'Pilih kelas atau status.' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _kota,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Kota/kabupaten', hintText: 'Contoh: Gresik', counterText: ''),
            validator: (v) => _wajib(v, 'Kota/kabupaten'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _noHp,
            maxLength: 20,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Nomor WhatsApp (opsional)', hintText: '08xxxxxxxxxx', counterText: ''),
            validator: (v) =>
                (v != null && v.trim().isNotEmpty && !RegExp(r'^[0-9+ -]{8,20}$').hasMatch(v.trim())) ? 'Nomor tidak valid.' : null,
          ),
          if (widget.mintaPersetujuan) ...[
            const SizedBox(height: 12),
            FormField<bool>(
              validator: (_) => _setuju ? null : 'Centang persetujuan untuk melanjutkan.',
              builder: (field) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _setuju,
                    onChanged: (v) => setState(() => _setuju = v ?? false),
                    title: Text(
                      'Saya setuju data ini digunakan Komunitas Kertas Kosong untuk keperluan bimbel, tryout, dan kegiatan komunitas.'
                      '${widget.urlPrivasi != null ? ' Kebijakan privasi: ${widget.urlPrivasi}' : ''}',
                    ),
                  ),
                  if (field.hasError) Text(field.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
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
