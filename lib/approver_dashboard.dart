import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/approval_epidence_page.dart';
import 'approval_ba_page.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'evidence_service.dart';
import 'project_service.dart';
import 'project_model.dart';
import 'session_manager.dart';

class ApproverDashboard extends StatefulWidget {
  @override
  _ApproverDashboardState createState() => _ApproverDashboardState();
}

class _ApproverDashboardState extends State<ApproverDashboard> {
  UserModel? currentUser;
  ProjectModel? currentProject;
  List<ProjectModel> availableProjects = [];
  bool _isLoading = true;
  Map<String, dynamic> _evidenceStats = {};
  String? _currentProjectId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      // Load current user
      currentUser = await UserService.getCurrentUser();
      
      // Load current project
      _currentProjectId = await SessionManager.getCurrentProject();
      if (_currentProjectId != null) {
        currentProject = await ProjectService.getProjectById(_currentProjectId!);
      }
      
      // Load available projects untuk user ini (untuk project switcher)
      if (currentUser != null) {
        if (currentUser!.isAdmin) {
          // Admin bisa akses semua proyek
          availableProjects = await ProjectService.getProjects().first;
        } else {
          // User biasa hanya yang di-assign
          final allProjects = await ProjectService.getProjects().first;
          availableProjects = allProjects
              .where((project) => currentUser!.projectIds.contains(project.id))
              .toList();
        }
      }

      // Load stats untuk project yang aktif
      if (_currentProjectId != null) {
        await _loadProjectStats();
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadProjectStats() async {
    if (_currentProjectId == null) return;
    
    try {
      final evidenceStats = await EvidenceService.getEvidenceStatsByProject(_currentProjectId!);
      setState(() {
        _evidenceStats = evidenceStats;
      });
    } catch (e) {
      print('Error loading project stats: $e');
    }
  }

  Future<void> _signOut() async {
    try {
      await SessionManager.clearSession();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out')),
      );
    }
  }

  Future<void> _switchProject(String newProjectId) async {
    if (newProjectId == currentProject?.id) return;
    
    try {
      await SessionManager.setCurrentProject(newProjectId);
      
      // Reload dashboard data dengan proyek baru
      setState(() => _isLoading = true);
      await _loadDashboardData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Berhasil beralih ke proyek ${currentProject?.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error switching project: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard Approver')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentProjectId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Dashboard Approver')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Tidak ada proyek aktif',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Silakan pilih proyek terlebih dahulu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    
    final totalPending = (_evidenceStats['pending'] ?? 0) + 5; // 5 untuk BA pending (hardcoded)
    final evidencePending = _evidenceStats['pending'] ?? 0;
    final baPending = 5; // Hardcoded untuk sekarang

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Approver',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: !isWeb,
        actions: [
          // Project Switcher untuk user yang punya akses multiple projects
          if (availableProjects.length > 1)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: PopupMenuButton<String>(
                icon: Icon(Icons.folder_special),
                tooltip: 'Ganti Proyek',
                onSelected: _switchProject,
                itemBuilder: (context) => availableProjects.map((project) {
                  final isCurrentProject = project.id == currentProject?.id;
                  return PopupMenuItem<String>(
                    value: project.id!,
                    child: Row(
                      children: [
                        Icon(
                          isCurrentProject ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isCurrentProject ? Colors.green : Colors.grey,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                project.name,
                                style: TextStyle(
                                  fontWeight: isCurrentProject ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                project.city,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          if (isWeb)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentUser?.name ?? 'Approver',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                      if (currentProject != null)
                        Text(
                          currentProject!.name,
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                    ],
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.green.shade100,
                    child: Text(
                      (currentUser?.name?.substring(0, 1) ?? 'A').toUpperCase(),
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                ],
              ),
            ),
          IconButton(
            onPressed: _signOut,
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: isWeb ? 1200 : double.infinity,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isWeb ? 32 : 20,
                      vertical: isWeb ? 24 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Project Card
                        _buildCurrentProjectCard(isWeb),
                        
                        SizedBox(height: isWeb ? 24 : 20),
                        
                        // Welcome Card - Hidden on web if shown in AppBar
                        if (!isWeb) _buildWelcomeCard(),
                        
                        SizedBox(height: isWeb ? 30 : 24),
                        
                        Text(
                          'Menu Approval',
                          style: TextStyle(
                            fontSize: isWeb ? 24 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        
                        SizedBox(height: isWeb ? 24 : 16),
                        
                        // Pending Approvals Summary
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(isWeb ? 20 : 16),
                          margin: EdgeInsets.only(bottom: isWeb ? 24 : 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.orange.shade50, Colors.orange.shade100],
                            ),
                            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                            border: Border.all(color: Colors.orange.shade200),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.1),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(isWeb ? 12 : 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.pending_actions,
                                  color: Colors.white,
                                  size: isWeb ? 24 : 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pending Approvals',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                        fontSize: isWeb ? 16 : 14,
                                      ),
                                    ),
                                    Text(
                                      '$totalPending items menunggu persetujuan Anda',
                                      style: TextStyle(
                                        color: Colors.orange.shade700,
                                        fontSize: isWeb ? 14 : 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isWeb ? 12 : 8, 
                                  vertical: isWeb ? 8 : 4
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$totalPending',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWeb ? 16 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Menu Grid
                        _buildMenuGrid(isWeb, baPending, evidencePending),
                        
                        SizedBox(height: isWeb ? 32 : 24),
                        
                        // Info Card
                        _buildInfoCard(isWeb),
                        
                        if (isWeb) SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentProjectCard(bool isWeb) {
    if (currentProject == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: isWeb ? 24 : 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Tidak ada proyek aktif. Silakan hubungi administrator.',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: isWeb ? 15 : 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade600, Colors.green.shade500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 24 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 12 : 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: isWeb ? 28 : 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Proyek Aktif',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isWeb ? 14 : 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        currentProject!.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isWeb ? 20 : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (availableProjects.length > 1)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${availableProjects.length} proyek',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            // Project Details
            Row(
              children: [
                Expanded(
                  child: _buildProjectDetail(
                    Icons.location_city,
                    'Venue',
                    '${currentProject!.venueTypeDisplayName} • ${currentProject!.venueName}',
                    isWeb,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildProjectDetail(
                    Icons.location_on,
                    'Lokasi',
                    '${currentProject!.address}, ${currentProject!.city}',
                    isWeb,
                  ),
                ),
              ],
            ),
            if (currentProject!.dateRangeDisplay != 'Tanggal belum ditentukan') ...[
              SizedBox(height: 12),
              _buildProjectDetail(
                Icons.calendar_today,
                'Jadwal',
                currentProject!.dateRangeDisplay,
                isWeb,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDetail(IconData icon, String label, String value, bool isWeb) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: isWeb ? 16 : 14,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: isWeb ? 12 : 10,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isWeb ? 13 : 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified,
                  color: Colors.green.shade600,
                  size: 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, ${currentUser?.name ?? 'Approver'}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Approver',
                      style: TextStyle(
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            currentUser?.email ?? '',
            style: TextStyle(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(bool isWeb, int baPending, int evidencePending) {
    return isWeb 
      ? Row(
          children: [
            Expanded(
              child: _buildMenuCard(
                icon: Icons.assignment_turned_in,
                title: 'Approval BA',
                subtitle: 'Setujui berita acara',
                color: Colors.blue,
                pendingCount: baPending,
                isWeb: isWeb,
                onTap: _currentProjectId != null ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApprovalBAPage(),
                    ),
                  );
                } : null,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildMenuCard(
                icon: Icons.photo_size_select_actual,
                title: 'Approval Evidence',
                subtitle: 'Setujui bukti kegiatan',
                color: Colors.green,
                pendingCount: evidencePending,
                isWeb: isWeb,
                onTap: _currentProjectId != null ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ApprovalEvidencePage(),
                    ),
                  );
                } : null,
              ),
            ),
          ],
        )
      : Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildMenuCard(
                    icon: Icons.assignment_turned_in,
                    title: 'Approval BA',
                    subtitle: 'Setujui berita acara',
                    color: Colors.blue,
                    pendingCount: baPending,
                    isWeb: isWeb,
                    onTap: _currentProjectId != null ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApprovalBAPage(),
                        ),
                      );
                    } : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildMenuCard(
                    icon: Icons.photo_size_select_actual,
                    title: 'Approval Evidence',
                    subtitle: 'Setujui bukti kegiatan',
                    color: Colors.green,
                    pendingCount: evidencePending,
                    isWeb: isWeb,
                    onTap: _currentProjectId != null ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ApprovalEvidencePage(),
                        ),
                      );
                    } : null,
                  ),
                ),
              ],
            ),
          ],
        );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required int pendingCount,
    required bool isWeb,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isWeb ? 160 : 140,
        decoration: BoxDecoration(
          color: isDisabled ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(isDisabled ? 0.05 : 0.1),
              spreadRadius: 1,
              blurRadius: isWeb ? 12 : 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.all(isWeb ? 16 : 12),
                    decoration: BoxDecoration(
                      color: isDisabled 
                          ? Colors.grey.withOpacity(0.1) 
                          : color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(isWeb ? 12 : 10),
                    ),
                    child: Icon(
                      icon,
                      color: isDisabled ? Colors.grey.shade400 : color,
                      size: isWeb ? 28 : 24,
                    ),
                  ),
                  if (pendingCount > 0 && !isDisabled)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 8 : 6, 
                        vertical: isWeb ? 4 : 2
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isWeb ? 12 : 10,
                        ),
                      ),
                    ),
                ],
              ),
              Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 16 : 14,
                  color: isDisabled ? Colors.grey.shade500 : Colors.grey.shade800,
                ),
              ),
              SizedBox(height: 4),
              Text(
                isDisabled ? 'Pilih proyek terlebih dahulu' : subtitle,
                style: TextStyle(
                  color: isDisabled ? Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: isWeb ? 13 : 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (pendingCount > 0 && !isDisabled) ...[
                SizedBox(height: 6),
                Text(
                  '$pendingCount pending',
                  style: TextStyle(
                    color: color,
                    fontSize: isWeb ? 12 : 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.green.shade600,
            size: isWeb ? 24 : 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              currentProject != null
                  ? 'Sebagai approver proyek "${currentProject!.name}", Anda bertanggung jawab meninjau dan menyetujui dokumen yang diajukan koordinator.'
                  : 'Sebagai approver, Anda bertanggung jawab meninjau dan menyetujui dokumen yang diajukan koordinator.',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: isWeb ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}