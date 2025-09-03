import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'berita_acara_page.dart';
import 'evidence_page.dart';
import 'nota_page.dart';
import 'absensi_page.dart';
import 'user_service.dart';
import 'user_model.dart';

class CoordinatorDashboard extends StatefulWidget {
  @override
  _CoordinatorDashboardState createState() => _CoordinatorDashboardState();
}

class _CoordinatorDashboardState extends State<CoordinatorDashboard> {
  UserModel? currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser = await UserService.getCurrentUser();
    } catch (e) {
      print('Error loading user: $e');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
          if (isWeb)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentUser?.name ?? 'Koordinator',
                    style: TextStyle(fontSize: 14),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BeritaAcaraPage(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.photo_library,
          title: 'Evidence',
          subtitle: 'Upload bukti kegiatan',
          color: Colors.green,
          isWeb: isWeb,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EvidencePage(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.receipt_long,
          title: 'Nota',
          subtitle: 'Kelola nota pembayaran',
          color: Colors.orange,
          isWeb: isWeb,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NotaPage(),
              ),
            );
          },
        ),
        _buildMenuCard(
          icon: Icons.how_to_reg,
          title: 'Absensi',
          subtitle: 'Kelola absensi peserta',
          color: Colors.purple,
          isWeb: isWeb,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AbsensiPage(),
              ),
            );
          },
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
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isWeb ? 36 : 32,
                  ),
                ),
                SizedBox(height: isWeb ? 16 : 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isWeb ? 16 : 14,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
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
              'Sebagai koordinator, Anda dapat mengelola dokumentasi dan administrasi kegiatan.',
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