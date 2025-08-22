import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SampleUsers {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  /// Buat sample user untuk semua role
  /// Email dibuat dengan format: roleX@example.com (password: 123456)
  static Future<void> generateAll() async {
    await _createUser('admin1@example.com', '123456', 'admin');
    await _createUser('coordinator1@example.com', '123456', 'coordinator');
    await _createUser('approver1@example.com', '123456', 'approver');
    await _createUser('staff1@example.com', '123456', 'staff');
  }

  /// Fungsi util untuk buat akun
  static Future<void> _createUser(String email, String password, String role) async {
    try {
      // Sign up pakai createUserWithEmailAndPassword harus logout dulu dari user sekarang
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('✅ Akun $role berhasil dibuat: $email / $password');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️ Akun $email sudah ada');
      } else {
        print('❌ Gagal buat akun $email: ${e.message}');
      }
    }
  }
}
