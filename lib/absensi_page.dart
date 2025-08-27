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
    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(icon: Icon(Icons.today), text: 'Hari Ini'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildHistoryTab(),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    return Column(
      children: [
        // Date Selector & Stats
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // Date Picker
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _selectDate,
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.purple),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tanggal Absensi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Stats Grid
              Row(
                children: [
                  Expanded(child: _buildStatCard('Hadir', _todayStats['hadir'] ?? 0, Colors.green)),
                  SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Izin', _todayStats['izin'] ?? 0, Colors.blue)),
                  SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Sakit', _todayStats['sakit'] ?? 0, Colors.orange)),
                  SizedBox(width: 8),
                  Expanded(child: _buildStatCard('Alpha', _todayStats['alpha'] ?? 0, Colors.red)),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Total Bawahan',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_todayStats['total_bawahan'] ?? 0}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Belum Absen',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '${_todayStats['belum_absen'] ?? 0}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Action Button
        if ((_todayStats['belum_absen'] ?? 0) > 0)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showBulkAbsensiDialog,
              icon: Icon(Icons.group_add),
              label: Text('Absensi Massal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: Size(0, 45),
              ),
            ),
          ),
        
        // Bawahan List
        Expanded(
          child: StreamBuilder<List<UserModel>>(
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
                return _buildEmptyBawahanState();
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

                  return ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: bawahanList.length,
                    itemBuilder: (context, index) {
                      final bawahan = bawahanList[index];
                      final absensi = absensiMap[bawahan.id];
                      return _buildBawahanCard(bawahan, absensi);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab() {
    return Column(
      children: [
        // Filter Section
        // Container(
        //   padding: EdgeInsets.all(16),
        //   child: Row(
        //     children: [
        //       Expanded(
        //         child: ElevatedButton.icon(
        //           onPressed: _showMonthlyReport,
        //           icon: Icon(Icons.bar_chart),
        //           label: Text('Laporan Bulanan'),
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.blue,
        //             foregroundColor: Colors.white,
        //           ),
        //         ),
        //       ),
        //       SizedBox(width: 12),
        //       Expanded(
        //         child: ElevatedButton.icon(
        //           onPressed: _showDetailHistory,
        //           icon: Icon(Icons.history),
        //           label: Text('Riwayat Detail'),
        //           style: ElevatedButton.styleFrom(
        //             backgroundColor: Colors.green,
        //             foregroundColor: Colors.white,
        //           ),
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        
        // Recent History
        Expanded(
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
                  .toList(); // Show last 20 records

              if (recentAbsensi.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                      SizedBox(height: 16),
                      Text('Belum ada riwayat absensi'),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: recentAbsensi.length,
                itemBuilder: (context, index) {
                  return _buildHistoryCard(recentAbsensi[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBawahanState() {
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
            'Tidak ada bawahan terdaftar',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hubungi admin untuk menambah bawahan',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBawahanCard(UserModel bawahan, AbsensiModel? absensi) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              backgroundColor: Colors.purple.shade100,
              child: Text(
                bawahan.name.isNotEmpty ? bawahan.name[0].toUpperCase() : 'B',
                style: TextStyle(
                  color: Colors.purple.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bawahan.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    bawahan.email,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  if (absensi != null) ...[
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: absensi.statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(absensi.statusIcon, size: 14, color: absensi.statusColor),
                          SizedBox(width: 4),
                          Text(
                            absensi.statusDisplayName,
                            style: TextStyle(
                              color: absensi.statusColor,
                              fontSize: 12,
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
                          fontSize: 11,
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
                child: Text('Absen', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  minimumSize: Size(60, 30),
                ),
              )
            else
              IconButton(
                onPressed: () => _showAbsensiDialog(bawahan, absensi),
                icon: Icon(Icons.edit, color: Colors.grey.shade600),
                tooltip: 'Edit Absensi',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(AbsensiModel absensi) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: absensi.statusColor.withOpacity(0.1),
          child: Icon(absensi.statusIcon, color: absensi.statusColor, size: 20),
        ),
        title: Text(
          absensi.bawahanName,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${absensi.formattedTanggal} - ${absensi.lokasiName}',
          style: TextStyle(fontSize: 12),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: absensi.statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            absensi.statusDisplayName,
            style: TextStyle(
              color: absensi.statusColor,
              fontSize: 11,
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
    StatusAbsensi selectedStatus = existingAbsensi?.status ?? StatusAbsensi.hadir;
    final keteranganController = TextEditingController(text: existingAbsensi?.keterangan ?? '');
    String selectedLokasiId = '';
    String selectedLokasiName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingAbsensi == null ? 'Absensi ${bawahan.name}' : 'Edit Absensi'),
          content: SingleChildScrollView(
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
                        border: OutlineInputBorder(),
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
                SizedBox(height: 16),
                
                // Status options
                ...StatusAbsensi.values.map((status) {
                  return RadioListTile<StatusAbsensi>(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(status.statusIcon, color: status.statusColor, size: 20),
                        SizedBox(width: 8),
                        Text(status.statusDisplayName),
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
                
                SizedBox(height: 16),
                
                // Keterangan
                TextField(
                  controller: keteranganController,
                  decoration: InputDecoration(
                    labelText: 'Keterangan (Opsional)',
                    border: OutlineInputBorder(),
                    hintText: 'Tambahkan keterangan jika diperlukan...',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
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
              ),
              child: Text(existingAbsensi == null ? 'Simpan' : 'Update'),
            ),
          ],
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
    StatusAbsensi selectedStatus = StatusAbsensi.hadir;
    String selectedLokasiId = '';
    String selectedLokasiName = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Absensi Massal'),
          content: Column(
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
                      border: OutlineInputBorder(),
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
              SizedBox(height: 16),
              
              Text(
                'Status Default untuk Semua Bawahan:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              
              ...StatusAbsensi.values.map((status) {
                return RadioListTile<StatusAbsensi>(
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.statusIcon, color: status.statusColor, size: 20),
                      SizedBox(width: 8),
                      Text(status.statusDisplayName),
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: selectedLokasiId.isEmpty ? null : () => _saveBulkAbsensi(
                selectedStatus,
                selectedLokasiId,
                selectedLokasiName,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
              child: Text('Simpan Semua'),
            ),
          ],
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

      // Get all bawahan
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

  void _showMonthlyReport() {
    // Implementasi laporan bulanan
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur laporan bulanan akan segera hadir')),
    );
  }

  void _showDetailHistory() {
    // Implementasi riwayat detail  
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fitur riwayat detail akan segera hadir')),
    );
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