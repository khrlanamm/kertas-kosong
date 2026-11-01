import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../tema.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';

class HalamanDaftarPengguna extends ConsumerStatefulWidget {
  const HalamanDaftarPengguna({super.key});

  @override
  ConsumerState<HalamanDaftarPengguna> createState() => _HalamanDaftarPenggunaState();
}

class _HalamanDaftarPenggunaState extends ConsumerState<HalamanDaftarPengguna> {
  String _cari = '';

  Future<void> _ubahPeran(Pengguna p, Peran peran) async {
    if (p.peran == peran) return;
    final saya = ref.read(authProvider).value?.uid;
    final ya = await konfirmasi(
      context,
      judul: peran == Peran.admin ? 'Jadikan admin?' : 'Jadikan siswa?',
      isi: peran == Peran.admin
          ? '${p.nama} akan bisa mengelola tryout, soal, hasil, dan peran pengguna lain.'
          : '${p.nama} tidak lagi bisa membuka panel admin.${p.uid == saya ? ' Ini akun kamu sendiri.' : ''}',
      ya: 'Ubah peran',
      bahaya: p.uid == saya,
    );
    if (!ya) return;
    try {
      await ref.read(repoProvider).aturPeran(p.uid, peran);
      if (mounted) tampilkanPesan(context, 'Peran ${p.nama} diubah.');
    } catch (e) {
      if (mounted) tampilkanPesan(context, 'Gagal mengubah peran: $e', galat: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final semua = ref.watch(semuaPenggunaProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pengguna'), actions: const [MenuAkun()]),
      body: semua.when(
        loading: () => const Memuat(),
        error: (e, _) => PesanGalat('Gagal memuat pengguna: $e'),
        data: (daftar) {
          final q = _cari.toLowerCase();
          final hasil = daftar.where((p) => q.isEmpty || '${p.nama} ${p.email} ${p.sekolah} ${p.kota}'.toLowerCase().contains(q)).toList();
          final admin = daftar.where((p) => p.admin).length;
          return ListView(
            children: [
              Lebar(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari nama, email, sekolah, atau kota'),
                      onChanged: (v) => setState(() => _cari = v.trim()),
                    ),
                    const SizedBox(height: 12),
                    Text('${daftar.length} pengguna · $admin admin'),
                    const SizedBox(height: 12),
                    for (final p in hasil)
                      Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: p.admin ? Warna.tinta : Warna.tintaMuda,
                            child: Text(
                              p.nama.isEmpty ? '?' : p.nama[0].toUpperCase(),
                              style: TextStyle(color: p.admin ? Colors.white : Warna.tintaTua),
                            ),
                          ),
                          title: Text(p.nama),
                          subtitle: Text([p.email, p.sekolah, p.kelas, p.kota, p.noHp].where((x) => x.isNotEmpty).join(' · ')),
                          trailing: DropdownButton<Peran>(
                            value: p.peran,
                            underline: const SizedBox.shrink(),
                            items: const [
                              DropdownMenuItem(value: Peran.siswa, child: Text('Siswa')),
                              DropdownMenuItem(value: Peran.admin, child: Text('Admin')),
                            ],
                            onChanged: (v) => v == null ? null : _ubahPeran(p, v),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
