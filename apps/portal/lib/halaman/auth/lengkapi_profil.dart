import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../konfigurasi.dart';
import '../../widget/form_profil.dart';
import '../../widget/umum.dart';

class HalamanLengkapiProfil extends ConsumerStatefulWidget {
  const HalamanLengkapiProfil({super.key});

  @override
  ConsumerState<HalamanLengkapiProfil> createState() => _HalamanLengkapiProfilState();
}

class _HalamanLengkapiProfilState extends ConsumerState<HalamanLengkapiProfil> {
  bool _sibuk = false;

  Future<void> _simpan(DataProfil d) async {
    final user = ref.read(authProvider).value;
    if (user == null) return;
    setState(() => _sibuk = true);
    try {
      await ref
          .read(repoProvider)
          .simpanProfilBaru(
            uid: user.uid,
            email: user.email ?? '',
            nama: d.nama,
            sekolah: d.sekolah,
            kelas: d.kelas,
            kota: d.kota,
            noHp: d.noHp,
          );
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal menyimpan profil: $e', galat: true);
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lengkapi profil'),
        actions: [TextButton(onPressed: () => ref.read(layananAuthProvider).keluar(), child: const Text('Keluar'))],
      ),
      body: SingleChildScrollView(
        child: Lebar(
          maks: 560,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Halo! Isi data diri kamu dulu.', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('Masuk sebagai ${user?.email ?? '-'}'),
              const SizedBox(height: 20),
              FormProfil(
                nama: user?.displayName ?? '',
                tombol: 'Simpan dan lanjutkan',
                sibuk: _sibuk,
                mintaPersetujuan: true,
                urlPrivasi: '${Konfigurasi.urlWebsite}/privasi',
                onSimpan: _simpan,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
