enum UserRole { admin, koordinator, approver, bawahan }

class UserModel {
  final String id;
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String? locationId; // Tambahan field untuk lokasi

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.locationId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      password: map['password'] ?? '',
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString().split('.').last == map['role'],
        orElse: () => UserRole.bawahan,
      ),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      locationId: map['locationId'], // Tambahan parsing locationId
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'password': password,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'createdAt': createdAt,
      'isActive': isActive,
      'locationId': locationId, // Tambahan untuk save locationId
    };
  }

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.koordinator:
        return 'Koordinator';
      case UserRole.approver:
        return 'Approver';
      case UserRole.bawahan:
        return 'Bawahan';
    }
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    DateTime? createdAt,
    bool? isActive,
    String? password,
    String? locationId,
  }) {
    return UserModel(
      password: password ?? this.password,
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      locationId: locationId ?? this.locationId, // Tambahan untuk copyWith locationId
    );
  }
}