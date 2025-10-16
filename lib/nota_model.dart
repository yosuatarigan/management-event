import 'package:flutter/material.dart';

enum StatusNota {
  pending,
  approved,
  rejected,
  reimbursed,
}

class NotaModel {
  final String notaId;
  final String projectId;
  final String koordinatorId;
  final String koordinatorName;
  final String lokasiId;
  final String lokasiName;
  final String jenis;
  final DateTime tanggal;
  final double nominal;
  final String keperluan;
  final String fotoNotaUrl;
  final StatusNota status;
  final String? approvedBy;
  final String? approverName;
  final DateTime? approvedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  NotaModel({
    required this.notaId,
    required this.projectId,
    required this.koordinatorId,
    required this.koordinatorName,
    required this.lokasiId,
    required this.lokasiName,
    required this.jenis,
    required this.tanggal,
    required this.nominal,
    required this.keperluan,
    required this.fotoNotaUrl,
    required this.createdAt,
    this.status = StatusNota.pending,
    this.approvedBy,
    this.approverName,
    this.approvedAt,
    this.rejectionReason,
  });

  factory NotaModel.fromMap(Map<String, dynamic> map, String id) {
    return NotaModel(
      notaId: id,
      projectId: map['project_id'] ?? '',
      koordinatorId: map['koordinator_id'] ?? '',
      koordinatorName: map['koordinator_name'] ?? '',
      lokasiId: map['lokasi_id'] ?? '',
      lokasiName: map['lokasi_name'] ?? '',
      jenis: map['jenis'] ?? 'Lain-lain',
      tanggal: map['tanggal']?.toDate() ?? DateTime.now(),
      nominal: (map['nominal'] ?? 0).toDouble(),
      keperluan: map['keperluan'] ?? '',
      fotoNotaUrl: map['foto_nota_url'] ?? '',
      status: StatusNota.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusNota.pending,
      ),
      approvedBy: map['approved_by'],
      approverName: map['approver_name'],
      approvedAt: map['approved_at']?.toDate(),
      rejectionReason: map['rejection_reason'],
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'project_id': projectId,
      'koordinator_id': koordinatorId,
      'koordinator_name': koordinatorName,
      'lokasi_id': lokasiId,
      'lokasi_name': lokasiName,
      'jenis': jenis,
      'tanggal': tanggal,
      'nominal': nominal,
      'keperluan': keperluan,
      'foto_nota_url': fotoNotaUrl,
      'status': status.toString().split('.').last,
      'approved_by': approvedBy,
      'approver_name': approverName,
      'approved_at': approvedAt,
      'rejection_reason': rejectionReason,
      'created_at': createdAt,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case StatusNota.pending:
        return 'Pending';
      case StatusNota.approved:
        return 'Approved';
      case StatusNota.rejected:
        return 'Rejected';
      case StatusNota.reimbursed:
        return 'Reimbursed';
    }
  }

  Color get statusColor {
    switch (status) {
      case StatusNota.pending:
        return Colors.orange;
      case StatusNota.approved:
        return Colors.green;
      case StatusNota.rejected:
        return Colors.red;
      case StatusNota.reimbursed:
        return Colors.blue;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case StatusNota.pending:
        return Icons.pending;
      case StatusNota.approved:
        return Icons.check_circle;
      case StatusNota.rejected:
        return Icons.cancel;
      case StatusNota.reimbursed:
        return Icons.account_balance_wallet;
    }
  }

  String get formattedNominal {
    return 'Rp ${nominal.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    )}';
  }

  String get formattedTanggal {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  String get formattedDate {
    return '${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  NotaModel copyWith({
    String? notaId,
    String? projectId,
    String? koordinatorId,
    String? koordinatorName,
    String? lokasiId,
    String? lokasiName,
    String? jenis,
    DateTime? tanggal,
    double? nominal,
    String? keperluan,
    String? fotoNotaUrl,
    StatusNota? status,
    String? approvedBy,
    String? approverName,
    DateTime? approvedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return NotaModel(
      notaId: notaId ?? this.notaId,
      projectId: projectId ?? this.projectId,
      koordinatorId: koordinatorId ?? this.koordinatorId,
      koordinatorName: koordinatorName ?? this.koordinatorName,
      lokasiId: lokasiId ?? this.lokasiId,
      lokasiName: lokasiName ?? this.lokasiName,
      jenis: jenis ?? this.jenis,
      tanggal: tanggal ?? this.tanggal,
      nominal: nominal ?? this.nominal,
      keperluan: keperluan ?? this.keperluan,
      fotoNotaUrl: fotoNotaUrl ?? this.fotoNotaUrl,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      approverName: approverName ?? this.approverName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}