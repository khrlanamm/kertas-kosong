import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna dari logo Komunitas Kertas Kosong.
class Warna {
  static const tinta = Color(0xFF3B7186);
  static const tintaTua = Color(0xFF1F3A46);
  static const tintaMuda = Color(0xFFE1EEF4);
  static const kertas = Color(0xFFFBFAF6);
  static const stabilo = Color(0xFFFFE680);
  static const benar = Color(0xFF15803D);
  static const salah = Color(0xFFB91C1C);
  static const ragu = Color(0xFFF59E0B);
}

ThemeData buatTema() {
  final skema = ColorScheme.fromSeed(seedColor: Warna.tinta, primary: Warna.tinta, surface: Warna.kertas);
  final dasar = ThemeData(colorScheme: skema, useMaterial3: true, scaffoldBackgroundColor: Warna.kertas);
  return dasar.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(dasar.textTheme),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, surfaceTintColor: Colors.white, elevation: 0, scrolledUnderElevation: 1),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Warna.tintaMuda),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: const StadiumBorder()),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: const StadiumBorder()),
    ),
    chipTheme: dasar.chipTheme.copyWith(shape: const StadiumBorder()),
    dividerTheme: const DividerThemeData(color: Warna.tintaMuda),
  );
}
