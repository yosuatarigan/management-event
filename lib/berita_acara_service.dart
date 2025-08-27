import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'berita_acara_model.dart';
import 'user_service.dart';
import 'location_service.dart';

class BeritaAcaraService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final CollectionReference _beritaAcaraCollection = _firestore.collection('berita_acara');

  // Get all berita acara
  static Stream<List<BeritaAcaraModel>> getAllBeritaAcara() {
    return _beritaAcaraCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BeritaAcaraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get berita acara by koordinator
  static Stream<List<BeritaAcaraModel>> getBeritaAcaraByKoordinator(String koordinatorId) {
    return _beritaAcaraCollection
        .where('koordinator_id', isEqualTo: koordinatorId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BeritaAcaraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get berita acara by status
  static Stream<List<BeritaAcaraModel>> getBeritaAcaraByStatus(StatusBA status) {
    return _beritaAcaraCollection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BeritaAcaraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create berita acara
  static Future<void> createBeritaAcara(BeritaAcaraModel beritaAcara) async {
    final docRef = _beritaAcaraCollection.doc();
    final baWithId = beritaAcara.copyWith(baId: docRef.id);
    await docRef.set(baWithId.toMap());
  }

  // Update berita acara
  static Future<void> updateBeritaAcara(String id, BeritaAcaraModel beritaAcara) async {
    await _beritaAcaraCollection.doc(id).update(beritaAcara.toMap());
  }

  // Delete berita acara
  static Future<void> deleteBeritaAcara(String id) async {
    // Get the document first to delete associated files
    final doc = await _beritaAcaraCollection.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final lampiranUrls = List<String>.from(data['lampiran_urls'] ?? []);
      
      // Delete files from storage
      for (String url in lampiranUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
    }
    
    await _beritaAcaraCollection.doc(id).delete();
  }

  // Get berita acara by ID
  static Future<BeritaAcaraModel?> getBeritaAcaraById(String id) async {
    final doc = await _beritaAcaraCollection.doc(id).get();
    if (!doc.exists) return null;

    return BeritaAcaraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Upload file to Firebase Storage
  static Future<String> uploadFile(File file, String baId) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = file.path.split('.').last;
      final String fullFileName = '${fileName}.$extension';
      
      final Reference ref = _storage
          .ref()
          .child('berita_acara')
          .child(baId)
          .child(fullFileName);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Upload multiple files
  static Future<List<String>> uploadMultipleFiles(List<File> files, String baId) async {
    List<String> urls = [];
    for (File file in files) {
      try {
        String url = await uploadFile(file, baId);
        urls.add(url);
      } catch (e) {
        print('Error uploading file: $e');
      }
    }
    return urls;
  }

  // Approve berita acara
  static Future<void> approveBeritaAcara(String baId, String approverId) async {
    await _beritaAcaraCollection.doc(baId).update({
      'status': StatusBA.approved.toString().split('.').last,
      'approved_by': approverId,
      'approved_at': DateTime.now(),
      'updated_at': DateTime.now(),
    });
  }

  // Reject berita acara
  static Future<void> rejectBeritaAcara(String baId, String approverId, String reason) async {
    await _beritaAcaraCollection.doc(baId).update({
      'status': StatusBA.rejected.toString().split('.').last,
      'approved_by': approverId,
      'approved_at': DateTime.now(),
      'rejection_reason': reason,
      'updated_at': DateTime.now(),
    });
  }

  // Get current user berita acara
  static Stream<List<BeritaAcaraModel>> getCurrentUserBeritaAcara() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return getBeritaAcaraByKoordinator(currentUser.uid);
  }

  // Get statistics
  static Future<Map<String, dynamic>> getBeritaAcaraStats() async {
    final allDocs = await _beritaAcaraCollection.get();
    final pendingDocs = await _beritaAcaraCollection.where('status', isEqualTo: 'pending').get();
    final approvedDocs = await _beritaAcaraCollection.where('status', isEqualTo: 'approved').get();
    final rejectedDocs = await _beritaAcaraCollection.where('status', isEqualTo: 'rejected').get();

    final beritaAcaraList = allDocs.docs
        .map((doc) => BeritaAcaraModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final jenisStats = <String, int>{};
    final lokasiStats = <String, int>{};

    for (final ba in beritaAcaraList) {
      final jenis = ba.jenisBADisplayName;
      final lokasi = ba.lokasiName;

      jenisStats[jenis] = (jenisStats[jenis] ?? 0) + 1;
      lokasiStats[lokasi] = (lokasiStats[lokasi] ?? 0) + 1;
    }

    return {
      'total': allDocs.docs.length,
      'pending': pendingDocs.docs.length,
      'approved': approvedDocs.docs.length,
      'rejected': rejectedDocs.docs.length,
      'byJenis': jenisStats,
      'byLokasi': lokasiStats,
    };
  }

  // Get jenis BA options
  static List<String> getJenisBAOptions() {
    return JenisBA.values.map((jenis) {
      switch (jenis) {
        case JenisBA.pembukaan:
          return 'Pembukaan';
        case JenisBA.kendala:
          return 'Kendala';
        case JenisBA.penutupan:
          return 'Penutupan';
        case JenisBA.monitoring:
          return 'Monitoring';
        case JenisBA.evaluasi:
          return 'Evaluasi';
        case JenisBA.lainnya:
          return 'Lainnya';
      }
    }).toList();
  }
}