import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

import '../../tema.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.lokasi, required this.child});

  final String lokasi;
  final Widget child;

  static const _menu = [
    (ikon: Icons.edit_note, label: 'Tryout', rute: '/admin/ujian'),
    (ikon: Icons.people_outline, label: 'Pengguna', rute: '/admin/pengguna'),
  ];

  int get _terpilih => _menu.indexWhere((m) => lokasi.startsWith(m.rute)).clamp(0, _menu.length - 1);

  @override
  Widget build(BuildContext context) {
    final lebar = MediaQuery.sizeOf(context).width >= 900;
    if (!lebar) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _terpilih,
          onDestinationSelected: (i) => context.go(_menu[i].rute),
          destinations: [for (final m in _menu) NavigationDestination(icon: Icon(m.ikon), label: m.label)],
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _terpilih,
            labelType: NavigationRailLabelType.all,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Image.asset('assets/logo.png', width: 72),
                  const SizedBox(height: 8),
                  const Text(
                    'Admin',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Warna.tinta),
                  ),
                ],
              ),
            ),
            onDestinationSelected: (i) => context.go(_menu[i].rute),
            destinations: [for (final m in _menu) NavigationRailDestination(icon: Icon(m.ikon), label: Text(m.label))],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
