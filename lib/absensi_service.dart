import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'absensi_model.dart';
import 'user_model.dart';

class AbsensiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _absensiCollection = _firestore.collection('absensi');
  static final CollectionReference _usersCollection = _firestore.collection('users');

  // Get all absensi
  static Stream<List<AbsensiModel>> getAllAbsensi() {
    return _absensiCollection
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get absensi by coordinator
  static Stream<List<AbsensiModel>> getAbsensiByCoordinator(String coordinatorId) {
    return _absensiCollection
        .where('koordinator_id', isEqualTo: coordinatorId)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get absensi by date
  static Stream<List<AbsensiModel>> getAbsensiByDate(DateTime date, String coordinatorId) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    return _absensiCollection
        .where('koordinator_id', isEqualTo: coordinatorId)
        .where('tanggal', isGreaterThanOrEqualTo: startOfDay)
        .where('tanggal', isLessThanOrEqualTo: endOfDay)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get absensi by bawahan and date range
  static Stream<List<AbsensiModel>> getAbsensiByBawahanAndDateRange(
    String bawahanId, 
    DateTime startDate, 
    DateTime endDate
  ) {
    return _absensiCollection
        .where('bawahan_id', isEqualTo: bawahanId)
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThanOrEqualTo: endDate)
        .orderBy('tanggal', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AbsensiModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create or update absensi
  static Future<void> createOrUpdateAbsensi(AbsensiModel absensi) async {
    // Check if absensi already exists for this bawahan on this date
    final existingQuery = await _absensiCollection
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
      await _absensiCollection.doc(docId).update(updatedAbsensi.toMap());
    } else {
      // Create new absensi
      final docRef = _absensiCollection.doc();
      final absensiWithId = absensi.copyWith(absensiId: docRef.id);
      await docRef.set(absensiWithId.toMap());
    }
  }

  // Delete absensi
  static Future<void> deleteAbsensi(String id) async {
    await _absensiCollection.doc(id).delete();
  }

  // Get all bawahan (subordinates)
  static Stream<List<UserModel>> getAllBawahan() {
    return _usersCollection
        .where('role', isEqualTo: 'bawahan')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get current coordinator absensi
  static Stream<List<AbsensiModel>> getCurrentCoordinatorAbsensi() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return getAbsensiByCoordinator(currentUser.uid);
  }

  // Get absensi statistics
  static Future<Map<String, dynamic>> getAbsensiStats(String coordinatorId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final absensiDocs = await _absensiCollection
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

    // Get total bawahan count
    final bawahanDocs = await _usersCollection
        .where('role', isEqualTo: 'bawahan')
        .where('isActive', isEqualTo: true)
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

  // Get monthly report
  static Future<Map<String, dynamic>> getMonthlyReport(String coordinatorId, int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    final absensiDocs = await _absensiCollection
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
      'bawahan_stats': bawahanStats,
      'total_records': absensiList.length,
    };
  }

  // Check if absensi exists for bawahan on specific date
  static Future<AbsensiModel?> getAbsensiByBawahanAndDate(String bawahanId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final query = await _absensiCollection
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

  // Bulk create absensi for multiple bawahan
  static Future<void> bulkCreateAbsensi(
    List<UserModel> bawahanList,
    DateTime date,
    StatusAbsensi defaultStatus,
    String coordinatorId,
    String coordinatorName,
    String lokasiId,
    String lokasiName,
  ) async {
    final batch = _firestore.batch();

    for (final bawahan in bawahanList) {
      // Check if absensi already exists
      final existing = await getAbsensiByBawahanAndDate(bawahan.id, date);
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

      batch.set(docRef, absensi.toMap());
    }

    await batch.commit();
  }
}