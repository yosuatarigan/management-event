import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nota_model.dart';

class NotaService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final CollectionReference _notaCollection = _firestore.collection('nota_pengeluaran');

  // Get all nota
  static Stream<List<NotaModel>> getAllNota() {
    return _notaCollection
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get nota by coordinator
  static Stream<List<NotaModel>> getNotaByCoordinator(String coordinatorId) {
    return _notaCollection
        .where('koordinator_id', isEqualTo: coordinatorId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Get nota by status
  static Stream<List<NotaModel>> getNotaByStatus(StatusNota status) {
    return _notaCollection
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Create nota
  static Future<void> createNota(NotaModel nota) async {
    final docRef = _notaCollection.doc();
    final notaWithId = nota.copyWith(notaId: docRef.id);
    await docRef.set(notaWithId.toMap());
  }

  // Update nota
  static Future<void> updateNota(String id, NotaModel nota) async {
    await _notaCollection.doc(id).update(nota.toMap());
  }

  // Delete nota
  static Future<void> deleteNota(String id) async {
    // Get the document first to delete associated photo
    final doc = await _notaCollection.doc(id).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final fotoUrl = data['foto_nota_url'] as String?;
      
      // Delete photo from storage
      if (fotoUrl != null && fotoUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(fotoUrl).delete();
        } catch (e) {
          print('Error deleting photo: $e');
        }
      }
    }
    
    await _notaCollection.doc(id).delete();
  }

  // Get nota by ID
  static Future<NotaModel?> getNotaById(String id) async {
    final doc = await _notaCollection.doc(id).get();
    if (!doc.exists) return null;

    return NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // Upload photo to Firebase Storage
  static Future<String> uploadPhoto(File photo, String notaId) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final String extension = photo.path.split('.').last.toLowerCase();
      final String fullFileName = '${fileName}.$extension';
      
      final Reference ref = _storage
          .ref()
          .child('nota_pengeluaran')
          .child(notaId)
          .child(fullFileName);

      final UploadTask uploadTask = ref.putFile(photo);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Error uploading photo: $e');
    }
  }

  // Approve nota
  static Future<void> approveNota(String notaId, String approverId, String approverName) async {
    await _notaCollection.doc(notaId).update({
      'status': StatusNota.approved.toString().split('.').last,
      'approved_by': approverId,
      'approver_name': approverName,
      'approved_at': DateTime.now(),
    });
  }

  // Reject nota
  static Future<void> rejectNota(String notaId, String approverId, String approverName, String reason) async {
    await _notaCollection.doc(notaId).update({
      'status': StatusNota.rejected.toString().split('.').last,
      'approved_by': approverId,
      'approver_name': approverName,
      'approved_at': DateTime.now(),
      'rejection_reason': reason,
    });
  }

  // Mark as reimbursed
  static Future<void> markAsReimbursed(String notaId) async {
    await _notaCollection.doc(notaId).update({
      'status': StatusNota.reimbursed.toString().split('.').last,
    });
  }

  // Get current user nota
  static Stream<List<NotaModel>> getCurrentUserNota() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return getNotaByCoordinator(currentUser.uid);
  }

  // Get statistics
  static Future<Map<String, dynamic>> getNotaStats() async {
    final allDocs = await _notaCollection.get();
    final pendingDocs = await _notaCollection.where('status', isEqualTo: 'pending').get();
    final approvedDocs = await _notaCollection.where('status', isEqualTo: 'approved').get();
    final rejectedDocs = await _notaCollection.where('status', isEqualTo: 'rejected').get();
    final reimbursedDocs = await _notaCollection.where('status', isEqualTo: 'reimbursed').get();

    final notaList = allDocs.docs
        .map((doc) => NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // Calculate totals
    double totalNominal = 0;
    double pendingTotal = 0;
    double approvedTotal = 0;
    double rejectedTotal = 0;
    double reimbursedTotal = 0;

    final lokasiStats = <String, int>{};

    for (final nota in notaList) {
      totalNominal += nota.nominal;
      final lokasi = nota.lokasiName;
      lokasiStats[lokasi] = (lokasiStats[lokasi] ?? 0) + 1;

      switch (nota.status) {
        case StatusNota.pending:
          pendingTotal += nota.nominal;
          break;
        case StatusNota.approved:
          approvedTotal += nota.nominal;
          break;
        case StatusNota.rejected:
          rejectedTotal += nota.nominal;
          break;
        case StatusNota.reimbursed:
          reimbursedTotal += nota.nominal;
          break;
      }
    }

    return {
      'total_count': allDocs.docs.length,
      'pending_count': pendingDocs.docs.length,
      'approved_count': approvedDocs.docs.length,
      'rejected_count': rejectedDocs.docs.length,
      'reimbursed_count': reimbursedDocs.docs.length,
      'total_nominal': totalNominal,
      'pending_total': pendingTotal,
      'approved_total': approvedTotal,
      'rejected_total': rejectedTotal,
      'reimbursed_total': reimbursedTotal,
      'by_lokasi': lokasiStats,
    };
  }

  // Validate photo
  static bool isValidPhoto(File photo) {
    final extension = photo.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
  }

  // Get file size in MB
  static double getFileSizeInMB(File file) {
    final bytes = file.lengthSync();
    return bytes / (1024 * 1024);
  }

  // Check if file size is valid (max 10MB for photos)
  static bool isValidFileSize(File file) {
    return getFileSizeInMB(file) <= 10;
  }

  // Get monthly stats
  static Future<Map<String, dynamic>> getMonthlyStats(int year, int month) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 1);

    final monthlyDocs = await _notaCollection
        .where('tanggal', isGreaterThanOrEqualTo: startDate)
        .where('tanggal', isLessThan: endDate)
        .get();

    final notaList = monthlyDocs.docs
        .map((doc) => NotaModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    double totalSpent = 0;
    int totalNota = notaList.length;
    
    for (final nota in notaList) {
      if (nota.status == StatusNota.approved || nota.status == StatusNota.reimbursed) {
        totalSpent += nota.nominal;
      }
    }

    return {
      'month': month,
      'year': year,
      'total_nota': totalNota,
      'total_spent': totalSpent,
      'nota_list': notaList,
    };
  }
}