import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';
import 'roles/admin/admin_dashboard.dart';
import 'roles/coordinator/coordinator_dashboard.dart';
import 'roles/approval/approval_dashboard.dart';

class HomeRouter extends StatelessWidget {
  const HomeRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.authStateChanges(),
      builder: (context, authSnap) {
        if (!authSnap.hasData) return const LoginPage();
        final user = authSnap.data!;
        return StreamBuilder(
          stream: AuthService.userProfileStream(user.uid),
          builder: (context, profSnap) {
            if (!profSnap.hasData || !profSnap.data!.exists) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final data = profSnap.data!.data()!;
            if (data['disabled'] == true) {
              // Blokir akses jika akun dinonaktifkan
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Akun Anda dinonaktifkan. Hubungi admin.')),
                );
                await AuthService.signOut();
              });
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final role = (data['role'] as String?) ?? 'coordinator';
            if (role == 'admin') return const AdminDashboard();
            if (role == 'approver') return const ApprovalDashboard();
            return const CoordinatorDashboard();
          },
        );
      },
    );
  }
}
