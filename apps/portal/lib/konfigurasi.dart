import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Konfigurasi dibaca dari `--dart-define-from-file=env/<nama>.json` saat build atau run.
class Konfigurasi {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const messagingSenderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const measurementId = String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  static const pakaiEmulator = bool.fromEnvironment('PAKAI_EMULATOR');
  static const hostEmulator = String.fromEnvironment('HOST_EMULATOR', defaultValue: '127.0.0.1');

  /// Region Cloud Functions, sama dengan lokasi Firestore.
  static const region = 'asia-southeast2';

  static const urlWebsite = String.fromEnvironment('URL_WEBSITE', defaultValue: 'https://kertas-kosong.web.app');

  static bool get lengkap => apiKey.isNotEmpty && appId.isNotEmpty && projectId.isNotEmpty;

  static Future<void> siapkanFirebase() async {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: apiKey,
        appId: appId,
        projectId: projectId,
        authDomain: authDomain.isEmpty ? null : authDomain,
        storageBucket: storageBucket.isEmpty ? null : storageBucket,
        messagingSenderId: messagingSenderId,
        measurementId: measurementId.isEmpty ? null : measurementId,
      ),
    );
    if (pakaiEmulator) {
      await FirebaseAuth.instance.useAuthEmulator(hostEmulator, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(hostEmulator, 8080);
      FirebaseFunctions.instanceFor(region: region).useFunctionsEmulator(hostEmulator, 5001);
      await FirebaseStorage.instance.useStorageEmulator(hostEmulator, 9199);
    }
  }
}
