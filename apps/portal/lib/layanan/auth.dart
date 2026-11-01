import 'package:firebase_auth/firebase_auth.dart';

class LayananAuth {
  LayananAuth(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> get perubahan => _auth.authStateChanges();
  User? get pengguna => _auth.currentUser;

  Future<void> masukGoogle() async {
    final penyedia = GoogleAuthProvider()..setCustomParameters({'prompt': 'select_account'});
    await _auth.signInWithPopup(penyedia);
  }

  Future<void> masukEmail(String email, String sandi) => _auth.signInWithEmailAndPassword(email: email.trim(), password: sandi);

  Future<void> daftarEmail(String email, String sandi) async {
    final kredensial = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: sandi);
    await kredensial.user?.sendEmailVerification();
  }

  Future<void> aturUlangSandi(String email) => _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> keluar() => _auth.signOut();
}

/// Pesan galat autentikasi dalam bahasa Indonesia.
String pesanGalatAuth(Object e) {
  if (e is! FirebaseAuthException) return 'Terjadi kesalahan. Coba lagi.';
  return switch (e.code) {
    'invalid-email' => 'Format email tidak valid.',
    'user-disabled' => 'Akun ini dinonaktifkan.',
    'user-not-found' || 'wrong-password' || 'invalid-credential' => 'Email atau kata sandi salah.',
    'email-already-in-use' => 'Email ini sudah terdaftar. Silakan masuk.',
    'weak-password' => 'Kata sandi terlalu lemah. Gunakan minimal 8 karakter.',
    'too-many-requests' => 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
    'popup-closed-by-user' || 'cancelled-popup-request' => 'Jendela masuk Google ditutup sebelum selesai.',
    'popup-blocked' => 'Jendela masuk diblokir browser. Izinkan pop-up untuk situs ini.',
    'network-request-failed' => 'Koneksi bermasalah. Periksa internet kamu.',
    'account-exists-with-different-credential' => 'Email ini sudah terdaftar dengan cara masuk lain.',
    _ => 'Gagal masuk (${e.code}).',
  };
}
