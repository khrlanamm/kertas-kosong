import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../widget/form_profil.dart';
import '../../widget/umum.dart';

class HalamanProfil extends ConsumerStatefulWidget {
  const HalamanProfil({super.key});

  @override
  ConsumerState<HalamanProfil> createState() => _HalamanProfilState();
}

class _HalamanProfilState extends ConsumerState<HalamanProfil> {
  bool _sibuk = false;

  Future<void> _simpan(DataProfil d) async {
    final p = ref.read(penggunaProvider).value;
    if (p == null) return;
    setState(() => _sibuk = true);
    try {
      await ref.read(repoProvider).perbaruiProfil(p.uid, nama: d.nama, sekolah: d.sekolah, kelas: d.kelas, kota: d.kota, noHp: d.noHp);
      if (mounted) tampilkanPesan(context, 'Profil tersimpan.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan: $e', galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(penggunaProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: p == null
          ? const Memuat()
          : SingleChildScrollView(
              child: Lebar(
                maks: 560,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.mail_outline),
                      title: Text(p.email),
                      subtitle: Text(p.admin ? 'Admin' : 'Siswa'),
                    ),
                    const SizedBox(height: 12),
                    FormProfil(
                      nama: p.nama,
                      sekolah: p.sekolah,
                      kelas: p.kelas,
                      kota: p.kota,
                      noHp: p.noHp,
                      tombol: 'Simpan perubahan',
                      sibuk: _sibuk,
                      onSimpan: _simpan,
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => ref.read(layananAuthProvider).keluar(),
                      icon: const Icon(Icons.logout),
                      label: const Text('Keluar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
