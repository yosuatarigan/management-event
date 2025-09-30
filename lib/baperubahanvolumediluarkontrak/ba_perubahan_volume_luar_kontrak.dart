class ItemPenambahan {
  String deskripsi;
  String jumlah;

  ItemPenambahan({required this.deskripsi, required this.jumlah});

  Map<String, dynamic> toMap() {
    return {'deskripsi': deskripsi, 'jumlah': jumlah};
  }

  factory ItemPenambahan.fromMap(Map<String, dynamic> map) {
    return ItemPenambahan(
      deskripsi: map['deskripsi'] ?? '',
      jumlah: map['jumlah'] ?? '',
    );
  }
}

class BAPerubahanVolumeLuarKontrak {
  String? id;
  String nomorBA;
  String hari;
  String tanggal;
  String bulan;
  String namaPihakPertama;
  String nipPihakPertama;
  String jabatanPihakPertama;
  String namaPihakKedua;
  String jabatanPihakKedua;
  String tilok;
  List<ItemPenambahan> items;
  DateTime createdAt;

  BAPerubahanVolumeLuarKontrak({
    this.id,
    required this.nomorBA,
    required this.hari,
    required this.tanggal,
    required this.bulan,
    required this.namaPihakPertama,
    required this.nipPihakPertama,
    required this.jabatanPihakPertama,
    required this.namaPihakKedua,
    required this.jabatanPihakKedua,
    required this.tilok,
    required this.items,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'nomorBA': nomorBA,
      'hari': hari,
      'tanggal': tanggal,
      'bulan': bulan,
      'namaPihakPertama': namaPihakPertama,
      'nipPihakPertama': nipPihakPertama,
      'jabatanPihakPertama': jabatanPihakPertama,
      'namaPihakKedua': namaPihakKedua,
      'jabatanPihakKedua': jabatanPihakKedua,
      'tilok': tilok,
      'items': items.map((item) => item.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory BAPerubahanVolumeLuarKontrak.fromMap(String id, Map<String, dynamic> map) {
    return BAPerubahanVolumeLuarKontrak(
      id: id,
      nomorBA: map['nomorBA'] ?? '',
      hari: map['hari'] ?? '',
      tanggal: map['tanggal'] ?? '',
      bulan: map['bulan'] ?? '',
      namaPihakPertama: map['namaPihakPertama'] ?? '',
      nipPihakPertama: map['nipPihakPertama'] ?? '',
      jabatanPihakPertama: map['jabatanPihakPertama'] ?? '',
      namaPihakKedua: map['namaPihakKedua'] ?? '',
      jabatanPihakKedua: map['jabatanPihakKedua'] ?? '',
      tilok: map['tilok'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => ItemPenambahan.fromMap(item))
              .toList() ??
          [],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
    );
  }
}