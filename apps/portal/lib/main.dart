import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'konfigurasi.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  // Alamat di browser ikut berubah saat memakai context.push, supaya halaman bisa dimuat ulang atau dibagikan.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  await initializeDateFormatting('id_ID');

  if (!Konfigurasi.lengkap) {
    runApp(const AplikasiTanpaKonfigurasi());
    return;
  }
  await Konfigurasi.siapkanFirebase();
  runApp(const ProviderScope(child: PortalApp()));
}
