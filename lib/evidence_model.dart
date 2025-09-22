import 'package:flutter/material.dart';

enum KategoriEvidence {
  foto,
  video,
  dokumen,
  lainnya,
}

enum StatusEvidence {
  pending,
  approved,
  rejected,
}

class EvidenceModel {
  final String evidenceId;
  final String uploadedBy;
  final String uploaderName;
  final String lokasiId;
  final String lokasiName;
  final String projectId; // Tambahan field untuk proyek
  final KategoriEvidence kategori;
  final String fileUrl;
  final String? description;
  final StatusEvidence status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  EvidenceModel({
    required this.evidenceId,
    required this.uploadedBy,
    required this.uploaderName,
    required this.lokasiId,
    required this.lokasiName,
    required this.projectId, // Required field
    required this.kategori,
    required this.fileUrl,
    required this.createdAt,
    this.description,
    this.status = StatusEvidence.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  factory EvidenceModel.fromMap(Map<String, dynamic> map, String id) {
    return EvidenceModel(
      evidenceId: id,
      uploadedBy: map['uploaded_by'] ?? '',
      uploaderName: map['uploader_name'] ?? '',
      lokasiId: map['lokasi_id'] ?? '',
      lokasiName: map['lokasi_name'] ?? '',
      projectId: map['project_id'] ?? '', // Handle legacy data
      kategori: KategoriEvidence.values.firstWhere(
        (e) => e.toString().split('.').last == map['kategori'],
        orElse: () => KategoriEvidence.lainnya,
      ),
      fileUrl: map['file_url'] ?? '',
      description: map['description'],
      status: StatusEvidence.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusEvidence.pending,
      ),
      approvedBy: map['approved_by'],
      approvedAt: map['approved_at']?.toDate(),
      rejectionReason: map['rejection_reason'],
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uploaded_by': uploadedBy,
      'uploader_name': uploaderName,
      'lokasi_id': lokasiId,
      'lokasi_name': lokasiName,
      'project_id': projectId, // Include projectId
      'kategori': kategori.toString().split('.').last,
      'file_url': fileUrl,
      'description': description,
      'status': status.toString().split('.').last,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
    };
  }

  String get kategoriDisplayName {
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
  }

  String get statusDisplayName {
    switch (status) {
      case StatusEvidence.pending:
        return 'Pending';
      case StatusEvidence.approved:
        return 'Approved';
      case StatusEvidence.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case StatusEvidence.pending:
        return Colors.orange;
      case StatusEvidence.approved:
        return Colors.green;
      case StatusEvidence.rejected:
        return Colors.red;
    }
  }

  IconData get kategoriIcon {
    switch (kategori) {
      case KategoriEvidence.foto:
        return Icons.photo;
      case KategoriEvidence.video:
        return Icons.videocam;
      case KategoriEvidence.dokumen:
        return Icons.description;
      case KategoriEvidence.lainnya:
        return Icons.folder;
    }
  }

  Color get kategoriColor {
    switch (kategori) {
      case KategoriEvidence.foto:
        return Colors.blue;
      case KategoriEvidence.video:
        return Colors.red;
      case KategoriEvidence.dokumen:
        return Colors.green;
      case KategoriEvidence.lainnya:
        return Colors.grey;
    }
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  bool get isImage => kategori == KategoriEvidence.foto;
  bool get isVideo => kategori == KategoriEvidence.video;
  bool get isDocument => kategori == KategoriEvidence.dokumen;

  EvidenceModel copyWith({
    String? evidenceId,
    String? uploadedBy,
    String? uploaderName,
    String? lokasiId,
    String? lokasiName,
    String? projectId,
    KategoriEvidence? kategori,
    String? fileUrl,
    String? description,
    StatusEvidence? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return EvidenceModel(
      evidenceId: evidenceId ?? this.evidenceId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploaderName: uploaderName ?? this.uploaderName,
      lokasiId: lokasiId ?? this.lokasiId,
      lokasiName: lokasiName ?? this.lokasiName,
      projectId: projectId ?? this.projectId,
      kategori: kategori ?? this.kategori,
      fileUrl: fileUrl ?? this.fileUrl,
      description: description ?? this.description,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}