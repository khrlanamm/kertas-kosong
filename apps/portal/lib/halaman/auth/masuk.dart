import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../layanan/auth.dart';
import '../../tema.dart';
import '../../widget/umum.dart';

class HalamanMasuk extends ConsumerStatefulWidget {
  const HalamanMasuk({super.key});

  @override
  ConsumerState<HalamanMasuk> createState() => _HalamanMasukState();
}

class _HalamanMasukState extends ConsumerState<HalamanMasuk> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _sandi = TextEditingController();
  bool _daftar = false;
  bool _sibuk = false;
  bool _sandiTerlihat = false;
  String? _galat;

  @override
  void dispose() {
    _email.dispose();
    _sandi.dispose();
    super.dispose();
  }

  Future<void> _jalankan(Future<void> Function() aksi) async {
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await aksi();
    } catch (e) {
      if (mounted) setState(() => _galat = pesanGalatAuth(e));
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  Future<void> _kirimEmail() async {
    if (!_form.currentState!.validate()) return;
    final auth = ref.read(layananAuthProvider);
    await _jalankan(() => _daftar ? auth.daftarEmail(_email.text, _sandi.text) : auth.masukEmail(_email.text, _sandi.text));
  }

  Future<void> _lupaSandi() async {
    if (_email.text.trim().isEmpty || !_email.text.contains('@')) {
      setState(() => _galat = 'Isi email kamu dulu, lalu tekan "Lupa kata sandi" lagi.');
      return;
    }
    await _jalankan(() async {
      await ref.read(layananAuthProvider).aturUlangSandi(_email.text);
      if (mounted) tampilkanPesan(context, 'Tautan untuk mengatur ulang kata sandi sudah dikirim ke ${_email.text.trim()}.');
    });
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/logo.png', height: 72),
                  const SizedBox(height: 24),
                  Text(
                    'Portal Bimbel Ayo Kuliah',
                    textAlign: TextAlign.center,
                    style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text('Masuk untuk mengikuti tryout dan kegiatan bimbel.', textAlign: TextAlign.center, style: tema.textTheme.bodyMedium),
                  const SizedBox(height: 28),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _sibuk ? null : () => _jalankan(ref.read(layananAuthProvider).masukGoogle),
                              icon: const Text(
                                'G',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Warna.tinta),
                              ),
                              label: const Text('Masuk dengan Google'),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('atau dengan email')),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(labelText: 'Email'),
                              validator: (v) => (v == null || !v.contains('@')) ? 'Masukkan email yang valid.' : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _sandi,
                              obscureText: !_sandiTerlihat,
                              autofillHints: [_daftar ? AutofillHints.newPassword : AutofillHints.password],
                              decoration: InputDecoration(
                                labelText: 'Kata sandi',
                                suffixIcon: IconButton(
                                  tooltip: _sandiTerlihat ? 'Sembunyikan' : 'Tampilkan',
                                  icon: Icon(_sandiTerlihat ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _sandiTerlihat = !_sandiTerlihat),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < (_daftar ? 8 : 1))
                                  ? (_daftar ? 'Kata sandi minimal 8 karakter.' : 'Masukkan kata sandi.')
                                  : null,
                              onFieldSubmitted: (_) => _kirimEmail(),
                            ),
                            if (_galat != null) ...[const SizedBox(height: 12), Text(_galat!, style: const TextStyle(color: Warna.salah))],
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: _sibuk ? null : _kirimEmail,
                              child: _sibuk
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Text(_daftar ? 'Daftar' : 'Masuk'),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: _sibuk ? null : () => setState(() => _daftar = !_daftar),
                                  child: Text(_daftar ? 'Sudah punya akun? Masuk' : 'Belum punya akun? Daftar'),
                                ),
                                if (!_daftar) TextButton(onPressed: _sibuk ? null : _lupaSandi, child: const Text('Lupa kata sandi')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
