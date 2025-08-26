import 'package:cloud_firestore/cloud_firestore.dart';
import 'location_model.dart';

class LocationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _locationsCollection = _firestore.collection('locations');

  // Get all locations
  static Stream<List<LocationModel>> getAllLocations() {
    return _locationsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by city
  static Stream<List<LocationModel>> getLocationsByCity(String city) {
    return _locationsCollection
        .where('city', isEqualTo: city)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get locations by province
  static Stream<List<LocationModel>> getLocationsByProvince(String province) {
    return _locationsCollection
        .where('province', isEqualTo: province)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LocationModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create location
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

  // Search locations by name or city
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

  // Get statistics
  static Future<Map<String, dynamic>> getLocationStats() async {
    final allDocs = await _locationsCollection.get();

    final locations = allDocs.docs
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
      'total': allDocs.docs.length,
      'byCity': cityStats,
      'byProvince': provinceStats,
    };
  }

  // Common cities for dropdown
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

  // Common provinces for dropdown
  static List<String> getCommonProvinces() {
    return [
      'DKI Jakarta',
      'Jawa Barat',
      'Jawa Tengah',
      'Jawa Timur',
      'DI Yogyakarta',
      'Banten',
      'Sumatera Utara',
      'Sumatera Barat',
      'Sumatera Selatan',
      'Riau',
      'Kalimantan Timur',
      'Kalimantan Selatan',
      'Sulawesi Selatan',
      'Sulawesi Utara',
      'Bali',
      'Nusa Tenggara Barat',
      'Papua',
    ];
  }
}