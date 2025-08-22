import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service manajemen akun TANPA Cloud Functions.
/// Admin membuat user baru via secondary Firebase App agar tidak mengganggu sesi login saat ini.
class AdminUserService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Buat akun baru (Auth + dokumen Firestore).
  /// Tetap mempertahankan sesi Admin (pakai secondary app).
  ///
  /// [email], [password] wajib. [displayName] opsional.
  /// [role] salah satu dari: 'admin' | 'coordinator' | 'approver' | 'staff'
  ///
  /// return: uid user yang dibuat.
  static Future<String> createUserWithPassword({
    required String email,
    required String password,
    String displayName = '',
    String role = 'coordinator',
  }) async {
    _assertValidEmail(email);
    _assertValidPassword(password);
    _assertValidRole(role);

    // Cek duplikat email di Firestore (mirror). Tidak menjamin 100%, tapi cepat.
    final existsInMirror = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
    if (existsInMirror.docs.isNotEmpty) {
      throw Exception('Email sudah terdaftar di sistem.');
    }

    // Init secondary app dengan nama unik dan aman (maks 25 char untuk jaga-jaga).
    final String appName = _uniqueAppNameFromEmail(email);

    // Jika appName sudah ada (jarang), tambahkan suffix acak.
    FirebaseApp? tempApp;
    try {
      final base = Firebase.app();
      tempApp = await Firebase.initializeApp(
        name: appName,
        options: base.options,
      );

      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // Coba create di Auth
      final cred = await tempAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user!.uid;

      // Update display name (opsional)
      if (displayName.trim().isNotEmpty) {
        await cred.user!.updateDisplayName(displayName.trim());
      }

      // Tulis mirror profile di Firestore
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email.trim(),
        'displayName': displayName.trim(),
        'role': role,
        'disabled': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email sudah digunakan di Firebase Auth.');
      }
      if (e.code == 'invalid-email') {
        throw Exception('Format email tidak valid.');
      }
      if (e.code == 'weak-password') {
        throw Exception('Password terlalu lemah.');
      }
      throw Exception('Gagal membuat akun: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Gagal membuat akun: $e');
    } finally {
      // Pastikan secondary app ditutup
      try {
        await tempApp?.delete();
      } catch (_) {/* abaikan */}
    }
  }

  /// Ubah role user (update di Firestore mirror).
  /// Tidak menyentuh Auth custom claims (karena kita tanpa Cloud Functions).
  static Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    _assertValidRole(role);
    if (uid.isEmpty) throw Exception('UID tidak boleh kosong.');
    try {
      await _db.collection('users').doc(uid).update({'role': role});
    } catch (e) {
      throw Exception('Gagal mengubah role: $e');
    }
  }

  /// Nonaktifkan/aktifkan akun (flag di Firestore).
  /// Akses akan diblokir di router saat login jika disabled = true.
  static Future<void> setUserDisabled({
    required String uid,
    required bool disabled,
  }) async {
    if (uid.isEmpty) throw Exception('UID tidak boleh kosong.');
    try {
      await _db.collection('users').doc(uid).update({'disabled': disabled});
    } catch (e) {
      throw Exception('Gagal mengubah status akun: $e');
    }
  }

  /// Kirim email reset password ke alamat email user.
  static Future<void> sendPasswordResetEmail(String email) async {
    _assertValidEmail(email);
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        // Tetap tanggapi sukses untuk keamanan, tapi beri info dev.
        throw Exception('Email belum terdaftar di Firebase Auth.');
      }
      throw Exception('Gagal mengirim reset password: ${e.message ?? e.code}');
    } catch (e) {
      throw Exception('Gagal mengirim reset password: $e');
    }
  }

  // =============================
  // Helpers
  // =============================

  static void _assertValidEmail(String email) {
    final value = email.trim();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (value.isEmpty || !regex.hasMatch(value)) {
      throw Exception('Email tidak valid.');
    }
  }

  static void _assertValidPassword(String password) {
    if (password.length < 6) {
      throw Exception('Password minimal 6 karakter.');
    }
  }

  static void _assertValidRole(String role) {
    const roles = {'admin', 'coordinator', 'approver', 'staff'};
    if (!roles.contains(role)) {
      throw Exception('Role tidak dikenali.');
    }
  }

  /// Buat nama app unik dari email, huruf/angka/underscore, panjang aman.
  static String _uniqueAppNameFromEmail(String email) {
    String base = email
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    if (base.length > 18) base = base.substring(0, 18);
    final suffix = _randomString(6);
    return 'sec_${base}_$suffix'; // contoh: sec_admin_gmail_abc123
  }

  static String _randomString(int len) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(len, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}
