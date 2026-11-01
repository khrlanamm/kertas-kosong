# Portal Bimbel Ayo Kuliah

Aplikasi Flutter untuk Portal Bimbel Komunitas Kertas Kosong (web dulu, Android menyusul).

Panduan lengkap (fitur, tipe soal, cara menjalankan dengan emulator, dan cara menayangkan) ada di [docs/portal.md](../../docs/portal.md).

Ringkasnya, untuk pengembangan:

```sh
firebase emulators:start --project demo-kertas-kosong   # dari root repo
flutter run -d chrome --dart-define-from-file=env/emulator.json
```
