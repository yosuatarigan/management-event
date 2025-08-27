import 'package:flutter/material.dart';

enum JenisBA {
  pembukaan,
  kendala,
  penutupan,
  monitoring,
  evaluasi,
  lainnya,
}

enum StatusBA {
  pending,
  approved,
  rejected,
}

class BeritaAcaraModel {
  final String baId;
  final String koordinatorId;
  final String koordinatorName;
  final String lokasiId;
  final String lokasiName;
  final JenisBA jenisBA;
  final String isiBA;
  final List<String> lampiranUrls;
  final StatusBA status;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime updatedAt;

  BeritaAcaraModel({
    required this.baId,
    required this.koordinatorId,
    required this.koordinatorName,
    required this.lokasiId,
    required this.lokasiName,
    required this.jenisBA,
    required this.isiBA,
    required this.createdAt,
    required this.updatedAt,
    this.lampiranUrls = const [],
    this.status = StatusBA.pending,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
  });

  factory BeritaAcaraModel.fromMap(Map<String, dynamic> map, String id) {
    return BeritaAcaraModel(
      baId: id,
      koordinatorId: map['koordinator_id'] ?? '',
      koordinatorName: map['koordinator_name'] ?? '',
      lokasiId: map['lokasi_id'] ?? '',
      lokasiName: map['lokasi_name'] ?? '',
      jenisBA: JenisBA.values.firstWhere(
        (e) => e.toString().split('.').last == map['jenis_ba'],
        orElse: () => JenisBA.lainnya,
      ),
      isiBA: map['isi_ba'] ?? '',
      lampiranUrls: List<String>.from(map['lampiran_urls'] ?? []),
      status: StatusBA.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusBA.pending,
      ),
      approvedBy: map['approved_by'],
      approvedAt: map['approved_at']?.toDate(),
      rejectionReason: map['rejection_reason'],
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'koordinator_id': koordinatorId,
      'koordinator_name': koordinatorName,
      'lokasi_id': lokasiId,
      'lokasi_name': lokasiName,
      'jenis_ba': jenisBA.toString().split('.').last,
      'isi_ba': isiBA,
      'lampiran_urls': lampiranUrls,
      'status': status.toString().split('.').last,
      'approved_by': approvedBy,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get jenisBADisplayName {
    switch (jenisBA) {
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
  }

  String get statusDisplayName {
    switch (status) {
      case StatusBA.pending:
        return 'Pending';
      case StatusBA.approved:
        return 'Approved';
      case StatusBA.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (status) {
      case StatusBA.pending:
        return Colors.orange;
      case StatusBA.approved:
        return Colors.green;
      case StatusBA.rejected:
        return Colors.red;
    }
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  BeritaAcaraModel copyWith({
    String? baId,
    String? koordinatorId,
    String? koordinatorName,
    String? lokasiId,
    String? lokasiName,
    JenisBA? jenisBA,
    String? isiBA,
    List<String>? lampiranUrls,
    StatusBA? status,
    String? approvedBy,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BeritaAcaraModel(
      baId: baId ?? this.baId,
      koordinatorId: koordinatorId ?? this.koordinatorId,
      koordinatorName: koordinatorName ?? this.koordinatorName,
      lokasiId: lokasiId ?? this.lokasiId,
      lokasiName: lokasiName ?? this.lokasiName,
      jenisBA: jenisBA ?? this.jenisBA,
      isiBA: isiBA ?? this.isiBA,
      lampiranUrls: lampiranUrls ?? this.lampiranUrls,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}