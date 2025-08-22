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
            final role = data['role'] as String? ?? 'coordinator';
            if (role == 'admin') return const AdminDashboard();
            if (role == 'approver') return const ApprovalDashboard();
            // default: koordinator
            return const CoordinatorDashboard();
          },
        );
      },
    );
  }
}
