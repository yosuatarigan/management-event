import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/cordinator_dashboard.dart';
import 'package:management_event/project_service.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'admin_dashboard.dart';
import 'approver_dashboard.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'project_selection_page.dart';
import 'session_manager.dart';

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

        // Check project selection setelah user data loaded
        return _buildProjectAwareScreen(user);
      },
    );
  }

  Widget _buildProjectAwareScreen(UserModel user) {
    return FutureBuilder<String?>(
      future: SessionManager.getCurrentProject(),
      builder: (context, projectSnapshot) {
        if (projectSnapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScreen();
        }

        final currentProjectId = projectSnapshot.data;

        // Jika user adalah admin dan belum pilih proyek, tampilkan project selection
        if (user.isAdmin && currentProjectId == null) {
          return ProjectSelectionPage(user: user);
        }

        // Jika user bukan admin
        if (!user.isAdmin) {
          // Check apakah user perlu migration
          if (user.needsMigration) {
            return _buildMigrationRequiredScreen();
          }

          // Check apakah user punya akses ke proyek
          if (user.projectIds.isEmpty) {
            return _buildNoProjectAccessScreen();
          }

          // Jika user hanya punya 1 proyek, auto set
          if (user.projectIds.length == 1 && currentProjectId == null) {
            SessionManager.setCurrentProject(user.projectIds.first);
            return _buildLoadingScreen(); // Refresh setelah set project
          }

          // Jika user punya multiple proyek tapi belum pilih
          if (user.projectIds.length > 1 && currentProjectId == null) {
            return ProjectSelectionPage(user: user);
          }

          // Validate akses ke current project
          if (currentProjectId != null && !user.canAccessProject(currentProjectId)) {
            SessionManager.clearProject(); // Clear invalid project
            return ProjectSelectionPage(user: user);
          }
        }

        // Jika admin dan sudah ada current project, validate project masih exist
        if (user.isAdmin && currentProjectId != null) {
          return FutureBuilder<bool>(
            future: _validateProjectExists(currentProjectId),
            builder: (context, validation) {
              if (validation.connectionState == ConnectionState.waiting) {
                return _buildLoadingScreen();
              }

              if (validation.data != true) {
                SessionManager.clearProject();
                return ProjectSelectionPage(user: user);
              }

              // Project valid, route ke dashboard
              return _routeByRole(user, currentProjectId);
            },
          );
        }

        // Route ke dashboard dengan project context
        return _routeByRole(user, currentProjectId);
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

  Widget _buildMigrationRequiredScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sync_alt,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'Account Update Required',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your account needs to be assigned to a project',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Please contact your administrator to assign you to a project.',
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
                  backgroundColor: Colors.orange,
                ),
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoProjectAccessScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                'No Project Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'You do not have access to any projects',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Please contact your administrator for project access.',
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
                  backgroundColor: Colors.red,
                ),
                child: Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _routeByRole(UserModel user, String? projectId) {
    switch (user.role) {
      case UserRole.admin:
        return AdminDashboard();
      
      case UserRole.koordinator:
        return CoordinatorDashboard();
      
      case UserRole.approver:
        return ApproverDashboard();
      
      case UserRole.bawahan:
        return HomePage(userRole: user.role);
    }
  }

  // Helper method untuk validasi project exists
  Future<bool> _validateProjectExists(String projectId) async {
    try {
      final project = await ProjectService.getProjectById(projectId);
      return project != null;
    } catch (e) {
      return false;
    }
  }
}