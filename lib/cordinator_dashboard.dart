import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ba_selection_page.dart';
import 'evidence_page.dart';
import 'nota_page.dart';
import 'absensi_page.dart';
import 'laporan_visual_page.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'project_service.dart';
import 'project_model.dart';
import 'session_manager.dart';

class CoordinatorDashboard extends StatefulWidget {
  @override
  _CoordinatorDashboardState createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  UserModel? currentUser;
  ProjectModel? currentProject;
  List<ProjectModel> availableProjects = [];
  bool _isLoading = true;

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
      final currentProjectId = await SessionManager.getCurrentProject();
      if (currentProjectId != null) {
        currentProject = await ProjectService.getProjectById(currentProjectId);
      }

      // Load available projects untuk user ini (untuk project switcher)
      if (currentUser != null) {
        if (currentUser!.isAdmin) {
          // Admin bisa akses semua proyek
          availableProjects = await ProjectService.getProjects().first;
        } else {
          // User biasa hanya yang di-assign
          final allProjects = await ProjectService.getProjects().first;
          availableProjects =
              allProjects
                  .where(
                    (project) => currentUser!.projectIds.contains(project.id),
                  )
                  .toList();
        }
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    try {
      await SessionManager.clearSession();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error signing out')));
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
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final isTablet = screenWidth > 600 && screenWidth <= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Dashboard Koordinator',
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
                itemBuilder:
                    (context) =>
                        availableProjects.map((project) {
                          final isCurrentProject =
                              project.id == currentProject?.id;
                          return PopupMenuItem<String>(
                            value: project.id!,
                            child: Row(
                              children: [
                                Icon(
                                  isCurrentProject
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color:
                                      isCurrentProject
                                          ? Colors.blue
                                          : Colors.grey,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        project.name,
                                        style: TextStyle(
                                          fontWeight:
                                              isCurrentProject
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
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
                        currentUser?.name ?? 'Koordinator',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      (currentUser?.name?.substring(0, 1) ?? 'K').toUpperCase(),
                      style: TextStyle(
                        color: Colors.blue.shade600,
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
                      horizontal: isWeb ? 32 : 16,
                      vertical: isWeb ? 24 : 20,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Current Project Card
                        _buildCurrentProjectCard(isWeb),

                        SizedBox(height: isWeb ? 24 : 20),

                        // Welcome Card - Hidden on web if shown in AppBar
                        if (!isWeb) _buildWelcomeCard(isWeb),

                        SizedBox(height: isWeb ? 32 : 24),

                        // Section Title
                        Text(
                          'Menu Koordinator',
                          style: TextStyle(
                            fontSize: isWeb ? 24 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),

                        SizedBox(height: isWeb ? 24 : 16),

                        // Menu Grid
                        _buildMenuGrid(isWeb, isTablet, screenWidth),

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
          colors: [Colors.blue.shade600, Colors.blue.shade500],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
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
                    Icons.event_note,
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
            if (currentProject!.dateRangeDisplay !=
                'Tanggal belum ditentukan') ...[
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

  Widget _buildProjectDetail(
    IconData icon,
    String label,
    String value,
    bool isWeb,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: isWeb ? 16 : 14),
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

  Widget _buildWelcomeCard(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: isWeb ? 15 : 10,
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
                padding: EdgeInsets.all(isWeb ? 16 : 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                ),
                child: Icon(
                  Icons.people_alt,
                  color: Colors.blue.shade600,
                  size: isWeb ? 32 : 28,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, ${currentUser?.name ?? 'Koordinator'}',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    Text(
                      'Koordinator',
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: isWeb ? 16 : 14,
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
              fontSize: isWeb ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(bool isWeb, bool isTablet, double screenWidth) {
    int crossAxisCount;
    double childAspectRatio;

    if (isWeb) {
      crossAxisCount = 4;
      childAspectRatio = 1.1;
    } else if (isTablet) {
      crossAxisCount = 3;
      childAspectRatio = 1.0;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 1.0;
    }

    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isWeb ? 24 : 16,
      mainAxisSpacing: isWeb ? 24 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildMenuCard(
          icon: Icons.description,
          title: 'Berita Acara',
          subtitle: 'Kelola berita acara kegiatan',
          color: Colors.blue,
          isWeb: isWeb,
          onTap:
              currentProject != null
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => BASelectionPage(
                              role: 'coordinator',
                            ),
                      ),
                    );
                  }
                  : null,
        ),
        _buildMenuCard(
          icon: Icons.photo_library,
          title: 'Evidence',
          subtitle: 'Upload bukti kegiatan',
          color: Colors.green,
          isWeb: isWeb,
          onTap:
              currentProject != null
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EvidencePage()),
                    );
                  }
                  : null,
        ),
        _buildMenuCard(
          icon: Icons.receipt_long,
          title: 'Nota',
          subtitle: 'Kelola nota pembayaran',
          color: Colors.orange,
          isWeb: isWeb,
          onTap:
              currentProject != null
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => NotaPage()),
                    );
                  }
                  : null,
        ),
        _buildMenuCard(
          icon: Icons.how_to_reg,
          title: 'Absensi',
          subtitle: 'Kelola absensi peserta',
          color: Colors.purple,
          isWeb: isWeb,
          onTap:
              currentProject != null
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AbsensiPage()),
                    );
                  }
                  : null,
        ),
        _buildMenuCard(
          icon: Icons.bar_chart,
          title: 'Laporan Visual',
          subtitle: 'Lihat laporan visual kegiatan',
          color: Colors.teal,
          isWeb: isWeb,
          onTap:
              currentProject != null
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LaporanVisualPage()),
                    );
                  }
                  : null,
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isWeb,
    VoidCallback? onTap,
  }) {
    final isDisabled = onTap == null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        child: Container(
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(isWeb ? 20 : 16),
                  decoration: BoxDecoration(
                    color:
                        isDisabled
                            ? Colors.grey.withOpacity(0.1)
                            : color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled ? Colors.grey.shade400 : color,
                    size: isWeb ? 36 : 32,
                  ),
                ),
                SizedBox(height: isWeb ? 16 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 16 : 14,
                    color:
                        isDisabled
                            ? Colors.grey.shade500
                            : Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  isDisabled ? 'Pilih proyek terlebih dahulu' : subtitle,
                  style: TextStyle(
                    color:
                        isDisabled
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                    fontSize: isWeb ? 14 : 11,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.blue.shade600,
            size: isWeb ? 24 : 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              currentProject != null
                  ? 'Sebagai koordinator proyek "${currentProject!.name}", Anda dapat mengelola dokumentasi dan administrasi kegiatan.'
                  : 'Sebagai koordinator, Anda dapat mengelola dokumentasi dan administrasi kegiatan.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontSize: isWeb ? 15 : 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}