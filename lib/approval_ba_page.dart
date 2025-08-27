import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'berita_acara_service.dart';
import 'berita_acara_model.dart';
import 'user_service.dart';

class ApprovalBAPage extends StatefulWidget {
  @override
  _ApprovalBAPageState createState() => _ApprovalBAPageState();
}

class _ApprovalBAPageState extends State<ApprovalBAPage> {
  final _searchController = TextEditingController();
  StatusBA? _selectedStatusFilter;
  JenisBA? _selectedJenisFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approval Berita Acara'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berita acara...',
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
                
                // Quick Filter Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickFilterChip('Semua', null),
                      SizedBox(width: 8),
                      _buildQuickFilterChip('Pending', StatusBA.pending),
                      SizedBox(width: 8),
                      _buildQuickFilterChip('Approved', StatusBA.approved),
                      SizedBox(width: 8),
                      _buildQuickFilterChip('Rejected', StatusBA.rejected),
                      SizedBox(width: 8),
                      _buildJenisFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Stats Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: FutureBuilder<Map<String, dynamic>>(
              future: BeritaAcaraService.getBeritaAcaraStats(),
              builder: (context, snapshot) {
                final stats = snapshot.data ?? {};
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Total', '${stats['total'] ?? 0}', Colors.blue),
                    _buildStatItem('Pending', '${stats['pending'] ?? 0}', Colors.orange),
                    _buildStatItem('Approved', '${stats['approved'] ?? 0}', Colors.green),
                    _buildStatItem('Rejected', '${stats['rejected'] ?? 0}', Colors.red),
                  ],
                );
              },
            ),
          ),
          
          // Berita Acara List
          Expanded(
            child: StreamBuilder<List<BeritaAcaraModel>>(
              stream: BeritaAcaraService.getAllBeritaAcara(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final beritaAcaraList = _filterBeritaAcara(snapshot.data ?? []);

                if (beritaAcaraList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: beritaAcaraList.length,
                  itemBuilder: (context, index) {
                    return _buildBeritaAcaraCard(beritaAcaraList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, StatusBA? status) {
    final isSelected = _selectedStatusFilter == status;
    
    Color getStatusColor(StatusBA? status) {
      if (status == null) return Colors.grey.shade600;
      switch (status) {
        case StatusBA.pending:
          return Colors.orange;
        case StatusBA.approved:
          return Colors.green;
        case StatusBA.rejected:
          return Colors.red;
      }
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedStatusFilter = selected ? status : null;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: getStatusColor(status).withOpacity(0.2),
      checkmarkColor: getStatusColor(status),
      labelStyle: TextStyle(
        color: isSelected 
          ? getStatusColor(status)
          : Colors.grey.shade600,
        fontSize: 12,
      ),
    );
  }

  Widget _buildJenisFilter() {
    String getJenisDisplayName(JenisBA jenis) {
      switch (jenis) {
        case JenisBA.pembukaan:
          return 'Pembukaan';
        case JenisBA.kendala:
          return 'Kendala';
        case JenisBA.penutupan:
          return 'Penutupan';
        case JenisBA.monitoring:
          return 'Monitoring';
        case JenisBA.evaluasi:
          return 'Evaluasi';
        case JenisBA.lainnya:
          return 'Lainnya';
      }
    }

    return PopupMenuButton<JenisBA?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedJenisFilter != null ? Colors.purple.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color: _selectedJenisFilter != null ? Colors.purple.shade600 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedJenisFilter != null ? getJenisDisplayName(_selectedJenisFilter!) : 'Jenis',
              style: TextStyle(
                color: _selectedJenisFilter != null ? Colors.purple.shade600 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Semua Jenis'),
        ),
        ...JenisBA.values.map((jenis) => PopupMenuItem(
          value: jenis,
          child: Text(getJenisDisplayName(jenis)),
        )),
      ],
      onSelected: (value) {
        setState(() => _selectedJenisFilter = value);
      },
    );
  }

  Widget _buildStatItem(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada berita acara',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Semua berita acara sudah diproses',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeritaAcaraCard(BeritaAcaraModel ba) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ba.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ba.statusDisplayName,
                              style: TextStyle(
                                color: ba.statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ba.jenisBADisplayName,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        ba.lokasiName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            ba.koordinatorName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Text(
                            ba.formattedDate,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Action Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBeritaAcaraAction(value, ba),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Detail'),
                        ],
                      ),
                    ),
                    if (ba.status == StatusBA.pending) ...[
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, size: 20, color: Colors.green),
                            SizedBox(width: 8),
                            Text('Approve', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'reject',
                        child: Row(
                          children: [
                            Icon(Icons.cancel, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Reject', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Isi BA Preview
            Text(
              ba.isiBA,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            SizedBox(height: 12),
            
            // Bottom Info Row
            Row(
              children: [
                // Lampiran indicator
                if (ba.lampiranUrls.isNotEmpty) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attach_file, size: 12, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          '${ba.lampiranUrls.length} file',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                ],
                
                // Quick Actions for Pending
                if (ba.status == StatusBA.pending) ...[
                  Spacer(),
                  ElevatedButton(
                    onPressed: () => _handleBeritaAcaraAction('approve', ba),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: Size(60, 32),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text('Approve', style: TextStyle(fontSize: 12)),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _handleBeritaAcaraAction('reject', ba),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      minimumSize: Size(60, 32),
                      padding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),

            // Rejection reason
            if (ba.status == StatusBA.rejected && ba.rejectionReason != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alasan: ${ba.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Approved info
            if (ba.status == StatusBA.approved && ba.approvedBy != null) ...[
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 16, color: Colors.green.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Disetujui pada ${ba.approvedAt != null ? ba.formattedDate : 'N/A'}',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<BeritaAcaraModel> _filterBeritaAcara(List<BeritaAcaraModel> beritaAcaraList) {
    return beritaAcaraList.where((ba) {
      final matchesSearch = ba.lokasiName.toLowerCase().contains(_searchQuery) ||
          ba.isiBA.toLowerCase().contains(_searchQuery) ||
          ba.koordinatorName.toLowerCase().contains(_searchQuery) ||
          ba.jenisBADisplayName.toLowerCase().contains(_searchQuery);
      
      final matchesStatus = _selectedStatusFilter == null || ba.status == _selectedStatusFilter;
      final matchesJenis = _selectedJenisFilter == null || ba.jenisBA == _selectedJenisFilter;
      
      return matchesSearch && matchesStatus && matchesJenis;
    }).toList();
  }

  void _handleBeritaAcaraAction(String action, BeritaAcaraModel ba) {
    switch (action) {
      case 'detail':
        _showDetailDialog(ba);
        break;
      case 'approve':
        _approveBeritaAcara(ba);
        break;
      case 'reject':
        _showRejectDialog(ba);
        break;
    }
  }

  void _showDetailDialog(BeritaAcaraModel ba) {
    showDialog(
      context: context,
      builder: (context) => ApprovalBADetailDialog(beritaAcara: ba),
    );
  }

  void _approveBeritaAcara(BeritaAcaraModel ba) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Approve Berita Acara'),
          ],
        ),
        content: Text('Apakah Anda yakin ingin menyetujui berita acara ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _confirmApprove(ba),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _confirmApprove(BeritaAcaraModel ba) async {
    Navigator.pop(context);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await BeritaAcaraService.approveBeritaAcara(ba.baId, currentUser.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berita acara berhasil disetujui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showRejectDialog(BeritaAcaraModel ba) {
    final _reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red),
            SizedBox(width: 8),
            Text('Reject Berita Acara'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Berikan alasan penolakan:'),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan penolakan',
                border: OutlineInputBorder(),
                hintText: 'Jelaskan mengapa berita acara ditolak...',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _confirmReject(ba, _reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmReject(BeritaAcaraModel ba, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alasan penolakan wajib diisi')),
      );
      return;
    }
    
    Navigator.pop(context);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await BeritaAcaraService.rejectBeritaAcara(ba.baId, currentUser.uid, reason.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berita acara berhasil ditolak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Detail Dialog Widget for Approval
class ApprovalBADetailDialog extends StatelessWidget {
  final BeritaAcaraModel beritaAcara;

  const ApprovalBADetailDialog({Key? key, required this.beritaAcara}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: beritaAcara.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.assignment, color: beritaAcara.statusColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Berita Acara',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          beritaAcara.lokasiName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: beritaAcara.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      beritaAcara.statusDisplayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
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
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Jenis', beritaAcara.jenisBADisplayName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Koordinator', beritaAcara.koordinatorName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Lokasi', beritaAcara.lokasiName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Tanggal', beritaAcara.formattedDate),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Isi BA
                    Text(
                      'Isi Berita Acara:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        beritaAcara.isiBA,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    // Lampiran
                    if (beritaAcara.lampiranUrls.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Lampiran (${beritaAcara.lampiranUrls.length} file):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: beritaAcara.lampiranUrls.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => _showImageDialog(context, beritaAcara.lampiranUrls[index]),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  beritaAcara.lampiranUrls[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.broken_image, color: Colors.grey),
                                          Text('Error', style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            if (beritaAcara.status == StatusBA.pending) ...[
              Container(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade300,
                          foregroundColor: Colors.grey.shade700,
                        ),
                        child: Text('Tutup'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRejectFromDetail(context, beritaAcara);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: Text('Reject'),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _approveFromDetail(context, beritaAcara);
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        child: Text('Approve'),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Lampiran'),
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close),
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _approveFromDetail(BuildContext context, BeritaAcaraModel ba) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await BeritaAcaraService.approveBeritaAcara(ba.baId, currentUser.uid);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berita acara berhasil disetujui'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _showRejectFromDetail(BuildContext context, BeritaAcaraModel ba) {
    final _reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Berita Acara'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Berikan alasan penolakan:'),
            SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan penolakan',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _confirmRejectFromDetail(context, ba, _reasonController.text),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _confirmRejectFromDetail(BuildContext context, BeritaAcaraModel ba, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alasan penolakan wajib diisi')),
      );
      return;
    }
    
    Navigator.pop(context);
    
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await BeritaAcaraService.rejectBeritaAcara(ba.baId, currentUser.uid, reason.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berita acara berhasil ditolak'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}