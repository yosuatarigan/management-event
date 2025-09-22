import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'user_model.dart';

class SessionManager {
  static const String _currentProjectKey = 'current_project_id';
  
  // Current session data
  static String? _currentProjectId;
  static UserModel? _currentUser;
  
  // Getters
  static String? get currentProjectId => _currentProjectId;
  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;
  static bool get hasProjectSelected => _currentProjectId != null;
  
  // Initialize session (call on app start)
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentProjectId = prefs.getString(_currentProjectKey);
      
      // Load user data if logged in
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUser = await UserService.getUserById(firebaseUser.uid);
        
        // Validate project access jika ada project yang tersimpan
        if (_currentProjectId != null && _currentUser != null) {
          if (!_currentUser!.canAccessProject(_currentProjectId)) {
            await clearProject(); // Clear invalid project
          }
        }
      }
    } catch (e) {
      print('Error initializing session: $e');
      // Clear session jika ada error
      await clearSession();
    }
  }
  
  // Set current project (after login/selection)
  static Future<void> setCurrentProject(String projectId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentProjectKey, projectId);
      _currentProjectId = projectId;
      
      print('Current project set to: $projectId');
    } catch (e) {
      print('Error setting current project: $e');
      throw Exception('Failed to set current project');
    }
  }
  
  // Get current project
  static Future<String?> getCurrentProject() async {
    if (_currentProjectId != null) return _currentProjectId;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentProjectId = prefs.getString(_currentProjectKey);
      return _currentProjectId;
    } catch (e) {
      print('Error getting current project: $e');
      return null;
    }
  }
  
  // Clear project only (keep user login)
  static Future<void> clearProject() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentProjectKey);
      _currentProjectId = null;
      
      print('Current project cleared');
    } catch (e) {
      print('Error clearing project: $e');
    }
  }
  
  // Clear entire session (logout)
  static Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentProjectKey);
      _currentProjectId = null;
      _currentUser = null;
      
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      print('Session cleared');
    } catch (e) {
      print('Error clearing session: $e');
    }
  }
  
  // Refresh user data (call when user data might have changed)
  static Future<void> refreshUserData() async {
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        _currentUser = await UserService.getUserById(firebaseUser.uid);
        
        // Check if still has access to current project
        if (_currentProjectId != null && 
            _currentUser != null && 
            !_currentUser!.canAccessProject(_currentProjectId)) {
          await clearProject();
          throw Exception('Access to current project has been revoked');
        }
      }
    } catch (e) {
      print('Error refreshing user data: $e');
      rethrow;
    }
  }
  
  // Check if user can access current project
  static bool canAccessCurrentProject() {
    if (_currentUser == null || _currentProjectId == null) return false;
    return _currentUser!.canAccessProject(_currentProjectId);
  }
  
  // Switch project (for users with multiple project access)
  static Future<bool> switchProject(String newProjectId) async {
    try {
      if (_currentUser == null) return false;
      
      if (!_currentUser!.canAccessProject(newProjectId)) {
        throw Exception('No access to selected project');
      }
      
      await setCurrentProject(newProjectId);
      return true;
    } catch (e) {
      print('Error switching project: $e');
      return false;
    }
  }
  
  // Helper method untuk debug
  static void printSessionInfo() {
    print('=== SESSION INFO ===');
    print('User: ${_currentUser?.name ?? 'null'}');
    print('Project ID: ${_currentProjectId ?? 'null'}');
    print('Is Admin: ${_currentUser?.isAdmin ?? false}');
    print('Can Access Project: ${canAccessCurrentProject()}');
    print('==================');
  }
}