import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _locationsCollection = _firestore.collection('locations');

  // ===== PROJECT-AWARE METHODS =====

  // Get locations by project ID
  static Stream<List<LocationModel>> getLocationsByProject(String projectId) {
    return _locationsCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by city in specific project
  static Stream<List<LocationModel>> getLocationsByCityInProject(String projectId, String city) {
    return _locationsCollection
        .where('projectId', isEqualTo: projectId)
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by province in specific project
  static Stream<List<LocationModel>> getLocationsByProvinceInProject(String projectId, String province) {
    return _locationsCollection
        .where('projectId', isEqualTo: projectId)
        .where('province', isEqualTo: province)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Search locations in specific project
  static Stream<List<LocationModel>> searchLocationsInProject(String projectId, String query) {
    if (query.isEmpty) {
      return getLocationsByProject(projectId);
    }

    return _locationsCollection
        .where('projectId', isEqualTo: projectId)
        .orderBy('name')
        .startAt([query.toLowerCase()])
        .endAt([query.toLowerCase() + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create location for specific project
  static Future<void> createLocationForProject(String projectId, LocationModel location) async {
    final docRef = _locationsCollection.doc();
    final locationWithId = location.copyWith(
      id: docRef.id,
      projectId: projectId,
    );
    await docRef.set(locationWithId.toMap());
  }

  // Copy location to another project
  static Future<void> copyLocationToProject(String locationId, String targetProjectId) async {
    try {
      LocationModel? sourceLocation = await getLocationById(locationId);
      if (sourceLocation == null) {
        throw Exception('Source location not found');
      }

      LocationModel newLocation = sourceLocation.copyToProject(targetProjectId);
      await createLocationForProject(targetProjectId, newLocation);
    } catch (e) {
      print('Error copying location to project: $e');
      throw Exception('Failed to copy location to project: $e');
    }
  }

  // Bulk copy locations to project
  static Future<void> bulkCopyLocationsToProject(
      List<String> locationIds, String targetProjectId) async {
    try {
      WriteBatch batch = _firestore.batch();
      
      for (String locationId in locationIds) {
        LocationModel? sourceLocation = await getLocationById(locationId);
        if (sourceLocation != null) {
          final docRef = _locationsCollection.doc();
          LocationModel newLocation = sourceLocation.copyWith(
            id: docRef.id,
            projectId: targetProjectId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          batch.set(docRef, newLocation.toMap());
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error bulk copying locations: $e');
      throw Exception('Failed to bulk copy locations: $e');
    }
  }

  // Get locations available for copying (from other projects)
  static Stream<List<LocationModel>> getLocationsAvailableForProject(
      String targetProjectId) {
    return _locationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((location) => location.projectId != targetProjectId)
            .toList());
  }

  // Get location count by project
  static Future<int> getLocationCountByProject(String projectId) async {
    try {
      QuerySnapshot snapshot = await _locationsCollection
          .where('projectId', isEqualTo: projectId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting location count: $e');
      return 0;
    }
  }

  // ===== LEGACY METHODS (Updated) =====

  // Get all locations (for admin/debugging)
  static Stream<List<LocationModel>> getAllLocations() {
    return _locationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by city (all projects)
  static Stream<List<LocationModel>> getLocationsByCity(String city) {
    return _locationsCollection
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by province (all projects)
  static Stream<List<LocationModel>> getLocationsByProvince(String province) {
    return _locationsCollection
        .where('province', isEqualTo: province)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create location (legacy - will use first project if available)
  static Future<void> createLocation(LocationModel location) async {
    final docRef = _locationsCollection.doc();
    final locationWithId = location.copyWith(id: docRef.id);
    await docRef.set(locationWithId.toMap());
  }

  // Update location
  static Future<void> updateLocation(String id, LocationModel location) async {
    await _locationsCollection.doc(id).update(location.toMap());
  }

  // Delete location
  static Future<void> deleteLocation(String id) async {
    await _locationsCollection.doc(id).delete();
  }

  // Get location by ID
  static Future<LocationModel?> getLocationById(String id) async {
    final doc = await _locationsCollection.doc(id).get();
    if (!doc.exists) return null;

    return LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Search locations by name or city (all projects)
  static Stream<List<LocationModel>> searchLocations(String query) {
    if (query.isEmpty) {
      return getAllLocations();
    }

    return _locationsCollection
        .orderBy('name')
        .startAt([query.toLowerCase()])
        .endAt([query.toLowerCase() + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get statistics by project
  static Future<Map<String, dynamic>> getLocationStatsByProject(String projectId) async {
    final projectDocs = await _locationsCollection
        .where('projectId', isEqualTo: projectId)
        .get();

    final locations = projectDocs.docs
        .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final cityStats = <String, int>{};
    final provinceStats = <String, int>{};

    for (final location in locations) {
      final city = location.city;
      final province = location.province;

      cityStats[city] = (cityStats[city] ?? 0) + 1;
      provinceStats[province] = (provinceStats[province] ?? 0) + 1;
    }

    return {
      'total': projectDocs.docs.length,
      'byCity': cityStats,
      'byProvince': provinceStats,
    };
  }

  // Get statistics (all projects)
  static Future<Map<String, dynamic>> getLocationStats() async {
    final allDocs = await _locationsCollection.get();

    final locations = allDocs.docs
        .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final cityStats = <String, int>{};
    final provinceStats = <String, int>{};
    final projectStats = <String, int>{};

    for (final location in locations) {
      final city = location.city;
      final province = location.province;
      final projectId = location.projectId;

      cityStats[city] = (cityStats[city] ?? 0) + 1;
      provinceStats[province] = (provinceStats[province] ?? 0) + 1;
      projectStats[projectId] = (projectStats[projectId] ?? 0) + 1;
    }

    return {
      'total': allDocs.docs.length,
      'byCity': cityStats,
      'byProvince': provinceStats,
      'byProject': projectStats,
    };
  }

  // Complete list of Indonesian provinces
  static List<String> getAllIndonesianProvinces() {
    return [
      'Aceh',
      'Sumatera Utara',
      'Sumatera Barat',
      'Riau',
      'Kepulauan Riau',
      'Jambi',
      'Sumatera Selatan',
      'Kepulauan Bangka Belitung',
      'Bengkulu',
      'Lampung',
      'DKI Jakarta',
      'Jawa Barat',
      'Banten',
      'Jawa Tengah',
      'DI Yogyakarta',
      'Jawa Timur',
      'Bali',
      'Nusa Tenggara Barat',
      'Nusa Tenggara Timur',
      'Kalimantan Barat',
      'Kalimantan Tengah',
      'Kalimantan Selatan',
      'Kalimantan Timur',
      'Kalimantan Utara',
      'Sulawesi Utara',
      'Gorontalo',
      'Sulawesi Tengah',
      'Sulawesi Barat',
      'Sulawesi Selatan',
      'Sulawesi Tenggara',
      'Maluku',
      'Maluku Utara',
      'Papua',
      'Papua Barat',
      'Papua Tengah',
      'Papua Pegunungan',
      'Papua Selatan',
      'Papua Barat Daya',
    ];
  }

  // Common cities for dropdown (kept for backward compatibility)
  static List<String> getCommonCities() {
    return [
      'Jakarta',
      'Bandung',
      'Surabaya',
      'Medan',
      'Semarang',
      'Makassar',
      'Palembang',
      'Tangerang',
      'Bekasi',
      'Depok',
      'Yogyakarta',
      'Malang',
      'Balikpapan',
      'Denpasar',
      'Manado',
    ];
  }

  // Common provinces for dropdown (legacy - now replaced with complete list)
  static List<String> getCommonProvinces() {
    return getAllIndonesianProvinces(); // Use complete list
  }
}