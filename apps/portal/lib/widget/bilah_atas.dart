import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/providers.dart';

/// Menu akun di pojok kanan atas.
class MenuAkun extends ConsumerWidget {
  const MenuAkun({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pengguna = ref.watch(penggunaProvider).value;
    final inisial = (pengguna?.nama.trim().isNotEmpty ?? false) ? pengguna!.nama.trim()[0].toUpperCase() : '?';
    return PopupMenuButton<String>(
      tooltip: 'Akun',
      offset: const Offset(0, 48),
      onSelected: (v) async {
        switch (v) {
          case 'profil':
            context.push('/profil');
          case 'jadwal':
            context.push('/jadwal');
          case 'ujian':
            context.go('/ujian');
          case 'admin':
            context.go('/admin/ujian');
          case 'keluar':
            await ref.read(layananAuthProvider).keluar();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, child: Text(pengguna?.email ?? '')),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'profil',
          child: ListTile(leading: Icon(Icons.person_outline), title: Text('Profil')),
        ),
        const PopupMenuItem(
          value: 'jadwal',
          child: ListTile(leading: Icon(Icons.calendar_month), title: Text('Jadwal bimbel')),
        ),
        if (pengguna?.admin ?? false) ...[
          const PopupMenuItem(
            value: 'ujian',
            child: ListTile(leading: Icon(Icons.school_outlined), title: Text('Tampilan siswa')),
          ),
          const PopupMenuItem(
            value: 'admin',
            child: ListTile(leading: Icon(Icons.admin_panel_settings_outlined), title: Text('Panel admin')),
          ),
        ],
        const PopupMenuItem(
          value: 'keluar',
          child: ListTile(leading: Icon(Icons.logout), title: Text('Keluar')),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: CircleAvatar(radius: 18, child: Text(inisial)),
      ),
    );
  }
}
