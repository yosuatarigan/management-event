enum UserRole { admin, koordinator, approver, bawahan }

class UserModel {
  final String id;
  final String email;
  final String password;
  final String name;
  final UserRole role;
  final DateTime createdAt;
  final bool isActive;
  final String? locationId;
  final List<String> projectIds; // Multi-project support
  final bool needsMigration; // Flag untuk user lama yang belum di-assign

  UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.locationId,
    this.projectIds = const [], // Default empty array
    this.needsMigration = false, // Default false untuk user baru
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    // Parse role first
    UserRole role = UserRole.values.firstWhere(
      (e) => e.toString().split('.').last == map['role'],
      orElse: () => UserRole.bawahan,
    );

    // Handle backward compatibility untuk user lama
    List<String> projectIds = [];
    bool needsMigration = false;

    if (map.containsKey('projectIds') && map['projectIds'] != null) {
      // User baru dengan multi-project support
      projectIds = List<String>.from(map['projectIds']);
    } else if (map.containsKey('projectId') && map['projectId'] != null) {
      // User dengan single projectId lama, convert ke array
      projectIds = [map['projectId']];
    } else {
      // User lama tanpa project assignment, perlu migration
      // KECUALI jika user adalah admin
      if (role != UserRole.admin) {
        needsMigration = true;
      }
    }

    // Override needsMigration dari database jika ada
    if (map.containsKey('needsMigration')) {
      needsMigration = map['needsMigration'] ?? needsMigration;
    }

    return UserModel(
      password: map['password'] ?? '',
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: role,
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      locationId: map['locationId'],
      projectIds: projectIds,
      needsMigration: needsMigration,
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
      'locationId': locationId,
      'projectIds': projectIds, // Simpan sebagai array
      'needsMigration': needsMigration,
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

  // Check if user is admin
  bool get isAdmin => role == UserRole.admin;

  // Check if user can access project
  bool canAccessProject(String? targetProjectId) {
    // Admin can access any project
    if (isAdmin) return true;
    
    // User yang perlu migration tidak bisa akses project apapun
    if (needsMigration) return false;
    
    // Check if user is assigned to target project
    return projectIds.contains(targetProjectId);
  }

  // Check if user is assigned to any project
  bool get hasProjectAssignment => projectIds.isNotEmpty;

  // Get project names display
  String getProjectsDisplay(List<String> allProjectNames) {
    if (isAdmin) return 'All Projects';
    if (needsMigration) return 'Need Assignment';
    if (projectIds.isEmpty) return 'No Projects';
    
    if (allProjectNames.length <= 2) {
      return allProjectNames.join(', ');
    } else {
      return '${allProjectNames.take(2).join(', ')} +${allProjectNames.length - 2} more';
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
    List<String>? projectIds,
    bool? needsMigration,
  }) {
    return UserModel(
      password: password ?? this.password,
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      locationId: locationId ?? this.locationId,
      projectIds: projectIds ?? this.projectIds,
      needsMigration: needsMigration ?? this.needsMigration,
    );
  }

  // Helper method untuk assign user ke project
  UserModel assignToProject(String projectId) {
    if (projectIds.contains(projectId)) return this;
    
    List<String> newProjectIds = List<String>.from(projectIds);
    newProjectIds.add(projectId);
    
    return copyWith(
      projectIds: newProjectIds,
      needsMigration: false, // Set migration selesai
    );
  }

  // Helper method untuk remove user dari project
  UserModel removeFromProject(String projectId) {
    if (!projectIds.contains(projectId)) return this;
    
    List<String> newProjectIds = List<String>.from(projectIds);
    newProjectIds.remove(projectId);
    
    return copyWith(projectIds: newProjectIds);
  }
}