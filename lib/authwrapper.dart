import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/cordinator_dashboard.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'admin_dashboard.dart';
import 'user_service.dart';
import 'user_model.dart';

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading state saat checking authentication
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Jika ada error
        if (snapshot.hasError) {
          return _buildErrorScreen('Authentication Error: ${snapshot.error}');
        }
        
        // Jika user sudah login
        if (snapshot.hasData && snapshot.data != null) {
          return _buildAuthenticatedScreen();
        }
        
        // Jika user belum login
        return LoginPage();
      },
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Force rebuild widget
              },
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticatedScreen() {
    return FutureBuilder<UserModel?>(
      future: UserService.getCurrentUser(),
      builder: (context, userSnapshot) {
        // Loading state saat mengambil data user
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        // Jika ada error saat mengambil data user
        if (userSnapshot.hasError) {
          return _buildErrorScreen('Failed to load user data: ${userSnapshot.error}');
        }
        
        final user = userSnapshot.data;
        
        // Jika data user tidak ditemukan di Firestore
        if (user == null) {
          return _buildUserSetupScreen();
        }
        
        // Route berdasarkan role user
        return _routeByRole(user);
      },
    );
  }

  Widget _buildUserSetupScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_outline,
                size: 64,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your account is being set up...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Please contact your administrator to complete account setup.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                ),
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeByRole(UserModel user) {
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboard();
      
      case UserRole.koordinator:
        return CoordinatorDashboard();
      
      case UserRole.approver:
        // Bisa dikembangkan dengan dashboard khusus approver
        return HomePage(userRole: user.role);
      
      case UserRole.bawahan:
        // Dashboard untuk bawahan
        return HomePage(userRole: user.role);
      
      default:
        return HomePage(userRole: user.role);
    }
  }
}