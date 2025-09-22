import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'project_service.dart';
import 'project_model.dart';

class UserMigrationDashboard extends StatefulWidget {
  @override
  _UserMigrationDashboardState createState() => _UserMigrationDashboardState();
}

class _UserMigrationDashboardState extends State<UserMigrationDashboard> {
  List<String> selectedUserIds = [];
  String? selectedProjectForBulk;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Migration'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showMigrationInfo,
            tooltip: 'Migration Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Migration Summary Card
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: _buildMigrationSummary(),
          ),

          // Bulk Assignment Section
          if (selectedUserIds.isNotEmpty)
            Container(
              color: Colors.orange.withOpacity(0.1),
              padding: EdgeInsets.all(16),
              child: _buildBulkAssignmentSection(),
            ),

          // Users List
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: UserService.getUsersNeedingMigration(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                        ElevatedButton(
                          onPressed: _showAllUsersDebug,
                          child: Text('Debug: Show All Users'),
                        ),
                      ],
                    ),
                  );
                }

                final users = snapshot.data ?? [];

                // Debug: Print users info
                print('=== MIGRATION DEBUG ===');
                print('Found ${users.length} users needing migration');
                for (var user in users) {
                  print('User: ${user.name} (${user.email}) - needsMigration: ${user.needsMigration}, projectIds: ${user.projectIds}');
                }
                print('======================');

                if (users.isEmpty) {
                  return Column(
                    children: [
                      Expanded(child: _buildCompletedMigrationMessage()),
                      ElevatedButton(
                        onPressed: _showAllUsersDebug,
                        child: Text('Debug: Show All Users'),
                      ),
                      SizedBox(height: 20),
                    ],
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    return _buildUserMigrationCard(users[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMigrationSummary() {
    return StreamBuilder<List<UserModel>>(
      stream: UserService.getUsersNeedingMigration(),
      builder: (context, snapshot) {
        int pendingCount = snapshot.data?.length ?? 0;
        
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.sync_alt, size: 32, color: Colors.orange),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Migration Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$pendingCount users need project assignment',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      if (pendingCount > 0)
                        Text(
                          'These are legacy users without project assignments',
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                    ],
                  ),
                ),
                if (pendingCount > 0)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$pendingCount pending',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkAssignmentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_add, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Bulk Assignment',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => selectedUserIds.clear());
                  },
                  child: Text('Clear Selection'),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text('${selectedUserIds.length} users selected'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<List<ProjectModel>>(
                    stream: ProjectService.getProjects(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return CircularProgressIndicator();
                      
                      return DropdownButtonFormField<String>(
                        value: selectedProjectForBulk,
                        decoration: InputDecoration(
                          labelText: 'Select Project',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: snapshot.data!.map((project) {
                          return DropdownMenuItem(
                            value: project.id,
                            child: Text(project.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => selectedProjectForBulk = value);
                        },
                      );
                    },
                  ),
                ),
                SizedBox(width: 12),
                ElevatedButton(
                  onPressed: selectedProjectForBulk != null ? _bulkAssignUsers : null,
                  child: isLoading 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Assign'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserMigrationCard(UserModel user) {
    bool isSelected = selectedUserIds.contains(user.id);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    selectedUserIds.add(user.id);
                  } else {
                    selectedUserIds.remove(user.id);
                  }
                });
              },
            ),
            CircleAvatar(
              backgroundColor: _getRoleColor(user.role),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
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
                  color: Colors.orange.shade700,
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
              value: 'assign',
              child: Row(
                children: [
                  Icon(Icons.assignment_ind, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Assign to Project'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'details',
              child: Row(
                children: [
                  Icon(Icons.info, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedMigrationMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            size: 64,
            color: Colors.green.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Migration Complete!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'All users have been assigned to projects',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Back to User Management'),
          ),
        ],
      ),
    );
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

  void _handleUserAction(String action, UserModel user) {
    switch (action) {
      case 'assign':
        _showAssignProjectDialog(user);
        break;
      case 'details':
        _showUserDetails(user);
        break;
    }
  }

  void _showAssignProjectDialog(UserModel user) {
    String? selectedProject;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Assign ${user.name} to Project'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select a project to assign this user to:'),
              SizedBox(height: 16),
              StreamBuilder<List<ProjectModel>>(
                stream: ProjectService.getProjects(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  
                  return DropdownButtonFormField<String>(
                    value: selectedProject,
                    decoration: InputDecoration(
                      labelText: 'Project',
                      border: OutlineInputBorder(),
                    ),
                    items: snapshot.data!.map((project) {
                      return DropdownMenuItem(
                        value: project.id,
                        child: Text(project.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() => selectedProject = value);
                    },
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedProject != null 
                  ? () => _assignUserToProject(user, selectedProject!)
                  : null,
              child: Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetails(UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', user.name),
            _buildDetailRow('Email', user.email),
            _buildDetailRow('Role', user.roleDisplayName),
            _buildDetailRow('Created', '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
            _buildDetailRow('Status', user.needsMigration ? 'Needs Assignment' : 'Assigned'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showMigrationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Migration Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'What is User Migration?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'This dashboard helps you assign legacy users (created before project system) to specific projects.',
              ),
              SizedBox(height: 16),
              Text(
                'How to use:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Select users individually or use bulk selection'),
              Text('• Choose a project to assign them to'),
              Text('• Users will then have access to assigned projects'),
              Text('• Admin users don\'t need assignment (access all projects)'),
              SizedBox(height: 16),
              Text(
                'Note:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
              ),
              SizedBox(height: 4),
              Text(
                'Users without project assignment cannot access any project features until assigned.',
                style: TextStyle(color: Colors.orange.shade700),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _assignUserToProject(UserModel user, String projectId) async {
    Navigator.pop(context); // Close dialog
    
    try {
      await UserService.assignUserToProject(user.id, projectId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} assigned to project successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _bulkAssignUsers() async {
    if (selectedProjectForBulk == null || selectedUserIds.isEmpty) return;

    setState(() => isLoading = true);

    try {
      await UserService.bulkAssignUsersToProject(selectedUserIds, selectedProjectForBulk!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${selectedUserIds.length} users assigned successfully')),
      );
      
      setState(() {
        selectedUserIds.clear();
        selectedProjectForBulk = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshMigrationStatus() async {
    try {
      await UserService.refreshMigrationStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Migration status refreshed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error refreshing: $e')),
      );
    }
  }

  void _showAllUsersDebug() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('users').get();
      List<UserModel> allUsers = snapshot.docs
          .map((doc) => UserModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Debug: All Users'),
          content: Container(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: allUsers.map((user) {
                return Card(
                  child: ListTile(
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user.email}'),
                        Text('Role: ${user.roleDisplayName}'),
                        Text('ProjectIds: ${user.projectIds}'),
                        Text('NeedsMigration: ${user.needsMigration}'),
                        Text('IsAdmin: ${user.isAdmin}'),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debug error: $e')),
      );
    }
  }
}