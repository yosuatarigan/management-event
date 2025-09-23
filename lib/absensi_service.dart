import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'absensi_model.dart';
import 'user_model.dart';
import 'session_manager.dart';

class AbsensiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _absensiCollection = _firestore.collection('absensi');
  static final CollectionReference _usersCollection = _firestore.collection('users');

  // ===== PROJECT-AWARE METHODS =====

  // Get absensi by project and date
  static Stream<List<AbsensiModel>> getAbsensiByProjectAndDate(String projectId, DateTime date, String coordinatorId) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _absensiCollection
        .where('project_id', isEqualTo: projectId)
        .where('koordinator_id', isEqualTo: coordinatorId)
        .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
        .where('tanggal', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get absensi by project and coordinator
  static Stream<List<AbsensiModel>> getAbsensiByProjectAndCoordinator(String projectId, String coordinatorId) {
    return _absensiCollection
        .where('project_id', isEqualTo: projectId)
        .where('koordinator_id', isEqualTo: coordinatorId)
        .orderBy('tanggal', descending: true)
        .limit(20) // Batasi untuk performa
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get all bawahan in current project
  static Stream<List<UserModel>> getBawahanByProject(String projectId) {
    return _usersCollection
        .where('role', isEqualTo: 'bawahan')
        .where('isActive', isEqualTo: true)
        .where('projectIds', arrayContains: projectId)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get absensi statistics for project
  static Future<Map<String, dynamic>> getAbsensiStatsByProject(String projectId, String coordinatorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final absensiDocs = await _absensiCollection
        .where('project_id', isEqualTo: projectId)
        .where('koordinator_id', isEqualTo: coordinatorId)
        .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
        .where('tanggal', isLessThanOrEqualTo: endOfDay)
        .get();

    final absensiList = absensiDocs.docs
        .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    int hadirCount = 0;
    int izinCount = 0;
    int sakitCount = 0;
    int alphaCount = 0;

    for (final absensi in absensiList) {
      switch (absensi.status) {
        case StatusAbsensi.hadir:
          hadirCount++;
          break;
        case StatusAbsensi.izin:
          izinCount++;
          break;
        case StatusAbsensi.sakit:
          sakitCount++;
          break;
        case StatusAbsensi.alpha:
          alphaCount++;
          break;
      }
    }

    // Get total bawahan count untuk project ini
    final bawahanDocs = await _usersCollection
        .where('role', isEqualTo: 'bawahan')
        .where('isActive', isEqualTo: true)
        .where('projectIds', arrayContains: projectId)
        .get();
    
    final totalBawahan = bawahanDocs.docs.length;
    final belumAbsen = totalBawahan - absensiList.length;

    return {
      'total_bawahan': totalBawahan,
      'hadir': hadirCount,
      'izin': izinCount,
      'sakit': sakitCount,
      'alpha': alphaCount,
      'belum_absen': belumAbsen,
      'tanggal': date,
    };
  }

  // Create or update absensi with project
  static Future<void> createOrUpdateAbsensiWithProject(AbsensiModel absensi, String projectId) async {
    // Check if absensi already exists for this bawahan on this date in this project
    final existingQuery = await _absensiCollection
        .where('project_id', isEqualTo: projectId)
        .where('bawahan_id', isEqualTo: absensi.bawahanId)
        .where('tanggal', isGreaterThanOrEqualTo: DateTime(absensi.tanggal.year, absensi.tanggal.month, absensi.tanggal.day))
        .where('tanggal', isLessThan: DateTime(absensi.tanggal.year, absensi.tanggal.month, absensi.tanggal.day + 1))
        .get();

    if (existingQuery.docs.isNotEmpty) {
      // Update existing absensi
      final docId = existingQuery.docs.first.id;
      final updatedAbsensi = absensi.copyWith(
        absensiId: docId,
        updatedAt: DateTime.now(),
      );
      final data = updatedAbsensi.toMap();
      data['project_id'] = projectId; // Add project ID
      await _absensiCollection.doc(docId).update(data);
    } else {
      // Create new absensi
      final docRef = _absensiCollection.doc();
      final absensiWithId = absensi.copyWith(absensiId: docRef.id);
      final data = absensiWithId.toMap();
      data['project_id'] = projectId; // Add project ID
      await docRef.set(data);
    }
  }

  // Bulk create absensi for project
  static Future<void> bulkCreateAbsensiForProject(
    List<UserModel> bawahanList,
    DateTime date,
    StatusAbsensi defaultStatus,
    String coordinatorId,
    String coordinatorName,
    String lokasiId,
    String lokasiName,
    String projectId,
  ) async {
    final batch = _firestore.batch();

    for (final bawahan in bawahanList) {
      // Check if absensi already exists
      final existing = await getAbsensiByBawahanAndDateInProject(bawahan.id, date, projectId);
      if (existing != null) continue; // Skip if already exists

      final docRef = _absensiCollection.doc();
      final absensi = AbsensiModel(
        absensiId: docRef.id,
        bawahanId: bawahan.id,
        bawahanName: bawahan.name,
        koordinatorId: coordinatorId,
        koordinatorName: coordinatorName,
        lokasiId: lokasiId,
        lokasiName: lokasiName,
        tanggal: date,
        status: defaultStatus,
        createdAt: DateTime.now(),
      );

      final data = absensi.toMap();
      data['project_id'] = projectId; // Add project ID
      batch.set(docRef, data);
    }

    await batch.commit();
  }

  // Check if absensi exists for bawahan on specific date in project
  static Future<AbsensiModel?> getAbsensiByBawahanAndDateInProject(String bawahanId, DateTime date, String projectId) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _absensiCollection
        .where('project_id', isEqualTo: projectId)
        .where('bawahan_id', isEqualTo: bawahanId)
        .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
        .where('tanggal', isLessThanOrEqualTo: endOfDay)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return AbsensiModel.fromMap(
        query.docs.first.data() as Map<String, dynamic>,
        query.docs.first.id,
      );
    }

    return null;
  }

  // ===== WRAPPER METHODS (menggunakan current project) =====
  
  // Get absensi by date (current project)
  static Stream<List<AbsensiModel>> getAbsensiByDate(DateTime date, String coordinatorId) {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      return Stream.value([]);
    }
    return getAbsensiByProjectAndDate(currentProjectId, date, coordinatorId);
  }

  // Get all bawahan (current project)
  static Stream<List<UserModel>> getAllBawahan() {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      return Stream.value([]);
    }
    return getBawahanByProject(currentProjectId);
  }

  // Get current coordinator absensi (current project)
  static Stream<List<AbsensiModel>> getCurrentCoordinatorAbsensi() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentProjectId = SessionManager.currentProjectId;
    
    if (currentUser == null || currentProjectId == null) {
      return Stream.value([]);
    }
    
    return getAbsensiByProjectAndCoordinator(currentProjectId, currentUser.uid);
  }

  // Get absensi statistics (current project)
  static Future<Map<String, dynamic>> getAbsensiStats(String coordinatorId, DateTime date) async {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      return {
        'total_bawahan': 0,
        'hadir': 0,
        'izin': 0,
        'sakit': 0,
        'alpha': 0,
        'belum_absen': 0,
        'tanggal': date,
      };
    }
    return getAbsensiStatsByProject(currentProjectId, coordinatorId, date);
  }

  // Create or update absensi (current project)
  static Future<void> createOrUpdateAbsensi(AbsensiModel absensi) async {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      throw Exception('No project selected');
    }
    return createOrUpdateAbsensiWithProject(absensi, currentProjectId);
  }

  // Bulk create absensi (current project)
  static Future<void> bulkCreateAbsensi(
    List<UserModel> bawahanList,
    DateTime date,
    StatusAbsensi defaultStatus,
    String coordinatorId,
    String coordinatorName,
    String lokasiId,
    String lokasiName,
  ) async {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      throw Exception('No project selected');
    }
    return bulkCreateAbsensiForProject(
      bawahanList,
      date,
      defaultStatus,
      coordinatorId,
      coordinatorName,
      lokasiId,
      lokasiName,
      currentProjectId,
    );
  }

  // ===== LEGACY METHODS (kept for compatibility) =====

  // Get all absensi (all projects - for admin)
  static Stream<List<AbsensiModel>> getAllAbsensi() {
    return _absensiCollection
        .orderBy('tanggal', descending: true)
        .limit(50) // Batasi untuk performa
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Delete absensi
  static Future<void> deleteAbsensi(String id) async {
    await _absensiCollection.doc(id).delete();
  }

  // Get monthly report for current project
  static Future<Map<String, dynamic>> getMonthlyReport(String coordinatorId, int year, int month) async {
    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      throw Exception('No project selected');
    }

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    final absensiDocs = await _absensiCollection
        .where('project_id', isEqualTo: currentProjectId)
        .where('koordinator_id', isEqualTo: coordinatorId)
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .get();

    final absensiList = absensiDocs.docs
        .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // Group by bawahan
    final Map<String, Map<String, dynamic>> bawahanStats = {};
    
    for (final absensi in absensiList) {
      if (!bawahanStats.containsKey(absensi.bawahanId)) {
        bawahanStats[absensi.bawahanId] = {
          'name': absensi.bawahanName,
          'hadir': 0,
          'izin': 0,
          'sakit': 0,
          'alpha': 0,
          'total_hari': 0,
        };
      }

      final stats = bawahanStats[absensi.bawahanId]!;
      switch (absensi.status) {
        case StatusAbsensi.hadir:
          stats['hadir']++;
          break;
        case StatusAbsensi.izin:
          stats['izin']++;
          break;
        case StatusAbsensi.sakit:
          stats['sakit']++;
          break;
        case StatusAbsensi.alpha:
          stats['alpha']++;
          break;
      }
      stats['total_hari']++;
    }

    return {
      'month': month,
      'year': year,
      'project_id': currentProjectId,
      'bawahan_stats': bawahanStats,
      'total_records': absensiList.length,
    };
  }
}