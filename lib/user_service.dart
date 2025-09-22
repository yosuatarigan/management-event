import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class UserService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _usersCollection = _firestore.collection(
    'users',
  );

  // Get all users
  static Stream<List<UserModel>> getAllUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Get current user data
  static Future<UserModel?> getCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    final doc = await _usersCollection.doc(currentUser.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Create user document after registration
  static Future<void> createUser(
    String uid,
    String email,
    String password,
    String name,
    UserRole role,
    String? locationId,
    List<String> projectIds, // Multi-project support
  ) async {
    final user = UserModel(
      password: password,
      id: uid,
      email: email,
      name: name,
      role: role,
      createdAt: DateTime.now(),
      locationId: locationId,
      projectIds: projectIds, // Assign to multiple projects
      needsMigration: false, // User baru tidak perlu migration
    );

    await _usersCollection.doc(uid).set(user.toMap());
  }

  // Update user
  static Future<void> updateUser(String uid, UserModel user) async {
    await _usersCollection.doc(uid).update(user.toMap());
  }

  // Delete user
  static Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final user = await getCurrentUser();
    return user?.role == UserRole.admin;
  }

  // Get user by ID
  static Future<UserModel?> getUserById(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;

    return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Get users by location
  static Stream<List<UserModel>> getUsersByLocation(String locationId) {
    return _usersCollection
        .where('locationId', isEqualTo: locationId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // ===== MULTI-PROJECT METHODS =====

  // Get users by project ID (multi-project aware)
  static Stream<List<UserModel>> getUsersByProject(String projectId) {
    return _usersCollection
        .where('projectIds', arrayContains: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Get admin users (no project restriction)
  static Stream<List<UserModel>> getAdminUsers() {
    return _usersCollection
        .where('role', isEqualTo: 'admin')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Get users for project (including admins)
  static Stream<List<UserModel>> getUsersForProject(String? projectId) {
    if (projectId == null) {
      // Return only admin users when no project selected
      return getAdminUsers();
    }

    // Return users from specific project + all admins
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .where((user) => user.projectIds.contains(projectId) || user.isAdmin)
                  .toList(),
        );
  }

  // ===== MIGRATION METHODS =====

  // Get users that need migration (user lama tanpa project assignment)
  static Stream<List<UserModel>> getUsersNeedingMigration() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .where((user) => user.needsMigration) // Filter di client side
                  .toList(),
        );
  }

  // Get count of users needing migration
  static Future<int> getMigrationCount() async {
    try {
      QuerySnapshot snapshot = await _usersCollection.get();
      List<UserModel> allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
      
      return allUsers.where((user) => user.needsMigration).length;
    } catch (e) {
      print('Error getting migration count: $e');
      return 0;
    }
  }

  // Assign user to project (for migration or new assignment)
  static Future<void> assignUserToProject(String userId, String projectId) async {
    try {
      UserModel? user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      UserModel updatedUser = user.assignToProject(projectId);
      await updateUser(userId, updatedUser);
    } catch (e) {
      print('Error assigning user to project: $e');
      throw Exception('Failed to assign user to project: $e');
    }
  }

  // Remove user from project
  static Future<void> removeUserFromProject(String userId, String projectId) async {
    try {
      UserModel? user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      UserModel updatedUser = user.removeFromProject(projectId);
      await updateUser(userId, updatedUser);
    } catch (e) {
      print('Error removing user from project: $e');
      throw Exception('Failed to remove user from project: $e');
    }
  }

  // Bulk assign users to project
  static Future<void> bulkAssignUsersToProject(
      List<String> userIds, String projectId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String userId in userIds) {
        UserModel? user = await getUserById(userId);
        if (user != null) {
          UserModel updatedUser = user.assignToProject(projectId);
          batch.update(_usersCollection.doc(userId), updatedUser.toMap());
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error bulk assigning users: $e');
      throw Exception('Failed to bulk assign users: $e');
    }
  }

  // Copy user from one project to another
  static Future<void> copyUserToProject(String userId, String fromProjectId, String toProjectId) async {
    try {
      UserModel? user = await getUserById(userId);
      if (user == null) throw Exception('User not found');

      if (!user.projectIds.contains(fromProjectId)) {
        throw Exception('User is not in source project');
      }

      UserModel updatedUser = user.assignToProject(toProjectId);
      await updateUser(userId, updatedUser);
    } catch (e) {
      print('Error copying user to project: $e');
      throw Exception('Failed to copy user to project: $e');
    }
  }

  // ===== UTILITY METHODS =====

  // Check if user can access project
  static Future<bool> canUserAccessProject(String uid, String projectId) async {
    try {
      UserModel? user = await getUserById(uid);
      if (user == null) return false;
      
      return user.canAccessProject(projectId);
    } catch (e) {
      print('Error checking user access: $e');
      return false;
    }
  }

  // Force refresh migration status untuk semua user (debug purpose)
  static Future<void> refreshMigrationStatus() async {
    try {
      QuerySnapshot snapshot = await _usersCollection.get();
      WriteBatch batch = _firestore.batch();
      
      for (DocumentSnapshot doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Parse user untuk determine migration status
        UserModel user = UserModel.fromMap(data, doc.id);
        
        // Update document dengan migration status yang benar
        Map<String, dynamic> updateData = user.toMap();
        batch.update(_usersCollection.doc(doc.id), updateData);
      }
      
      await batch.commit();
      print('Migration status refreshed for all users');
    } catch (e) {
      print('Error refreshing migration status: $e');
      throw Exception('Failed to refresh migration status: $e');
    }
  }

  // Get users by project count by project
  static Future<int> getUserCountByProject(String projectId) async {
    try {
      QuerySnapshot snapshot = await _usersCollection
          .where('projectIds', arrayContains: projectId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting user count: $e');
      return 0;
    }
  }

  // Get active users by project
  static Stream<List<UserModel>> getActiveUsersByProject(String projectId) {
    return _usersCollection
        .where('projectIds', arrayContains: projectId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Get users by role in specific project
  static Stream<List<UserModel>> getUsersByRoleInProject(
      String projectId, UserRole role) {
    return _usersCollection
        .where('projectIds', arrayContains: projectId)
        .where('role', isEqualTo: role.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => UserModel.fromMap(
                      doc.data() as Map<String, dynamic>,
                      doc.id,
                    ),
                  )
                  .toList(),
        );
  }

  // Get users available for project assignment (not in target project)
  static Stream<List<UserModel>> getUsersAvailableForProject(String projectId) {
    return getAllUsers().map((users) => 
        users.where((user) => 
            !user.isAdmin && // Exclude admins
            !user.projectIds.contains(projectId) && // Not already in project
            !user.needsMigration // Not in migration state
        ).toList()
    );
  }
}