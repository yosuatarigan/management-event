class BAPerubahanVolume {
  String? id;
  String tilok;
  String alamat;
  int peserta;
  String hari;
  String tanggal;
  String bulan;
  String koordinator;
  String pengawas;
  String nipPengawas;
  
  // Tenda Semi Dekor
  int b30l; // kontrak/lama
  int b30b; // baru/terpasang
  String k1; // keterangan
  
  // Tenda Sarnafil
  int b32l;
  int b32b;
  String k2;
  
  // AC Standing
  int b36l;
  int b36b;
  String k3;
  
  // Misty Fan
  int b38l;
  int b38b;
  String k4;
  
  DateTime createdAt;

  BAPerubahanVolume({
    this.id,
    required this.tilok,
    required this.alamat,
    required this.peserta,
    required this.hari,
    required this.tanggal,
    required this.bulan,
    required this.koordinator,
    required this.pengawas,
    required this.nipPengawas,
    required this.b30l, required this.b30b, required this.k1,
    required this.b32l, required this.b32b, required this.k2,
    required this.b36l, required this.b36b, required this.k3,
    required this.b38l, required this.b38b, required this.k4,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'tilok': tilok,
      'alamat': alamat,
      'peserta': peserta,
      'hari': hari,
      'tanggal': tanggal,
      'bulan': bulan,
      'koordinator': koordinator,
      'pengawas': pengawas,
      'nipPengawas': nipPengawas,
      'b30l': b30l, 'b30b': b30b, 'k1': k1,
      'b32l': b32l, 'b32b': b32b, 'k2': k2,
      'b36l': b36l, 'b36b': b36b, 'k3': k3,
      'b38l': b38l, 'b38b': b38b, 'k4': k4,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BAPerubahanVolume.fromMap(String id, Map<String, dynamic> map) {
    return BAPerubahanVolume(
      id: id,
      tilok: map['tilok'] ?? '',
      alamat: map['alamat'] ?? '',
      peserta: map['peserta'] ?? 0,
      hari: map['hari'] ?? '',
      tanggal: map['tanggal'] ?? '',
      bulan: map['bulan'] ?? '',
      koordinator: map['koordinator'] ?? '',
      pengawas: map['pengawas'] ?? '',
      nipPengawas: map['nipPengawas'] ?? '',
      b30l: map['b30l'] ?? 0, b30b: map['b30b'] ?? 0, k1: map['k1'] ?? '',
      b32l: map['b32l'] ?? 0, b32b: map['b32b'] ?? 0, k2: map['k2'] ?? '',
      b36l: map['b36l'] ?? 0, b36b: map['b36b'] ?? 0, k3: map['k3'] ?? '',
      b38l: map['b38l'] ?? 0, b38b: map['b38b'] ?? 0, k4: map['k4'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}