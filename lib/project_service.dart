import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'project_model.dart';

class ProjectService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection reference
  static CollectionReference get _projectsCollection =>
      _firestore.collection('projects');

  // Get all projects
  static Stream<List<ProjectModel>> getProjects() {
    return _projectsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get project by ID
  static Future<ProjectModel?> getProjectById(String id) async {
    try {
      DocumentSnapshot doc = await _projectsCollection.doc(id).get();
      if (doc.exists) {
        return ProjectModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting project: $e');
      return null;
    }
  }

  // Create new project
  static Future<String?> createProject(ProjectModel project) async {
    try {
      String currentUserId = _auth.currentUser?.uid ?? '';
      
      ProjectModel newProject = project.copyWith(
        createdBy: currentUserId,
        createdAt: DateTime.now(),
      );

      DocumentReference docRef = await _projectsCollection.add(newProject.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating project: $e');
      throw Exception('Gagal membuat proyek: $e');
    }
  }

  // Update project
  static Future<void> updateProject(String id, ProjectModel project) async {
    try {
      ProjectModel updatedProject = project.copyWith(
        updatedAt: DateTime.now(),
      );

      await _projectsCollection.doc(id).update(updatedProject.toFirestore());
    } catch (e) {
      print('Error updating project: $e');
      throw Exception('Gagal mengupdate proyek: $e');
    }
  }

  // Delete project
  static Future<void> deleteProject(String id) async {
    try {
      await _projectsCollection.doc(id).delete();
    } catch (e) {
      print('Error deleting project: $e');
      throw Exception('Gagal menghapus proyek: $e');
    }
  }

  // Search projects
  static Stream<List<ProjectModel>> searchProjects(String query) {
    return _projectsCollection
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    });
  }

  // Search projects by venue type
  static Stream<List<ProjectModel>> getProjectsByVenueType(String venueType) {
    return _projectsCollection
        .where('venueType', isEqualTo: venueType)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    });
  }

  // Search projects by city
  static Stream<List<ProjectModel>> getProjectsByCity(String city) {
    return _projectsCollection
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromFirestore(doc))
          .toList();
    });
  }

  // Get project count
  static Future<int> getProjectCount() async {
    try {
      QuerySnapshot snapshot = await _projectsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting project count: $e');
      return 0;
    }
  }
}