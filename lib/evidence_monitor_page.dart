import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/user_model.dart';
import 'evidence_service.dart';
import 'evidence_model.dart';

class AdminEvidencePage extends StatefulWidget {
  @override
  _AdminEvidencePageState createState() => _AdminEvidencePageState();
}

class _AdminEvidencePageState extends State<AdminEvidencePage> {
  final _searchController = TextEditingController();
  StatusEvidence? _selectedStatusFilter;
  KategoriEvidence? _selectedKategoriFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Evidence'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showStatsDialog(),
            icon: Icon(Icons.analytics),
            tooltip: 'Statistik Evidence',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Colors.blue.shade50,
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari evidence...',
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

                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter(),
                      SizedBox(width: 8),
                      _buildKategoriFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Evidence List
          Expanded(
            child: StreamBuilder<List<EvidenceModel>>(
              stream: EvidenceService.getAllEvidence(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final evidenceList = _filterEvidence(snapshot.data ?? []);

                if (evidenceList.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: evidenceList.length,
                  itemBuilder: (context, index) {
                    return _buildEvidenceCard(evidenceList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    Color getStatusColor(StatusEvidence? status) {
      if (status == null) return Colors.grey.shade600;
      switch (status) {
        case StatusEvidence.pending:
          return Colors.orange;
        case StatusEvidence.approved:
          return Colors.green;
        case StatusEvidence.rejected:
          return Colors.red;
      }
    }

    return PopupMenuButton<StatusEvidence?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              _selectedStatusFilter != null
                  ? getStatusColor(_selectedStatusFilter).withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color:
                  _selectedStatusFilter != null
                      ? getStatusColor(_selectedStatusFilter)
                      : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedStatusFilter?.toString().split('.').last ?? 'Status',
              style: TextStyle(
                color:
                    _selectedStatusFilter != null
                        ? getStatusColor(_selectedStatusFilter)
                        : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Status')),
        ...StatusEvidence.values.map(
          (status) => PopupMenuItem(
            value: status,
            child: Text(status.toString().split('.').last),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() => _selectedStatusFilter = value);
      },
    );
  }

  Widget _buildKategoriFilter() {
    String getKategoriDisplayName(KategoriEvidence kategori) {
      switch (kategori) {
        case KategoriEvidence.foto:
          return 'Foto';
        case KategoriEvidence.video:
          return 'Video';
        case KategoriEvidence.dokumen:
          return 'Dokumen';
        case KategoriEvidence.lainnya:
          return 'Lainnya';
      }
    }

    return PopupMenuButton<KategoriEvidence?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              _selectedKategoriFilter != null
                  ? Colors.purple.shade100
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color:
                  _selectedKategoriFilter != null
                      ? Colors.purple.shade600
                      : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedKategoriFilter != null
                  ? getKategoriDisplayName(_selectedKategoriFilter!)
                  : 'Kategori',
              style: TextStyle(
                color:
                    _selectedKategoriFilter != null
                        ? Colors.purple.shade600
                        : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Kategori')),
        ...KategoriEvidence.values.map(
          (kategori) => PopupMenuItem(
            value: kategori,
            child: Text(getKategoriDisplayName(kategori)),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() => _selectedKategoriFilter = value);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada evidence',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Evidence akan muncul setelah koordinator mengupload',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence) {
    return GestureDetector(
      onTap: () => _showDetailDialog(evidence),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child: Stack(
                    children: [
                      // File content
                      evidence.isImage
                          ? Image.network(
                              evidence.fileUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildFileIcon(evidence);
                              },
                            )
                          : _buildFileIcon(evidence),
                      
                      // Status badge overlay
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evidence.statusDisplayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Uploader name
                    Text(
                      evidence.uploaderName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    
                    // Location
                    Text(
                      evidence.lokasiName,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),

                    // Category and date
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            evidence.kategoriDisplayName,
                            style: TextStyle(
                              color: evidence.kategoriColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Spacer(),
                        Text(
                          evidence.formattedDate.split(' ')[0], // Only date
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(EvidenceModel evidence) {
    return Container(
      decoration: BoxDecoration(
        color: evidence.kategoriColor.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              evidence.kategoriIcon,
              size: 32,
              color: evidence.kategoriColor,
            ),
            SizedBox(height: 4),
            Text(
              evidence.kategoriDisplayName,
              style: TextStyle(
                color: evidence.kategoriColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EvidenceModel> _filterEvidence(List<EvidenceModel> evidenceList) {
    return evidenceList.where((evidence) {
      final matchesSearch =
          evidence.lokasiName.toLowerCase().contains(_searchQuery) ||
          evidence.uploaderName.toLowerCase().contains(_searchQuery) ||
          (evidence.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          evidence.kategoriDisplayName.toLowerCase().contains(_searchQuery);

      final matchesStatus =
          _selectedStatusFilter == null ||
          evidence.status == _selectedStatusFilter;
      final matchesKategori =
          _selectedKategoriFilter == null ||
          evidence.kategori == _selectedKategoriFilter;

      return matchesSearch && matchesStatus && matchesKategori;
    }).toList();
  }

  void _showDetailDialog(EvidenceModel evidence) {
    showDialog(
      context: context,
      builder: (context) => AdminEvidenceDetailDialog(
        evidence: evidence,
        onStatusChanged: () {
          // Refresh akan otomatis karena menggunakan Stream
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showStatsDialog() async {
    try {
      final stats = await EvidenceService.getEvidenceStats();
      showDialog(
        context: context,
        builder: (context) => _buildStatsDialog(stats),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
  }

  Widget _buildStatsDialog(Map<String, dynamic> stats) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'Statistik Evidence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Summary stats
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total', stats['total'], Colors.blue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Pending', stats['pending'], Colors.orange),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard('Approved', stats['approved'], Colors.green),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Rejected', stats['rejected'], Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int value, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Admin Evidence Detail Dialog with Approve/Reject functionality
class AdminEvidenceDetailDialog extends StatelessWidget {
  final EvidenceModel evidence;
  final VoidCallback onStatusChanged;

  const AdminEvidenceDetailDialog({
    Key? key,
    required this.evidence,
    required this.onStatusChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: evidence.kategoriColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(evidence.kategoriIcon, color: evidence.kategoriColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evidence Detail',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'by ${evidence.uploaderName}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: evidence.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      evidence.statusDisplayName,
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
                    // File Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: evidence.isImage
                            ? Image.network(
                                evidence.fileUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(evidence.kategoriIcon, size: 48),
                                        SizedBox(height: 8),
                                        Text('Gagal memuat file'),
                                      ],
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      evidence.kategoriIcon,
                                      size: 48,
                                      color: evidence.kategoriColor,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      evidence.kategoriDisplayName,
                                      style: TextStyle(
                                        color: evidence.kategoriColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Info Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Lokasi', evidence.lokasiName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Kategori', evidence.kategoriDisplayName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Tanggal', evidence.formattedDate),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Status', evidence.statusDisplayName),
                        ),
                      ],
                    ),

                    // Description
                    if (evidence.description != null && evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Deskripsi:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                        child: Text(evidence.description!, style: TextStyle(fontSize: 14)),
                      ),
                    ],

                    // Rejection reason
                    if (evidence.status == StatusEvidence.rejected && evidence.rejectionReason != null) ...[
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Alasan Penolakan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              evidence.rejectionReason!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Actions - Show approve/reject buttons only for pending evidence
            Container(
              padding: EdgeInsets.all(20),
              child: evidence.status == StatusEvidence.pending
                  ? Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rejectEvidence(context),
                            icon: Icon(Icons.cancel, size: 20),
                            label: Text('Tolak'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 45),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _approveEvidence(context),
                            icon: Icon(Icons.check_circle, size: 20),
                            label: Text('Setujui'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              minimumSize: Size(0, 45),
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Tutup'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 45),
                      ),
                    ),
            ),
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }

  void _approveEvidence(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      await EvidenceService.approveEvidence(evidence.evidenceId, currentUser.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence berhasil disetujui'),
          backgroundColor: Colors.green,
        ),
      );
      onStatusChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _rejectEvidence(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.cancel, color: Colors.red),
                  SizedBox(width: 12),
                  Text(
                    'Tolak Evidence',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Alasan penolakan *',
                  border: OutlineInputBorder(),
                  hintText: 'Berikan alasan mengapa evidence ini ditolak...',
                ),
                maxLines: 3,
              ),
              SizedBox(height: 20),
              Row(
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
                      onPressed: () => _submitRejection(context, reasonController.text),
                      child: Text('Tolak'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitRejection(BuildContext context, String reason) async {
    if (reason.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Alasan penolakan wajib diisi')),
      );
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      await EvidenceService.rejectEvidence(
        evidence.evidenceId,
        currentUser.uid,
        reason.trim(),
      );
      
      Navigator.pop(context); // Close reject dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence berhasil ditolak'),
          backgroundColor: Colors.red,
        ),
      );
      onStatusChanged();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}