import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'evidence_model.dart';

class EvidenceService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final CollectionReference _evidenceCollection = _firestore.collection('evidence');

  // Get all evidence
  static Stream<List<EvidenceModel>> getAllEvidence() {
    return _evidenceCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get evidence by uploader
  static Stream<List<EvidenceModel>> getEvidenceByUploader(String uploaderId) {
    return _evidenceCollection
        .where('uploaded_by', isEqualTo: uploaderId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get evidence by status
  static Stream<List<EvidenceModel>> getEvidenceByStatus(StatusEvidence status) {
    return _evidenceCollection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get evidence by kategori
  static Stream<List<EvidenceModel>> getEvidenceByKategori(KategoriEvidence kategori) {
    return _evidenceCollection
        .where('kategori', isEqualTo: kategori.toString().split('.').last)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create evidence
  static Future<void> createEvidence(EvidenceModel evidence) async {
    final docRef = _evidenceCollection.doc();
    final evidenceWithId = evidence.copyWith(evidenceId: docRef.id);
    await docRef.set(evidenceWithId.toMap());
  }

  // Update evidence
  static Future<void> updateEvidence(String id, EvidenceModel evidence) async {
    await _evidenceCollection.doc(id).update(evidence.toMap());
  }

  // Delete evidence
  static Future<void> deleteEvidence(String id) async {
    // Get the document first to delete associated file
    final doc = await _evidenceCollection.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final fileUrl = data['file_url'] as String?;
      
      // Delete file from storage
      if (fileUrl != null && fileUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(fileUrl).delete();
        } catch (e) {
          print('Error deleting file: $e');
        }
      }
    }
    
    await _evidenceCollection.doc(id).delete();
  }

  // Get evidence by ID
  static Future<EvidenceModel?> getEvidenceById(String id) async {
    final doc = await _evidenceCollection.doc(id).get();
    if (!doc.exists) return null;

    return EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Upload file to Firebase Storage
  static Future<String> uploadFile(File file, String evidenceId, KategoriEvidence kategori) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = file.path.split('.').last.toLowerCase();
      final String fullFileName = '${fileName}.$extension';
      
      final Reference ref = _storage
          .ref()
          .child('evidence')
          .child(kategori.toString().split('.').last)
          .child(evidenceId)
          .child(fullFileName);

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  // Approve evidence
  static Future<void> approveEvidence(String evidenceId, String approverId) async {
    await _evidenceCollection.doc(evidenceId).update({
      'status': StatusEvidence.approved.toString().split('.').last,
      'approved_by': approverId,
      'approved_at': DateTime.now(),
    });
  }

  // Reject evidence
  static Future<void> rejectEvidence(String evidenceId, String approverId, String reason) async {
    await _evidenceCollection.doc(evidenceId).update({
      'status': StatusEvidence.rejected.toString().split('.').last,
      'approved_by': approverId,
      'approved_at': DateTime.now(),
      'rejection_reason': reason,
    });
  }

  // Get current user evidence
  static Stream<List<EvidenceModel>> getCurrentUserEvidence() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return getEvidenceByUploader(currentUser.uid);
  }

  // Get statistics
  static Future<Map<String, dynamic>> getEvidenceStats() async {
    final allDocs = await _evidenceCollection.get();
    final pendingDocs = await _evidenceCollection.where('status', isEqualTo: 'pending').get();
    final approvedDocs = await _evidenceCollection.where('status', isEqualTo: 'approved').get();
    final rejectedDocs = await _evidenceCollection.where('status', isEqualTo: 'rejected').get();

    final evidenceList = allDocs.docs
        .map((doc) => EvidenceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    final kategoriStats = <String, int>{};
    final lokasiStats = <String, int>{};

    for (final evidence in evidenceList) {
      final kategori = evidence.kategoriDisplayName;
      final lokasi = evidence.lokasiName;

      kategoriStats[kategori] = (kategoriStats[kategori] ?? 0) + 1;
      lokasiStats[lokasi] = (lokasiStats[lokasi] ?? 0) + 1;
    }

    return {
      'total': allDocs.docs.length,
      'pending': pendingDocs.docs.length,
      'approved': approvedDocs.docs.length,
      'rejected': rejectedDocs.docs.length,
      'byKategori': kategoriStats,
      'byLokasi': lokasiStats,
    };
  }

  // Get kategori evidence options
  static List<String> getKategoriEvidenceOptions() {
    return KategoriEvidence.values.map((kategori) {
      switch (kategori) {
        case KategoriEvidence.foto:
          return 'Foto';
        case KategoriEvidence.video:
          return 'Video';
        case KategoriEvidence.dokumen:
          return 'Dokumen';
        case KategoriEvidence.lainnya:
          return 'Lainnya';
      }
    }).toList();
  }

  // Validate file type based on kategori
  static bool isValidFileType(File file, KategoriEvidence kategori) {
    final extension = file.path.split('.').last.toLowerCase();
    
    switch (kategori) {
      case KategoriEvidence.foto:
        return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
      case KategoriEvidence.video:
        return ['mp4', 'avi', 'mov', 'mkv', '3gp', 'webm'].contains(extension);
      case KategoriEvidence.dokumen:
        return ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'].contains(extension);
      case KategoriEvidence.lainnya:
        return true; // Allow any file type
    }
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is valid (max 50MB)
  static bool isValidFileSize(File file) {
    return getFileSizeInMB(file) <= 50;
  }
}