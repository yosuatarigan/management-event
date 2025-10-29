import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'absensi_service.dart';
import 'absensi_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'session_manager.dart';

class AbsensiPage extends StatefulWidget {
  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> with TickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _todayStats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTodayStats();
  }

  Future<void> _loadTodayStats() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final stats = await AbsensiService.getAbsensiStats(currentUser.uid, _selectedDate);
        setState(() => _todayStats = stats);
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Widget _buildNoProjectSelected(bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_off,
            size: isWeb ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            'Tidak Ada Project Dipilih',
            style: TextStyle(
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pilih project terlebih dahulu untuk menggunakan fitur absensi',
            style: TextStyle(
              fontSize: isWeb ? 16 : 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final currentProjectId = SessionManager.currentProjectId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Absensi',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: !isWeb,
        bottom: currentProjectId != null ? TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Icon(Icons.today),
              text: 'Hari Ini',
              iconMargin: EdgeInsets.only(bottom: isWeb ? 8 : 4),
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'Riwayat',
              iconMargin: EdgeInsets.only(bottom: isWeb ? 8 : 4),
            ),
          ],
        ) : null,
      ),
      body: currentProjectId == null 
          ? _buildNoProjectSelected(isWeb)
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(isWeb, currentProjectId),
                _buildHistoryTab(isWeb),
              ],
            ),
    );
  }

  Widget _buildTodayTab(bool isWeb, String projectId) {
    return Column(
      children: [
        // Date Selector & Stats
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
              child: Column(
                children: [
                  // Date Picker
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isWeb ? 16 : 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: isWeb ? 8 : 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _selectDate,
                      borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isWeb ? 12 : 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.calendar_today, 
                              color: Colors.purple,
                              size: isWeb ? 24 : 20,
                            ),
                          ),
                          SizedBox(width: isWeb ? 16 : 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tanggal Absensi',
                                  style: TextStyle(
                                    fontSize: isWeb ? 14 : 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  style: TextStyle(
                                    fontSize: isWeb ? 18 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: isWeb ? 28 : 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: isWeb ? 20 : 16),
                  
                  // Stats Grid
                  _buildStatsGrid(isWeb),
                ],
              ),
            ),
          ),
        ),
        
        // Content
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
              child: Column(
                children: [
                  // Action Button
                  if ((_todayStats['belum_absen'] ?? 0) > 0)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isWeb ? 24 : 16),
                      child: ElevatedButton.icon(
                        onPressed: () => _showBulkAbsensiDialog(projectId),
                        icon: Icon(Icons.group_add),
                        label: Text(
                          'Absensi Massal',
                          style: TextStyle(fontSize: isWeb ? 16 : 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, isWeb ? 50 : 45),
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 24 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                          ),
                        ),
                      ),
                    ),
                  
                  // List
                  Expanded(
                    child: StreamBuilder<List<UserModel>>(
                      stream: AbsensiService.getAllBawahan(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.people_outline,
                                  size: isWeb ? 80 : 64,
                                  color: Colors.grey.shade300,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Belum ada bawahan',
                                  style: TextStyle(
                                    fontSize: isWeb ? 18 : 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        final bawahan = snapshot.data!;

                        return ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 24 : 16,
                            vertical: isWeb ? 12 : 8,
                          ),
                          itemCount: bawahan.length,
                          itemBuilder: (context, index) {
                            return _buildBawahanCard(bawahan[index], isWeb);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(bool isWeb) {
    return StreamBuilder<List<AbsensiModel>>(
      stream: AbsensiService.getAbsensiHistory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: isWeb ? 80 : 64,
                  color: Colors.grey.shade300,
                ),
                SizedBox(height: 16),
                Text(
                  'Belum ada riwayat absensi',
                  style: TextStyle(
                    fontSize: isWeb ? 18 : 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        }

        final absensiList = snapshot.data!;

        return ListView.builder(
          padding: EdgeInsets.all(isWeb ? 24 : 16),
          itemCount: absensiList.length,
          itemBuilder: (context, index) {
            return _buildAbsensiHistoryCard(absensiList[index], isWeb);
          },
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isWeb) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Hadir',
            (_todayStats['hadir'] ?? 0).toString(),
            Icons.check_circle,
            Colors.green,
            isWeb,
          ),
        ),
        SizedBox(width: isWeb ? 12 : 8),
        Expanded(
          child: _buildStatCard(
            'Izin',
            (_todayStats['izin'] ?? 0).toString(),
            Icons.info,
            Colors.blue,
            isWeb,
          ),
        ),
        SizedBox(width: isWeb ? 12 : 8),
        Expanded(
          child: _buildStatCard(
            'Sakit',
            (_todayStats['sakit'] ?? 0).toString(),
            Icons.local_hospital,
            Colors.orange,
            isWeb,
          ),
        ),
        SizedBox(width: isWeb ? 12 : 8),
        Expanded(
          child: _buildStatCard(
            'Alpha',
            (_todayStats['alpha'] ?? 0).toString(),
            Icons.cancel,
            Colors.red,
            isWeb,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: isWeb ? 8 : 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: isWeb ? 24 : 20),
          SizedBox(height: isWeb ? 8 : 6),
          Text(
            value,
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: isWeb ? 12 : 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBawahanCard(UserModel bawahan, bool isWeb) {
    return FutureBuilder<AbsensiModel?>(
      future: AbsensiService.getTodayAbsensi(bawahan.id, _selectedDate),
      builder: (context, snapshot) {
        final absensi = snapshot.data;
        final hasAbsensi = absensi != null;

        return Card(
          margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(isWeb ? 16 : 12),
            leading: CircleAvatar(
              backgroundColor: hasAbsensi 
                  ? absensi.status.statusColor 
                  : Colors.grey,
              child: Icon(
                hasAbsensi ? absensi.status.statusIcon : Icons.person,
                color: Colors.white,
              ),
            ),
            title: Text(
              bawahan.name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4),
                if (hasAbsensi) ...[
                  Text(
                    'Status: ${absensi.status.statusDisplayName}',
                    style: TextStyle(fontSize: isWeb ? 14 : 12),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Lokasi: ${absensi.lokasiName}',
                    style: TextStyle(fontSize: isWeb ? 12 : 11),
                  ),
                ] else
                  Text(
                    'Belum absen',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
              ],
            ),
            trailing: !hasAbsensi
                ? IconButton(
                    onPressed: () => _showSingleAbsensiDialog(bawahan),
                    icon: Icon(Icons.add_circle, color: Colors.purple),
                    tooltip: 'Absen',
                  )
                : null,
          ),
        );
      },
    );
  }

  Widget _buildAbsensiHistoryCard(AbsensiModel absensi, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isWeb ? 16 : 12),
        leading: CircleAvatar(
          backgroundColor: absensi.status.statusColor,
          child: Icon(
            absensi.status.statusIcon,
            color: Colors.white,
          ),
        ),
        title: Text(
          absensi.bawahanName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: isWeb ? 16 : 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              '${absensi.formattedDateTime} • ${absensi.status.statusDisplayName}',
              style: TextStyle(fontSize: isWeb ? 14 : 12),
            ),
            SizedBox(height: 2),
            Text(
              'Lokasi: ${absensi.lokasiName}',
              style: TextStyle(fontSize: isWeb ? 12 : 11),
            ),
            Text(
              'Dibuat oleh: ${absensi.koordinatorName}',
              style: TextStyle(fontSize: isWeb ? 12 : 11),
            ),
          ],
        ),
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _loadTodayStats();
      });
    }
  }

  void _showSingleAbsensiDialog(UserModel bawahan) async {
    final currentUser = await UserService.getCurrentUser();
    
    if (currentUser == null || currentUser.locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi Anda belum ditugaskan. Hubungi admin.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final location = await LocationService.getLocationById(currentUser.locationId!);
    
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi tidak ditemukan. Hubungi admin untuk update lokasi.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _SingleAbsensiDialog(
        bawahan: bawahan,
        date: _selectedDate,
        location: location,
        onSaved: _loadTodayStats,
      ),
    );
  }

  void _showBulkAbsensiDialog(String projectId) {
    showDialog(
      context: context,
      builder: (context) => _BulkAbsensiDialog(
        projectId: projectId,
        date: _selectedDate,
        onSaved: _loadTodayStats,
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Single Absensi Dialog
class _SingleAbsensiDialog extends StatefulWidget {
  final UserModel bawahan;
  final DateTime date;
  final LocationModel location;
  final VoidCallback onSaved;

  const _SingleAbsensiDialog({
    required this.bawahan,
    required this.date,
    required this.location,
    required this.onSaved,
  });

  @override
  _SingleAbsensiDialogState createState() => _SingleAbsensiDialogState();
}

class _SingleAbsensiDialogState extends State<_SingleAbsensiDialog> {
  StatusAbsensi _selectedStatus = StatusAbsensi.hadir;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
      ),
      child: Container(
        width: isWeb ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_add, color: Colors.purple),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Absensi ${widget.bawahan.name}',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Display (Read-only)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Lokasi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.location.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.location.fullAddress,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // Status Selection
                    Text(
                      'Pilih Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    ...StatusAbsensi.values.map((status) {
                      return RadioListTile<StatusAbsensi>(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Icon(
                              status.statusIcon, 
                              color: status.statusColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(status.statusDisplayName),
                          ],
                        ),
                        value: status,
                        groupValue: _selectedStatus,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveAbsensi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveAbsensi() async {
    Navigator.pop(context);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) {
        throw Exception('User not found');
      }

      await AbsensiService.createAbsensi(
        widget.bawahan.id,
        widget.bawahan.name,
        widget.date,
        _selectedStatus,
        currentUser.uid,
        currentUserData.name,
        widget.location.id,
        widget.location.name,
      );

      widget.onSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absensi berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Bulk Absensi Dialog with Auto Location
class _BulkAbsensiDialog extends StatefulWidget {
  final String projectId;
  final DateTime date;
  final VoidCallback onSaved;

  const _BulkAbsensiDialog({
    required this.projectId,
    required this.date,
    required this.onSaved,
  });

  @override
  _BulkAbsensiDialogState createState() => _BulkAbsensiDialogState();
}

class _BulkAbsensiDialogState extends State<_BulkAbsensiDialog> {
  StatusAbsensi _selectedStatus = StatusAbsensi.hadir;
  String? _lokasiId;
  String _lokasiName = '';
  String _lokasiFullAddress = '';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null || currentUser.locationId == null) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final location = await LocationService.getLocationById(currentUser.locationId!);
      if (location != null) {
        setState(() {
          _lokasiId = location.id;
          _lokasiName = location.name;
          _lokasiFullAddress = location.fullAddress;
          _isLoadingLocation = false;
        });
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      print('Error loading user location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 20 : 16),
      ),
      child: Container(
        width: isWeb ? 500 : null,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * (isWeb ? 0.8 : 0.85),
          maxWidth: isWeb ? 500 : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group_add, 
                    color: Colors.purple,
                    size: isWeb ? 24 : 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Absensi Massal',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: isWeb ? 24 : 20),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location Display (Read-only from user data)
                    if (_isLoadingLocation)
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Text('Memuat lokasi...'),
                          ],
                        ),
                      )
                    else if (_lokasiId != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Lokasi',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              _lokasiName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _lokasiFullAddress,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber, color: Colors.orange.shade600),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Anda belum memiliki lokasi yang ditugaskan. Hubungi admin.',
                                style: TextStyle(color: Colors.orange.shade600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: isWeb ? 20 : 16),
                    
                    Text(
                      'Status Default untuk Semua Bawahan:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    ...StatusAbsensi.values.map((status) {
                      return RadioListTile<StatusAbsensi>(
                        contentPadding: EdgeInsets.symmetric(horizontal: 0),
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status.statusIcon, 
                              color: status.statusColor, 
                              size: isWeb ? 22 : 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              status.statusDisplayName,
                              style: TextStyle(fontSize: isWeb ? 16 : 14),
                            ),
                          ],
                        ),
                        value: status,
                        groupValue: _selectedStatus,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Batal',
                        style: TextStyle(fontSize: isWeb ? 16 : 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _lokasiId == null ? null : _saveBulkAbsensi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                      ),
                      child: Text(
                        'Simpan Semua',
                        style: TextStyle(fontSize: isWeb ? 16 : 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveBulkAbsensi() async {
    if (_lokasiId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lokasi tidak ditemukan. Hubungi admin untuk menugaskan lokasi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) {
        throw Exception('User not found');
      }

      final bawahanSnapshot = await AbsensiService.getAllBawahan().first;
      
      await AbsensiService.bulkCreateAbsensi(
        bawahanSnapshot,
        widget.date,
        _selectedStatus,
        currentUser.uid,
        currentUserData.name,
        _lokasiId!,
        _lokasiName,
      );
      
      widget.onSaved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Absensi massal berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Extension for StatusAbsensi
extension StatusAbsensiExtension on StatusAbsensi {
  String get statusDisplayName {
    switch (this) {
      case StatusAbsensi.hadir:
        return 'Hadir';
      case StatusAbsensi.izin:
        return 'Izin';
      case StatusAbsensi.sakit:
        return 'Sakit';
      case StatusAbsensi.alpha:
        return 'Alpha';
    }
  }

  Color get statusColor {
    switch (this) {
      case StatusAbsensi.hadir:
        return Colors.green;
      case StatusAbsensi.izin:
        return Colors.blue;
      case StatusAbsensi.sakit:
        return Colors.orange;
      case StatusAbsensi.alpha:
        return Colors.red;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case StatusAbsensi.hadir:
        return Icons.check_circle;
      case StatusAbsensi.izin:
        return Icons.info;
      case StatusAbsensi.sakit:
        return Icons.local_hospital;
      case StatusAbsensi.alpha:
        return Icons.cancel;
    }
  }
}