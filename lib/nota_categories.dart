import 'package:flutter/material.dart';

class NotaCategories {
  static const List<String> jenisNota = [
    'Lain-lain',
    'Hotel per Kamar',
    'Tiket Pesawat PP',
    'Pembelian ATK',
    'Transport dari/ke Rumah',
    'Biaya Kirim Dokumen',
    'Fuel',
    'Sewa Mobil',
  ];

  // Get color for jenis nota (optional - untuk badge)
  static Map<String, dynamic> getJenisStyle(String jenis) {
    switch (jenis) {
      case 'Lain-lain':
        return {'color': Colors.grey, 'icon': Icons.more_horiz};
      case 'Hotel per Kamar':
        return {'color': Colors.blue, 'icon': Icons.hotel};
      case 'Tiket Pesawat PP':
        return {'color': Colors.pink, 'icon': Icons.flight};
      case 'Pembelian ATK':
        return {'color': Colors.grey.shade700, 'icon': Icons.inventory};
      case 'Transport dari/ke Rumah':
        return {'color': Colors.red, 'icon': Icons.directions_car};
      case 'Biaya Kirim Dokumen':
        return {'color': Colors.purple, 'icon': Icons.local_shipping};
      case 'Fuel':
        return {'color': Colors.amber, 'icon': Icons.local_gas_station};
      case 'Sewa Mobil':
        return {'color': Colors.brown, 'icon': Icons.car_rental};
      default:
        return {'color': Colors.grey, 'icon': Icons.receipt};
    }
  }
}