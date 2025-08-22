import 'admin_user_service.dart';

class SampleUsers {
  /// Buat beberapa akun sample dengan role berbeda.
  /// Password default: 123456
  static Future<void> generateAll() async {
    await _createIfNotExists(
      email: 'admin1@example.com',
      password: '123456',
      displayName: 'Admin Satu',
      role: 'admin',
    );
    await _createIfNotExists(
      email: 'coordinator1@example.com',
      password: '123456',
      displayName: 'Koordinator Satu',
      role: 'coordinator',
    );
    await _createIfNotExists(
      email: 'approver1@example.com',
      password: '123456',
      displayName: 'Approver Satu',
      role: 'approver',
    );
    await _createIfNotExists(
      email: 'staff1@example.com',
      password: '123456',
      displayName: 'Staff Satu',
      role: 'staff',
    );
  }

  /// Helper: buat akun jika belum ada (cek Firestore).
  static Future<void> _createIfNotExists({
    required String email,
    required String password,
    required String displayName,
    required String role,
  }) async {
    try {
      await AdminUserService.createUserWithPassword(
        email: email,
        password: password,
        displayName: displayName,
        role: role,
      );
      print('✅ Akun $role berhasil dibuat: $email / $password');
    } catch (e) {
      // Kalau sudah ada, abaikan
      final msg = e.toString();
      if (msg.contains('Email sudah terdaftar') ||
          msg.contains('Email sudah digunakan')) {
        print('⚠️ Akun $email sudah ada, skip.');
      } else {
        print('❌ Gagal buat akun $email: $e');
      }
    }
  }
}
