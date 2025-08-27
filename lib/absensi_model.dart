import 'package:flutter/material.dart';

enum StatusAbsensi {
  hadir,
  izin,
  sakit,
  alpha,
}

class AbsensiModel {
  final String absensiId;
  final String bawahanId;
  final String bawahanName;
  final String koordinatorId;
  final String koordinatorName;
  final String lokasiId;
  final String lokasiName;
  final DateTime tanggal;
  final StatusAbsensi status;
  final String? keterangan;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AbsensiModel({
    required this.absensiId,
    required this.bawahanId,
    required this.bawahanName,
    required this.koordinatorId,
    required this.koordinatorName,
    required this.lokasiId,
    required this.lokasiName,
    required this.tanggal,
    required this.status,
    this.keterangan,
    required this.createdAt,
    this.updatedAt,
  });

  factory AbsensiModel.fromMap(Map<String, dynamic> map, String id) {
    return AbsensiModel(
      absensiId: id,
      bawahanId: map['bawahan_id'] ?? '',
      bawahanName: map['bawahan_name'] ?? '',
      koordinatorId: map['koordinator_id'] ?? '',
      koordinatorName: map['koordinator_name'] ?? '',
      lokasiId: map['lokasi_id'] ?? '',
      lokasiName: map['lokasi_name'] ?? '',
      tanggal: map['tanggal']?.toDate() ?? DateTime.now(),
      status: StatusAbsensi.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => StatusAbsensi.alpha,
      ),
      keterangan: map['keterangan'],
      createdAt: map['created_at']?.toDate() ?? DateTime.now(),
      updatedAt: map['updated_at']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bawahan_id': bawahanId,
      'bawahan_name': bawahanName,
      'koordinator_id': koordinatorId,
      'koordinator_name': koordinatorName,
      'lokasi_id': lokasiId,
      'lokasi_name': lokasiName,
      'tanggal': tanggal,
      'status': status.toString().split('.').last,
      'keterangan': keterangan,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  String get statusDisplayName {
    switch (status) {
      case StatusAbsensi.hadir:
        return 'Hadir';
      case StatusAbsensi.izin:
        return 'Izin';
      case StatusAbsensi.sakit:
        return 'Sakit';
      case StatusAbsensi.alpha:
        return 'Alpha';
    }
  }

  Color get statusColor {
    switch (status) {
      case StatusAbsensi.hadir:
        return Colors.green;
      case StatusAbsensi.izin:
        return Colors.blue;
      case StatusAbsensi.sakit:
        return Colors.orange;
      case StatusAbsensi.alpha:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (status) {
      case StatusAbsensi.hadir:
        return Icons.check_circle;
      case StatusAbsensi.izin:
        return Icons.info;
      case StatusAbsensi.sakit:
        return Icons.local_hospital;
      case StatusAbsensi.alpha:
        return Icons.cancel;
    }
  }

  String get formattedTanggal {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year}';
  }

  String get formattedDateTime {
    return '${tanggal.day}/${tanggal.month}/${tanggal.year} ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  AbsensiModel copyWith({
    String? absensiId,
    String? bawahanId,
    String? bawahanName,
    String? koordinatorId,
    String? koordinatorName,
    String? lokasiId,
    String? lokasiName,
    DateTime? tanggal,
    StatusAbsensi? status,
    String? keterangan,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AbsensiModel(
      absensiId: absensiId ?? this.absensiId,
      bawahanId: bawahanId ?? this.bawahanId,
      bawahanName: bawahanName ?? this.bawahanName,
      koordinatorId: koordinatorId ?? this.koordinatorId,
      koordinatorName: koordinatorName ?? this.koordinatorName,
      lokasiId: lokasiId ?? this.lokasiId,
      lokasiName: lokasiName ?? this.lokasiName,
      tanggal: tanggal ?? this.tanggal,
      status: status ?? this.status,
      keterangan: keterangan ?? this.keterangan,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}