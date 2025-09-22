import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';
import 'project_service.dart';
import 'project_model.dart';
import 'session_manager.dart';

class ProjectSelectionPage extends StatefulWidget {
  final UserModel user;

  const ProjectSelectionPage({Key? key, required this.user}) : super(key: key);

  @override
  _ProjectSelectionPageState createState() => _ProjectSelectionPageState();
}

class _ProjectSelectionPageState extends State<ProjectSelectionPage> {
  bool _isLoading = false;

  Future<void> _selectProject(String projectId) async {
    setState(() => _isLoading = true);

    try {
      // Simpan project ID menggunakan SessionManager
      await SessionManager.setCurrentProject(projectId);

      // Refresh halaman dengan reload AuthWrapper
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    try {
      // Clear session menggunakan SessionManager
      await SessionManager.clearSession();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Proyek'),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Header Info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_special,
                        size: 48,
                        color: Colors.blue.shade600,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Selamat datang, ${widget.user.name}!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.user.isAdmin 
                            ? 'Pilih proyek yang ingin Anda kelola'
                            : 'Pilih proyek untuk memulai bekerja',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getRoleColor(widget.user.role).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.user.roleDisplayName,
                          style: TextStyle(
                            color: _getRoleColor(widget.user.role),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Projects List
                Expanded(
                  child: widget.user.isAdmin 
                      ? _buildAdminProjectList()
                      : _buildUserProjectList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAdminProjectList() {
    return StreamBuilder<List<ProjectModel>>(
      stream: ProjectService.getProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading projects'),
                Text(snapshot.error.toString()),
              ],
            ),
          );
        }

        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off, size: 48, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Belum ada proyek',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return _buildProjectCard(projects[index]);
          },
        );
      },
    );
  }

  Widget _buildUserProjectList() {
    return FutureBuilder<List<ProjectModel>>(
      future: _getUserProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading your projects'),
              ],
            ),
          );
        }

        final projects = snapshot.data ?? [];

        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, size: 48, color: Colors.orange),
                SizedBox(height: 16),
                Text(
                  'Tidak ada proyek yang tersedia',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                SizedBox(height: 8),
                Text(
                  'Hubungi admin untuk mendapat akses proyek',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: projects.length,
          itemBuilder: (context, index) {
            return _buildProjectCard(projects[index]);
          },
        );
      },
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: _isLoading ? null : () => _selectProject(project.id!),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.event_note,
                        color: Colors.blue.shade600,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            project.description,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.blue.shade400,
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // Project details
                Row(
                  children: [
                    Icon(Icons.location_city, size: 16, color: Colors.grey.shade500),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${project.venueTypeDisplayName} • ${project.venueName}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 6),
                
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey.shade500),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${project.address}, ${project.city}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (project.dateRangeDisplay != 'Tanggal belum ditentukan') ...[
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 8),
                      Text(
                        project.dateRangeDisplay,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<ProjectModel>> _getUserProjects() async {
    try {
      final allProjects = await ProjectService.getProjects().first;
      return allProjects.where((project) => 
          widget.user.projectIds.contains(project.id)
      ).toList();
    } catch (e) {
      print('Error getting user projects: $e');
      return [];
    }
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
}