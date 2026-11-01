import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/model.dart';
import '../../data/providers.dart';
import '../../widget/bilah_atas.dart';
import '../../widget/umum.dart';
import 'tab_hasil.dart';
import 'tab_pengaturan.dart';
import 'tab_soal.dart';

class HalamanEditorUjian extends ConsumerWidget {
  const HalamanEditorUjian({super.key, required this.ujianId, this.tab, this.subtes});

  final String ujianId;
  final String? tab;
  final String? subtes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ujian = ref.watch(ujianProvider(ujianId));
    final indeksTab = switch (tab) {
      'soal' => 1,
      'hasil' => 2,
      _ => 0,
    };
    return ujian.when(
      loading: () => const Scaffold(body: Memuat()),
      error: (e, _) => Scaffold(body: PesanGalat('Gagal memuat tryout: $e')),
      data: (Ujian? u) {
        if (u == null) {
          return Scaffold(
            appBar: AppBar(leading: BackButton(onPressed: () => context.go('/admin/ujian'))),
            body: const PesanGalat('Tryout tidak ditemukan.'),
          );
        }
        return DefaultTabController(
          key: ValueKey('tab-$indeksTab'),
          length: 3,
          initialIndex: indeksTab,
          child: Scaffold(
            appBar: AppBar(
              leading: BackButton(onPressed: () => context.go('/admin/ujian')),
              title: Text(u.judul, overflow: TextOverflow.ellipsis),
              actions: [
                TextButton.icon(
                  onPressed: () => context.push('/ujian/${u.id}'),
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Coba sebagai peserta'),
                ),
                const MenuAkun(),
              ],
              bottom: const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Pengaturan'),
                  Tab(text: 'Subtes & soal'),
                  Tab(text: 'Hasil'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                TabPengaturan(ujian: u),
                TabSoal(ujian: u, subtesAwal: subtes),
                TabHasil(ujian: u),
              ],
            ),
          ),
        );
      },
    );
  }
}
