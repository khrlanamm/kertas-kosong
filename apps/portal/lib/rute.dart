import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'data/providers.dart';
import 'halaman/admin/admin_shell.dart';
import 'halaman/admin/editor_soal.dart';
import 'halaman/admin/editor_ujian.dart';
import 'halaman/admin/daftar_pengguna.dart';
import 'halaman/admin/daftar_program.dart';
import 'halaman/admin/daftar_ujian.dart';
import 'halaman/admin/editor_program.dart';
import 'halaman/auth/lengkapi_profil.dart';
import 'halaman/auth/masuk.dart';
import 'halaman/memuat.dart';
import 'halaman/program/detail_program.dart';
import 'halaman/program/jadwal.dart';
import 'halaman/siswa/beranda.dart';
import 'halaman/siswa/detail_ujian.dart';
import 'halaman/siswa/pembahasan.dart';
import 'halaman/siswa/pengerjaan.dart';
import 'halaman/siswa/profil.dart';

final ruteProvider = Provider<GoRouter>((ref) {
  final segarkan = ValueNotifier(0);
  ref
    ..listen(authProvider, (_, _) => segarkan.value++)
    ..listen(penggunaProvider, (_, _) => segarkan.value++)
    ..onDispose(segarkan.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: segarkan,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final pengguna = ref.read(penggunaProvider);
      final di = state.matchedLocation;
      // Dari halaman masuk, yang perlu diingat adalah tujuan aslinya, bukan halaman masuk itu sendiri.
      final lokasi = di == '/masuk' ? (state.uri.queryParameters['ke'] ?? '/') : state.uri.toString();

      bool layak(String? ke) =>
          ke != null && ke.startsWith('/') && !ke.startsWith('/masuk') && !ke.startsWith('/memuat') && !ke.startsWith('/lengkapi-profil');

      // Tunggu status masuk dan profil selesai dimuat.
      if (auth.isLoading || (auth.value != null && pengguna.isLoading)) {
        return di == '/memuat' ? null : '/memuat?ke=${Uri.encodeComponent(lokasi)}';
      }
      final tujuan = di == '/memuat' ? state.uri.queryParameters['ke'] : lokasi;

      if (auth.value == null) {
        if (di == '/masuk') return null;
        return layak(tujuan) && tujuan != '/' ? '/masuk?ke=${Uri.encodeComponent(tujuan!)}' : '/masuk';
      }

      final profil = pengguna.value;
      if (profil == null) return di == '/lengkapi-profil' ? null : '/lengkapi-profil';

      if (di == '/masuk') {
        final ke = state.uri.queryParameters['ke'];
        return layak(ke) ? ke : '/';
      }
      if (di == '/memuat') return layak(tujuan) ? tujuan : '/';
      if (di == '/lengkapi-profil') return '/';
      if (di == '/') return profil.admin ? '/admin/ujian' : '/ujian';
      if (di.startsWith('/admin') && !profil.admin) return '/ujian';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HalamanMemuat()),
      GoRoute(path: '/memuat', builder: (context, state) => const HalamanMemuat()),
      GoRoute(path: '/masuk', builder: (context, state) => const HalamanMasuk()),
      GoRoute(path: '/lengkapi-profil', builder: (context, state) => const HalamanLengkapiProfil()),
      GoRoute(path: '/profil', builder: (context, state) => const HalamanProfil()),
      GoRoute(path: '/jadwal', builder: (context, state) => const HalamanJadwal()),
      GoRoute(
        path: '/program/:id',
        builder: (context, state) => HalamanDetailProgram(programId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/ujian',
        builder: (context, state) => const HalamanBeranda(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (context, state) => HalamanDetailUjian(ujianId: state.pathParameters['id']!),
            routes: [
              GoRoute(
                path: 'kerjakan/:subtes',
                builder: (context, state) =>
                    HalamanPengerjaan(ujianId: state.pathParameters['id']!, subtesId: state.pathParameters['subtes']!),
              ),
              GoRoute(
                path: 'pembahasan',
                builder: (context, state) => HalamanPembahasan(ujianId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(lokasi: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: '/admin', redirect: (context, state) => state.matchedLocation == '/admin' ? '/admin/ujian' : null),
          GoRoute(
            path: '/admin/ujian',
            builder: (context, state) => const HalamanDaftarUjian(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => HalamanEditorUjian(
                  ujianId: state.pathParameters['id']!,
                  tab: state.uri.queryParameters['tab'],
                  subtes: state.uri.queryParameters['subtes'],
                ),
                routes: [
                  GoRoute(
                    path: 'soal/:soal',
                    builder: (context, state) => HalamanEditorSoal(
                      key: ValueKey(state.uri.toString()),
                      ujianId: state.pathParameters['id']!,
                      soalId: state.pathParameters['soal']!,
                      subtesId: state.uri.queryParameters['subtes'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/admin/program',
            builder: (context, state) => const HalamanDaftarProgram(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    HalamanEditorProgram(programId: state.pathParameters['id']!, tab: state.uri.queryParameters['tab']),
              ),
            ],
          ),
          GoRoute(path: '/admin/pengguna', builder: (context, state) => const HalamanDaftarPengguna()),
        ],
      ),
    ],
  );
});
