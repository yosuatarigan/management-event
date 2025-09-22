import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'project_service.dart';
import 'project_model.dart';
import 'user_migration_dashboard.dart';

class UserManagementPage extends StatefulWidget {
  @override
  _UserManagementPageState createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final _searchController = TextEditingController();
  UserRole? _selectedRoleFilter;
  String _searchQuery = '';
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Management'),
        elevation: 0,
        actions: [
          // Migration Dashboard Button
          StreamBuilder<List<UserModel>>(
            stream: UserService.getUsersNeedingMigration(),
            builder: (context, snapshot) {
              int migrationCount = snapshot.data?.length ?? 0;
              
              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserMigrationDashboard(),
                        ),
                      );
                    },
                    icon: Icon(Icons. sync_alt),
                    tooltip: 'User Migration',
                  ),
                  if (migrationCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$migrationCount',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            onPressed: _selectedProjectId != null ? _showAddUserDialog : null,
            icon: Icon(Icons.person_add),
            tooltip: 'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Selector
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Proyek',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showCopyUsersDialog(),
                      icon: Icon(Icons.copy, size: 16),
                      label: Text('Copy Users'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                StreamBuilder<List<ProjectModel>>(
                  stream: ProjectService.getProjects(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final projects = snapshot.data!;
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: InputDecoration(
                        labelText: 'Proyek',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.folder_special),
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem<String>(
                          value: project.id,
                          child: Text(project.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                          _searchQuery = '';
                          _selectedRoleFilter = null;
                        });
                        _searchController.clear();
                      },
                      hint: Text('Pilih proyek untuk mengelola user'),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search and Filter Section (only show when project selected)
          if (_selectedProjectId != null)
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                  SizedBox(height: 12),
                  // Role Filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRoleChip('All', null),
                        SizedBox(width: 8),
                        ...UserRole.values.map(
                          (role) => Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _buildRoleChip(
                              _getRoleDisplayName(role),
                              role,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Users List or Project Selection Message
          Expanded(
            child: _selectedProjectId == null
                ? _buildSelectProjectMessage()
                : StreamBuilder<List<UserModel>>(
                    stream: UserService.getUsersForProject(_selectedProjectId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final users = _filterUsers(snapshot.data ?? []);

                      if (users.isEmpty) {
                        return _buildEmptyUsersMessage();
                      }

                      return ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          return _buildUserCard(users[index]);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectProjectMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_special,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Pilih Proyek Terlebih Dahulu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Silakan pilih proyek untuk mengelola user',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyUsersMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada user di proyek ini',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap tombol + untuk menambah user atau copy dari proyek lain',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, UserRole? role) {
    final isSelected = _selectedRoleFilter == role;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedRoleFilter = selected ? role : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Text(
            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (user.isAdmin)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ALL PROJECTS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            if (user.needsMigration)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'NEEDS ASSIGNMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade600,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            SizedBox(height: 4),
            Text("Password: ${user.password}"),
            SizedBox(height: 4),
            // Projects assigned (for non-admin)
            if (!user.isAdmin && !user.needsMigration && user.projectIds.isNotEmpty)
              FutureBuilder<List<ProjectModel>>(
                future: _getProjectNames(user.projectIds),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.folder_special, size: 14, color: Colors.blue),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Projects: ${snapshot.data!.map((p) => p.name).join(', ')}',
                              style: TextStyle(fontSize: 12, color: Colors.blue[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            // Tampilkan lokasi user
            if (user.locationId != null) 
              FutureBuilder<LocationModel?>(
                future: LocationService.getLocationById(user.locationId!),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              snapshot.data!.name,
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return SizedBox.shrink();
                },
              ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                user.roleDisplayName,
                style: TextStyle(
                  color: _getRoleColor(user.role),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(value, user),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            if (!user.isAdmin)
              PopupMenuItem(
                value: 'manage_projects',
                child: Row(
                  children: [
                    Icon(Icons.folder_special, size: 20, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Manage Projects'),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<ProjectModel>> _getProjectNames(List<String> projectIds) async {
    List<ProjectModel> projects = [];
    for (String id in projectIds) {
      ProjectModel? project = await ProjectService.getProjectById(id);
      if (project != null) projects.add(project);
    }
    return projects;
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(_searchQuery) ||
              user.email.toLowerCase().contains(_searchQuery);
      final matchesRole =
          _selectedRoleFilter == null || user.role == _selectedRoleFilter;
      return matchesSearch && matchesRole;
    }).toList();
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade600;
      case UserRole.koordinator:
        return Colors.blue.shade600;
      case UserRole.approver:
        return Colors.green.shade600;
      case UserRole.bawahan:
        return Colors.grey.shade600;
    }
  }

  String _getRoleDisplayName(UserRole role) {
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

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'manage_projects':
        _showManageProjectsDialog(user);
        break;
      case 'delete':
        _showDeleteConfirmation(user);
        break;
    }
  }

  void _showAddUserDialog() {
    _showUserDialog(null);
  }

  void _showEditUserDialog(UserModel user) {
    _showUserDialog(user);
  }

  void _showUserDialog(UserModel? user) {
    final _nameController = TextEditingController(text: user?.name ?? '');
    final _emailController = TextEditingController(text: user?.email ?? '');
    final _passwordController = TextEditingController();
    UserRole _selectedRole = user?.role ?? UserRole.bawahan;
    String? _selectedLocationId = user?.locationId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(user == null ? 'Add User' : 'Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: user == null,
                ),
                if (user == null) ...[
                  SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                ],
                SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: UserRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => _selectedRole = value);
                    }
                  },
                ),
                SizedBox(height: 16),
                // Dropdown untuk pilihan lokasi
                StreamBuilder<List<LocationModel>>(
                  stream: LocationService.getAllLocations(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return CircularProgressIndicator();
                    }

                    final locations = snapshot.data!;
                    
                    return DropdownButtonFormField<String>(
                      value: _selectedLocationId,
                      decoration: InputDecoration(
                        labelText: 'Location (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          value: null,
                          child: Text('No Location'),
                        ),
                        ...locations.map((location) {
                          return DropdownMenuItem<String>(
                            value: location.id,
                            child: Text(location.name),
                          );
                        }).toList(),
                      ],
                      onChanged: (value) {
                        setDialogState(() => _selectedLocationId = value);
                      },
                    );
                  },
                ),
                SizedBox(height: 8),
                // Info untuk admin
                if (_selectedRole == UserRole.admin)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.red, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin dapat mengakses semua proyek',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _saveUser(
                user,
                _nameController.text,
                _emailController.text,
                _passwordController.text,
                _selectedRole,
                _selectedLocationId,
              ),
              child: Text(user == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showManageProjectsDialog(UserModel user) {
    List<String> selectedProjects = List<String>.from(user.projectIds);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Manage Projects for ${user.name}'),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<List<ProjectModel>>(
              stream: ProjectService.getProjects(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();
                
                return ListView(
                  shrinkWrap: true,
                  children: snapshot.data!.map((project) {
                    bool isSelected = selectedProjects.contains(project.id);
                    
                    return CheckboxListTile(
                      title: Text(project.name),
                      subtitle: Text(project.description),
                      value: isSelected,
                      onChanged: (value) {
                        setDialogState(() {
                          if (value == true) {
                            selectedProjects.add(project.id!);
                          } else {
                            selectedProjects.remove(project.id);
                          }
                        });
                      },
                    );
                  }).toList(),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _updateUserProjects(user, selectedProjects),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCopyUsersDialog() {
    if (_selectedProjectId == null) return;
    
    String? sourceProjectId;
    List<String> selectedUserIds = [];
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Copy Users to Current Project'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: Column(
              children: [
                // Source Project Selector
                StreamBuilder<List<ProjectModel>>(
                  stream: ProjectService.getProjects(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    
                    final projects = snapshot.data!
                        .where((p) => p.id != _selectedProjectId)
                        .toList();
                    
                    return DropdownButtonFormField<String>(
                      value: sourceProjectId,
                      decoration: InputDecoration(
                        labelText: 'Copy from Project',
                        border: OutlineInputBorder(),
                      ),
                      items: projects.map((project) {
                        return DropdownMenuItem(
                          value: project.id,
                          child: Text(project.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          sourceProjectId = value;
                          selectedUserIds.clear();
                        });
                      },
                    );
                  },
                ),
                SizedBox(height: 16),
                
                // Users List
                if (sourceProjectId != null)
                  Expanded(
                    child: StreamBuilder<List<UserModel>>(
                      stream: UserService.getUsersAvailableForProject(_selectedProjectId!),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return CircularProgressIndicator();
                        
                        final availableUsers = snapshot.data!
                            .where((user) => user.projectIds.contains(sourceProjectId))
                            .toList();
                        
                        if (availableUsers.isEmpty) {
                          return Center(child: Text('No users available to copy'));
                        }
                        
                        return ListView(
                          children: availableUsers.map((user) {
                            bool isSelected = selectedUserIds.contains(user.id);
                            
                            return CheckboxListTile(
                              title: Text(user.name),
                              subtitle: Text(user.roleDisplayName),
                              value: isSelected,
                              onChanged: (value) {
                                setDialogState(() {
                                  if (value == true) {
                                    selectedUserIds.add(user.id);
                                  } else {
                                    selectedUserIds.remove(user.id);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedUserIds.isNotEmpty 
                  ? () => _copyUsersToProject(selectedUserIds)
                  : null,
              child: Text('Copy ${selectedUserIds.length} Users'),
            ),
          ],
        ),
      ),
    );
  }

  void _saveUser(
    UserModel? existingUser,
    String name,
    String email,
    String password,
    UserRole role,
    String? locationId,
  ) async {
    if (name.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (existingUser == null && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password is required for new users')),
      );
      return;
    }

    Navigator.pop(context);

    try {
      // Tentukan projectIds berdasarkan role
      List<String> projectIds = [];
      if (role != UserRole.admin && _selectedProjectId != null) {
        // Non-admin assign ke project yang sedang dipilih
        projectIds = [_selectedProjectId!];
      }
      // Admin tidak perlu projectIds (bisa akses semua)

      if (existingUser == null) {
        // Create new user
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        await UserService.createUser(
          credential.user!.uid,
          email,
          password,
          name,
          role,
          locationId,
          projectIds, // Multi-project support
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User created successfully')),
        );
      } else {
        // Update existing user
        final updatedUser = existingUser.copyWith(
          name: name, 
          role: role, 
          locationId: locationId,
          // Keep existing projects for updates
        );

        await UserService.updateUser(existingUser.id, updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User updated successfully')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _updateUserProjects(UserModel user, List<String> projectIds) async {
    Navigator.pop(context);
    
    try {
      UserModel updatedUser = user.copyWith(
        projectIds: projectIds,
        needsMigration: false,
      );
      
      await UserService.updateUser(user.id, updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User projects updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _copyUsersToProject(List<String> userIds) async {
    Navigator.pop(context);
    
    try {
      await UserService.bulkAssignUsersToProject(userIds, _selectedProjectId!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${userIds.length} users copied successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showDeleteConfirmation(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _deleteUser(user),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteUser(UserModel user) async {
    Navigator.pop(context);

    try {
      await UserService.deleteUser(user.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting user: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}