class BAUjiFungsi {
  final String nomorBA;
  final String hari;
  final String tanggal;
  final String bulan;
  final String tilok;
  final String alamat;
  final int jumlahPeserta; // 100, 200, 300, 400, 500
  
  // Laptop Client Ujian
  final List<String> laptopClientIds;
  
  // Laptop Backup/Cadangan
  final List<String> laptopBackupIds;
  
  // Peralatan lainnya (B1-B39)
  final Map<String, String> peralatan; // key: B1, B2, dll, value: status (✓ atau -)
  
  // Tanda tangan
  final String koordinator;
  final String pengawas;
  final String nipPengawas;

  BAUjiFungsi({
    required this.nomorBA,
    required this.hari,
    required this.tanggal,
    required this.bulan,
    required this.tilok,
    required this.alamat,
    required this.jumlahPeserta,
    required this.laptopClientIds,
    required this.laptopBackupIds,
    required this.peralatan,
    required this.koordinator,
    required this.pengawas,
    required this.nipPengawas,
  });

  Map<String, dynamic> toMap() {
    return {
      'nomorBA': nomorBA,
      'hari': hari,
      'tanggal': tanggal,
      'bulan': bulan,
      'tilok': tilok,
      'alamat': alamat,
      'jumlahPeserta': jumlahPeserta,
      'laptopClientIds': laptopClientIds,
      'laptopBackupIds': laptopBackupIds,
      'peralatan': peralatan,
      'koordinator': koordinator,
      'pengawas': pengawas,
      'nipPengawas': nipPengawas,
    };
  }

  factory BAUjiFungsi.fromMap(Map<String, dynamic> map) {
    return BAUjiFungsi(
      nomorBA: map['nomorBA'] ?? '',
      hari: map['hari'] ?? '',
      tanggal: map['tanggal'] ?? '',
      bulan: map['bulan'] ?? '',
      tilok: map['tilok'] ?? '',
      alamat: map['alamat'] ?? '',
      jumlahPeserta: map['jumlahPeserta'] ?? 100,
      laptopClientIds: List<String>.from(map['laptopClientIds'] ?? []),
      laptopBackupIds: List<String>.from(map['laptopBackupIds'] ?? []),
      peralatan: Map<String, String>.from(map['peralatan'] ?? {}),
      koordinator: map['koordinator'] ?? '',
      pengawas: map['pengawas'] ?? '',
      nipPengawas: map['nipPengawas'] ?? '',
    );
  }
}