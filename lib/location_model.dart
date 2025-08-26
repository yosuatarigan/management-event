class LocationModel {
  final String id;
  final String name;
  final String address;
  final String city;
  final String province;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  LocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.province,
    required this.createdAt,
    required this.updatedAt,
    this.description,
  });

  factory LocationModel.fromMap(Map<String, dynamic> map, String id) {
    return LocationModel(
      id: id,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      province: map['province'] ?? '',
      description: map['description'],
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'province': province,
      'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  String get fullAddress {
    return '$address, $city, $province';
  }

  String get shortLocation {
    return '$city, $province';
  }

  LocationModel copyWith({
    String? id,
    String? name,
    String? address,
    String? city,
    String? province,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      province: province ?? this.province,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}