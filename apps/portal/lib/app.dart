import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rute.dart';
import 'tema.dart';

class PortalApp extends ConsumerWidget {
  const PortalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Portal Bimbel Ayo Kuliah',
    debugShowCheckedModeBanner: false,
    theme: buatTema(),
    routerConfig: ref.watch(ruteProvider),
    locale: const Locale('id', 'ID'),
    supportedLocales: const [Locale('id', 'ID'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
  );
}

/// Ditampilkan jika aplikasi dijalankan tanpa konfigurasi Firebase.
class AplikasiTanpaKonfigurasi extends StatelessWidget {
  const AplikasiTanpaKonfigurasi({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Konfigurasi Firebase belum diisi.\n\n'
            'Jalankan dengan --dart-define-from-file=env/emulator.json (pengembangan) '
            'atau env/produksi.json (produksi).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ),
  );
}
