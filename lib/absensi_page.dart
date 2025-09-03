import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'absensi_service.dart';
import 'absensi_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';
import 'user_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

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
        bottom: TabBar(
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
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(isWeb),
          _buildHistoryTab(isWeb),
        ],
      ),
    );
  }

  Widget _buildTodayTab(bool isWeb) {
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
                        onPressed: _showBulkAbsensiDialog,
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
                            vertical: isWeb ? 16 : 12,
                          ),
                        ),
                      ),
                    ),
                  
                  // Bawahan List
                  Expanded(
                    child: _buildBawahanList(isWeb),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isWeb) {
    if (isWeb) {
      // Single row for web
      return Row(
        children: [
          Expanded(child: _buildStatCard('Hadir', _todayStats['hadir'] ?? 0, Colors.green, isWeb)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Izin', _todayStats['izin'] ?? 0, Colors.blue, isWeb)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Sakit', _todayStats['sakit'] ?? 0, Colors.orange, isWeb)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Alpha', _todayStats['alpha'] ?? 0, Colors.red, isWeb)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Total', _todayStats['total_bawahan'] ?? 0, Colors.purple, isWeb)),
          SizedBox(width: 12),
          Expanded(child: _buildStatCard('Belum', _todayStats['belum_absen'] ?? 0, Colors.grey, isWeb)),
        ],
      );
    } else {
      // Two rows for mobile
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Hadir', _todayStats['hadir'] ?? 0, Colors.green, isWeb)),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard('Izin', _todayStats['izin'] ?? 0, Colors.blue, isWeb)),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard('Sakit', _todayStats['sakit'] ?? 0, Colors.orange, isWeb)),
              SizedBox(width: 8),
              Expanded(child: _buildStatCard('Alpha', _todayStats['alpha'] ?? 0, Colors.red, isWeb)),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Total Bawahan', _todayStats['total_bawahan'] ?? 0, Colors.purple, isWeb),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Belum Absen', _todayStats['belum_absen'] ?? 0, Colors.grey, isWeb),
              ),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildBawahanList(bool isWeb) {
    return StreamBuilder<List<UserModel>>(
      stream: AbsensiService.getAllBawahan(),
      builder: (context, bawahanSnapshot) {
        if (bawahanSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (bawahanSnapshot.hasError) {
          return Center(child: Text('Error: ${bawahanSnapshot.error}'));
        }

        final bawahanList = bawahanSnapshot.data ?? [];

        if (bawahanList.isEmpty) {
          return _buildEmptyBawahanState(isWeb);
        }

        return StreamBuilder<List<AbsensiModel>>(
          stream: AbsensiService.getAbsensiByDate(
            _selectedDate,
            FirebaseAuth.instance.currentUser?.uid ?? '',
          ),
          builder: (context, absensiSnapshot) {
            final absensiList = absensiSnapshot.data ?? [];
            final Map<String, AbsensiModel> absensiMap = {};
            
            for (final absensi in absensiList) {
              absensiMap[absensi.bawahanId] = absensi;
            }

            if (isWeb) {
              // Grid layout for web
              return GridView.builder(
                padding: EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 16,
                  childAspectRatio: 2.8,
                ),
                itemCount: bawahanList.length,
                itemBuilder: (context, index) {
                  final bawahan = bawahanList[index];
                  final absensi = absensiMap[bawahan.id];
                  return _buildBawahanCard(bawahan, absensi, isWeb);
                },
              );
            } else {
              // List layout for mobile
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: bawahanList.length,
                itemBuilder: (context, index) {
                  final bawahan = bawahanList[index];
                  final absensi = absensiMap[bawahan.id];
                  return _buildBawahanCard(bawahan, absensi, isWeb);
                },
              );
            }
          },
        );
      },
    );
  }

  Widget _buildHistoryTab(bool isWeb) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
        child: StreamBuilder<List<AbsensiModel>>(
          stream: AbsensiService.getCurrentCoordinatorAbsensi(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final recentAbsensi = (snapshot.data ?? [])
                .take(20)
                .toList();

            if (recentAbsensi.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history, 
                      size: isWeb ? 80 : 64, 
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: isWeb ? 24 : 16),
                    Text(
                      'Belum ada riwayat absensi',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 16,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(isWeb ? 24 : 16),
              itemCount: recentAbsensi.length,
              itemBuilder: (context, index) {
                return _buildHistoryCard(recentAbsensi[index], isWeb);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isWeb ? 16 : 12,
        horizontal: isWeb ? 12 : 8,
      ),
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
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: isWeb ? 24 : 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isWeb ? 6 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 12 : 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBawahanState(bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: isWeb ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            'Tidak ada bawahan terdaftar',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hubungi admin untuk menambah bawahan',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isWeb ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBawahanCard(UserModel bawahan, AbsensiModel? absensi, bool isWeb) {
    return Card(
      margin: isWeb ? EdgeInsets.zero : EdgeInsets.only(bottom: 12),
      elevation: isWeb ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isWeb ? 20 : 16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              radius: isWeb ? 24 : 20,
              child: Text(
                bawahan.name.isNotEmpty ? bawahan.name[0].toUpperCase() : 'B',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.bold,
                  fontSize: isWeb ? 18 : 14,
                ),
              ),
            ),
            SizedBox(width: isWeb ? 16 : 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bawahan.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isWeb ? 18 : 16,
                    ),
                  ),
                  SizedBox(height: isWeb ? 6 : 4),
                  Text(
                    bawahan.email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isWeb ? 14 : 12,
                    ),
                  ),
                  if (absensi != null) ...[
                    SizedBox(height: isWeb ? 12 : 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 12 : 8,
                        vertical: isWeb ? 6 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: absensi.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            absensi.statusIcon, 
                            size: isWeb ? 16 : 14, 
                            color: absensi.statusColor,
                          ),
                          SizedBox(width: 4),
                          Text(
                            absensi.statusDisplayName,
                            style: TextStyle(
                              color: absensi.statusColor,
                              fontSize: isWeb ? 14 : 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (absensi.keterangan != null && absensi.keterangan!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        absensi.keterangan!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: isWeb ? 13 : 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            
            // Action Button
            if (absensi == null)
              ElevatedButton(
                onPressed: () => _showAbsensiDialog(bawahan),
                child: Text(
                  'Absen', 
                  style: TextStyle(fontSize: isWeb ? 14 : 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(isWeb ? 80 : 60, isWeb ? 36 : 30),
                  padding: EdgeInsets.symmetric(
                    horizontal: isWeb ? 16 : 12,
                    vertical: isWeb ? 8 : 4,
                  ),
                ),
              )
            else
              IconButton(
                onPressed: () => _showAbsensiDialog(bawahan, absensi),
                icon: Icon(
                  Icons.edit, 
                  color: Colors.grey.shade600,
                  size: isWeb ? 24 : 20,
                ),
                tooltip: 'Edit Absensi',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AbsensiModel absensi, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
      elevation: isWeb ? 3 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(isWeb ? 20 : 16),
        leading: CircleAvatar(
          backgroundColor: absensi.statusColor.withOpacity(0.1),
          radius: isWeb ? 24 : 20,
          child: Icon(
            absensi.statusIcon, 
            color: absensi.statusColor, 
            size: isWeb ? 24 : 20,
          ),
        ),
        title: Text(
          absensi.bawahanName,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: isWeb ? 16 : 14,
          ),
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(top: 4),
          child: Text(
            '${absensi.formattedTanggal} - ${absensi.lokasiName}',
            style: TextStyle(
              fontSize: isWeb ? 14 : 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isWeb ? 12 : 8,
            vertical: isWeb ? 6 : 4,
          ),
          decoration: BoxDecoration(
            color: absensi.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            absensi.statusDisplayName,
            style: TextStyle(
              color: absensi.statusColor,
              fontSize: isWeb ? 12 : 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 7)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadTodayStats();
    }
  }

  void _showAbsensiDialog(UserModel bawahan, [AbsensiModel? existingAbsensi]) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    StatusAbsensi selectedStatus = existingAbsensi?.status ?? StatusAbsensi.hadir;
    final keteranganController = TextEditingController(text: existingAbsensi?.keterangan ?? '');
    String selectedLokasiId = '';
    String selectedLokasiName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                        Icons.how_to_reg, 
                        color: Colors.purple,
                        size: isWeb ? 24 : 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          existingAbsensi == null ? 'Absensi ${bawahan.name}' : 'Edit Absensi',
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
                      children: [
                        // Lokasi dropdown
                        StreamBuilder<List<LocationModel>>(
                          stream: LocationService.getAllLocations(),
                          builder: (context, snapshot) {
                            final locations = snapshot.data ?? [];
                            
                            return DropdownButtonFormField<String>(
                              value: selectedLokasiId.isEmpty ? null : selectedLokasiId,
                              decoration: InputDecoration(
                                labelText: 'Lokasi *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: locations.map((location) {
                                return DropdownMenuItem(
                                  value: location.id,
                                  child: Text('${location.name} - ${location.city}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  final selectedLocation = locations.firstWhere((loc) => loc.id == value);
                                  setDialogState(() {
                                    selectedLokasiId = value;
                                    selectedLokasiName = selectedLocation.name;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        SizedBox(height: isWeb ? 20 : 16),
                        
                        // Status options
                        Text(
                          'Status Kehadiran:',
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
                            groupValue: selectedStatus,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => selectedStatus = value);
                              }
                            },
                          );
                        }),
                        
                        SizedBox(height: isWeb ? 20 : 16),
                        
                        // Keterangan
                        TextField(
                          controller: keteranganController,
                          decoration: InputDecoration(
                            labelText: 'Keterangan (Opsional)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            hintText: 'Tambahkan keterangan jika diperlukan...',
                          ),
                          maxLines: 2,
                        ),
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
                          onPressed: selectedLokasiId.isEmpty ? null : () => _saveAbsensi(
                            bawahan,
                            selectedStatus,
                            keteranganController.text.trim(),
                            selectedLokasiId,
                            selectedLokasiName,
                            existingAbsensi,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                          ),
                          child: Text(
                            existingAbsensi == null ? 'Simpan' : 'Update',
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
        ),
      ),
    );
  }

  void _saveAbsensi(
    UserModel bawahan,
    StatusAbsensi status,
    String keterangan,
    String lokasiId,
    String lokasiName,
    AbsensiModel? existingAbsensi,
  ) async {
    Navigator.pop(context);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) {
        throw Exception('User not found');
      }

      final absensi = AbsensiModel(
        absensiId: existingAbsensi?.absensiId ?? '',
        bawahanId: bawahan.id,
        bawahanName: bawahan.name,
        koordinatorId: currentUser.uid,
        koordinatorName: currentUserData.name,
        lokasiId: lokasiId,
        lokasiName: lokasiName,
        tanggal: _selectedDate,
        status: status,
        keterangan: keterangan.isEmpty ? null : keterangan,
        createdAt: existingAbsensi?.createdAt ?? DateTime.now(),
      );

      await AbsensiService.createOrUpdateAbsensi(absensi);
      _loadTodayStats();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingAbsensi == null ? 'Absensi berhasil disimpan' : 'Absensi berhasil diupdate'),
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

  void _showBulkAbsensiDialog() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    StatusAbsensi selectedStatus = StatusAbsensi.hadir;
    String selectedLokasiId = '';
    String selectedLokasiName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                      children: [
                        StreamBuilder<List<LocationModel>>(
                          stream: LocationService.getAllLocations(),
                          builder: (context, snapshot) {
                            final locations = snapshot.data ?? [];
                            
                            return DropdownButtonFormField<String>(
                              value: selectedLokasiId.isEmpty ? null : selectedLokasiId,
                              decoration: InputDecoration(
                                labelText: 'Lokasi *',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: locations.map((location) {
                                return DropdownMenuItem(
                                  value: location.id,
                                  child: Text('${location.name} - ${location.city}'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  final selectedLocation = locations.firstWhere((loc) => loc.id == value);
                                  setDialogState(() {
                                    selectedLokasiId = value;
                                    selectedLokasiName = selectedLocation.name;
                                  });
                                }
                              },
                            );
                          },
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
                            groupValue: selectedStatus,
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() => selectedStatus = value);
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
                          onPressed: selectedLokasiId.isEmpty ? null : () => _saveBulkAbsensi(
                            selectedStatus,
                            selectedLokasiId,
                            selectedLokasiName,
                          ),
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
        ),
      ),
    );
  }

  void _saveBulkAbsensi(
    StatusAbsensi status,
    String lokasiId,
    String lokasiName,
  ) async {
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
        _selectedDate,
        status,
        currentUser.uid,
        currentUserData.name,
        lokasiId,
        lokasiName,
      );
      
      _loadTodayStats();
      
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Extension untuk StatusAbsensi
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