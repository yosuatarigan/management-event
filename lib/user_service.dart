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

  // Create user document after registration - tambahkan parameter locationId
  static Future<void> createUser(
    String uid,
    String email,
    String password,
    String name,
    UserRole role,
    String? locationId, // Parameter baru untuk locationId
  ) async {
    final user = UserModel(
      password: password,
      id: uid,
      email: email,
      name: name,
      role: role,
      createdAt: DateTime.now(),
      locationId: locationId, // Set locationId
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

  // Get users by location - method tambahan
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
}