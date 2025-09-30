class BADismantle {
  String? id;
  String tilok;
  String alamat;
  int peserta;
  int cadangan;
  String hari;
  String tanggal;
  String bulan;
  String koordinator;
  String pengawas;
  String nipPengawas;
  
  // Sarana Prasarana quantities
  int b1, b2, b3, b4, b5, b6, b7, b8, b9, b10;
  int b11, b12, b13, b14, b15, b16, b19, b20, b21, b22;
  int b23, b24, b25, b26, b27, b28, b29, b30, b32, b34;
  int b35, b36, b38, b39;
  
  DateTime createdAt;

  BADismantle({
    this.id,
    required this.tilok,
    required this.alamat,
    required this.peserta,
    required this.cadangan,
    required this.hari,
    required this.tanggal,
    required this.bulan,
    required this.koordinator,
    required this.pengawas,
    required this.nipPengawas,
    required this.b1, required this.b2, required this.b3, required this.b4,
    required this.b5, required this.b6, required this.b7, required this.b8,
    required this.b9, required this.b10, required this.b11, required this.b12,
    required this.b13, required this.b14, required this.b15, required this.b16,
    required this.b19, required this.b20, required this.b21, required this.b22,
    required this.b23, required this.b24, required this.b25, required this.b26,
    required this.b27, required this.b28, required this.b29, required this.b30,
    required this.b32, required this.b34, required this.b35, required this.b36,
    required this.b38, required this.b39,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tilok': tilok,
      'alamat': alamat,
      'peserta': peserta,
      'cadangan': cadangan,
      'hari': hari,
      'tanggal': tanggal,
      'bulan': bulan,
      'koordinator': koordinator,
      'pengawas': pengawas,
      'nipPengawas': nipPengawas,
      'b1': b1, 'b2': b2, 'b3': b3, 'b4': b4, 'b5': b5,
      'b6': b6, 'b7': b7, 'b8': b8, 'b9': b9, 'b10': b10,
      'b11': b11, 'b12': b12, 'b13': b13, 'b14': b14, 'b15': b15,
      'b16': b16, 'b19': b19, 'b20': b20, 'b21': b21, 'b22': b22,
      'b23': b23, 'b24': b24, 'b25': b25, 'b26': b26, 'b27': b27,
      'b28': b28, 'b29': b29, 'b30': b30, 'b32': b32, 'b34': b34,
      'b35': b35, 'b36': b36, 'b38': b38, 'b39': b39,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BADismantle.fromMap(String id, Map<String, dynamic> map) {
    return BADismantle(
      id: id,
      tilok: map['tilok'] ?? '',
      alamat: map['alamat'] ?? '',
      peserta: map['peserta'] ?? 0,
      cadangan: map['cadangan'] ?? 0,
      hari: map['hari'] ?? '',
      tanggal: map['tanggal'] ?? '',
      bulan: map['bulan'] ?? '',
      koordinator: map['koordinator'] ?? '',
      pengawas: map['pengawas'] ?? '',
      nipPengawas: map['nipPengawas'] ?? '',
      b1: map['b1'] ?? 0, b2: map['b2'] ?? 0, b3: map['b3'] ?? 0,
      b4: map['b4'] ?? 0, b5: map['b5'] ?? 0, b6: map['b6'] ?? 0,
      b7: map['b7'] ?? 0, b8: map['b8'] ?? 0, b9: map['b9'] ?? 0,
      b10: map['b10'] ?? 0, b11: map['b11'] ?? 0, b12: map['b12'] ?? 0,
      b13: map['b13'] ?? 0, b14: map['b14'] ?? 0, b15: map['b15'] ?? 0,
      b16: map['b16'] ?? 0, b19: map['b19'] ?? 0, b20: map['b20'] ?? 0,
      b21: map['b21'] ?? 0, b22: map['b22'] ?? 0, b23: map['b23'] ?? 0,
      b24: map['b24'] ?? 0, b25: map['b25'] ?? 0, b26: map['b26'] ?? 0,
      b27: map['b27'] ?? 0, b28: map['b28'] ?? 0, b29: map['b29'] ?? 0,
      b30: map['b30'] ?? 0, b32: map['b32'] ?? 0, b34: map['b34'] ?? 0,
      b35: map['b35'] ?? 0, b36: map['b36'] ?? 0, b38: map['b38'] ?? 0,
      b39: map['b39'] ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}