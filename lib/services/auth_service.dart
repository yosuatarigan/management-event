import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _db = FirebaseFirestore.instance;

  static User? get currentUser => _auth.currentUser;

  static Stream<User?> authStateChanges() => _auth.authStateChanges();

  static Future<void> signOut() => _auth.signOut();

  static Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  static Future<UserCredential> register(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _ensureUserProfile(cred.user!);
    return cred;
  }

  static Future<void> _ensureUserProfile(User user) async {
    final doc = _db.collection('users').doc(user.uid);
    final snap = await doc.get();

    if (snap.exists) return;

    // Jika belum ada admin sama sekali, user pertama jadi admin.
    final adminExists = await _db.collection('users').where('role', isEqualTo: 'admin').limit(1).get();
    final role = adminExists.docs.isEmpty ? 'admin' : 'coordinator';

    await doc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? '',
      'role': role, // admin | coordinator | approver | staff
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> userProfileStream(String uid) {
    return _db.collection('users').doc(uid).snapshots();
  }

  static Future<void> updateRole(String uid, String role) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }
}
