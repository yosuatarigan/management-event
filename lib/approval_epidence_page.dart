import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'evidence_model.dart';
import 'evidence_service.dart';
import 'evidence_categories.dart';
import 'user_service.dart';
import 'session_manager.dart';

class ApprovalEvidencePage extends StatefulWidget {
  const ApprovalEvidencePage({Key? key}) : super(key: key);

  @override
  _ApprovalEvidencePageState createState() => _ApprovalEvidencePageState();
}

class _ApprovalEvidencePageState extends State<ApprovalEvidencePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StatusEvidence _statusFilter = StatusEvidence.pending;
  KategoriEvidence? _selectedKategoriFilter;
  String? _selectedJenisFilter;
  String? _selectedSubJenisFilter;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final currentProjectId = SessionManager.currentProjectId;
    
    if (currentProjectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Approval Evidence'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Tidak ada proyek yang dipilih',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pilih proyek terlebih dahulu',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Approval Evidence',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: !isWeb,
      ),
      body: Column(
        children: [
          // Header Stats
          Container(
            color: Colors.green.withOpacity(0.1),
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                child: _buildHeaderStats(currentProjectId, isWeb),
              ),
            ),
          ),
          
          // Search & Filter
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
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
                          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 16 : 12,
                          vertical: isWeb ? 16 : 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                    SizedBox(height: isWeb ? 16 : 12),
                    
                    // Status Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: StatusEvidence.values.map((status) {
                          final isSelected = _statusFilter == status;
                          return GestureDetector(
                            onTap: () => setState(() => _statusFilter = status),
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                              padding: EdgeInsets.symmetric(
                                horizontal: isWeb ? 16 : 12,
                                vertical: isWeb ? 10 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? status.statusColor : Colors.white,
                                borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
                                border: Border.all(color: status.statusColor),
                              ),
                              child: Text(
                                status.statusDisplayName,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : status.statusColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isWeb ? 14 : 12,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: isWeb ? 16 : 12),

                    // Additional Filters
                    isWeb 
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildKategoriFilter(isWeb),
                            _buildJenisFilter(isWeb),
                            _buildSubJenisFilter(isWeb),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildKategoriFilter(isWeb),
                              SizedBox(width: 8),
                              _buildJenisFilter(isWeb),
                              SizedBox(width: 8),
                              _buildSubJenisFilter(isWeb),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
          
          // Evidence List
          Expanded(
            child: StreamBuilder<List<EvidenceModel>>(
              stream: EvidenceService.getEvidenceByProjectAndStatus(
                currentProjectId,
                _statusFilter,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                        SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final evidenceList = _filterEvidence(snapshot.data ?? []);

                if (evidenceList.isEmpty) {
                  return _buildEmptyState(isWeb);
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                    child: ListView.builder(
                      padding: EdgeInsets.all(isWeb ? 24 : 16),
                      itemCount: evidenceList.length,
                      itemBuilder: (context, index) {
                        return _buildEvidenceCard(evidenceList[index], isWeb);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(String projectId, bool isWeb) {
    return FutureBuilder<Map<String, dynamic>>(
      future: EvidenceService.getEvidenceStatsByProject(projectId),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final pending = stats['pending'] ?? 0;
        final approved = stats['approved'] ?? 0;
        final rejected = stats['rejected'] ?? 0;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Pending', pending, Colors.orange, isWeb)),
            SizedBox(width: isWeb ? 16 : 12),
            Expanded(child: _buildStatCard('Approved', approved, Colors.green, isWeb)),
            SizedBox(width: isWeb ? 16 : 12),
            Expanded(child: _buildStatCard('Rejected', rejected, Colors.red, isWeb)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, int count, Color color, bool isWeb) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isWeb ? 20 : 16,
        horizontal: isWeb ? 16 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: isWeb ? 8 : 4),
          Text(
            title,
            style: TextStyle(
              fontSize: isWeb ? 14 : 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriFilter(bool isWeb) {
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
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedKategoriFilter != null
              ? Colors.purple.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: isWeb ? 18 : 16,
              color: _selectedKategoriFilter != null
                  ? Colors.purple.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedKategoriFilter != null
                  ? getKategoriDisplayName(_selectedKategoriFilter!)
                  : 'Kategori',
              style: TextStyle(
                color: _selectedKategoriFilter != null
                    ? Colors.purple.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
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
        setState(() {
          _selectedKategoriFilter = value;
          _selectedJenisFilter = null;
          _selectedSubJenisFilter = null;
        });
      },
    );
  }

  Widget _buildJenisFilter(bool isWeb) {
    if (_selectedKategoriFilter == null) return SizedBox.shrink();
    
    final kategoriKey = _selectedKategoriFilter.toString().split('.').last;
    if (!EvidenceCategories.hasJenisSubJenis(kategoriKey)) {
      return SizedBox.shrink();
    }

    final jenisList = EvidenceCategories.getJenisByKategori(kategoriKey);
    if (jenisList.isEmpty) return SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedJenisFilter != null
              ? Colors.teal.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt,
              size: isWeb ? 18 : 16,
              color: _selectedJenisFilter != null
                  ? Colors.teal.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedJenisFilter ?? 'Jenis',
              style: TextStyle(
                color: _selectedJenisFilter != null
                    ? Colors.teal.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Jenis')),
        ...jenisList.map(
          (jenis) => PopupMenuItem(
            value: jenis,
            child: Text(jenis),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() {
          _selectedJenisFilter = value;
          _selectedSubJenisFilter = null;
        });
      },
    );
  }

  Widget _buildSubJenisFilter(bool isWeb) {
    if (_selectedKategoriFilter == null || _selectedJenisFilter == null) {
      return SizedBox.shrink();
    }

    final kategoriKey = _selectedKategoriFilter.toString().split('.').last;
    final subJenisList = EvidenceCategories.getSubJenisByJenis(
      kategoriKey, 
      _selectedJenisFilter!,
    );
    
    if (subJenisList.isEmpty) return SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedSubJenisFilter != null
              ? Colors.indigo.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subdirectory_arrow_right,
              size: isWeb ? 18 : 16,
              color: _selectedSubJenisFilter != null
                  ? Colors.indigo.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedSubJenisFilter ?? 'Sub Jenis',
              style: TextStyle(
                color: _selectedSubJenisFilter != null
                    ? Colors.indigo.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Sub Jenis')),
        ...subJenisList.map(
          (subJenis) => PopupMenuItem(
            value: subJenis,
            child: Text(subJenis),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() => _selectedSubJenisFilter = value);
      },
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _statusFilter == StatusEvidence.pending
                ? Icons.hourglass_empty
                : _statusFilter == StatusEvidence.approved
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
            size: isWeb ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            _statusFilter == StatusEvidence.pending
                ? 'Tidak ada evidence pending'
                : 'Tidak ada evidence ${_statusFilter.statusDisplayName.toLowerCase()}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Semua evidence telah diproses',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isWeb ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence, bool isWeb) {
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 16 : 12),
      elevation: isWeb ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        onTap: () => _showDetailDialog(evidence),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Preview
              Container(
                width: isWeb ? 80 : 60,
                height: isWeb ? 80 : 60,
                decoration: BoxDecoration(
                  color: evidence.kategoriColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
                ),
                child: evidence.isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
                        child: Image.network(
                          evidence.fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(evidence.kategoriIcon, 
                                color: evidence.kategoriColor, 
                                size: isWeb ? 32 : 24);
                          },
                        ),
                      )
                    : Icon(evidence.kategoriIcon, 
                          color: evidence.kategoriColor, 
                          size: isWeb ? 32 : 24),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Category Badges
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 10 : 8,
                            vertical: isWeb ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evidence.statusDisplayName,
                            style: TextStyle(
                              color: evidence.statusColor,
                              fontSize: isWeb ? 11 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWeb ? 10 : 8,
                            vertical: isWeb ? 5 : 4,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evidence.kategoriDisplayName,
                            style: TextStyle(
                              color: evidence.kategoriColor,
                              fontSize: isWeb ? 11 : 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    // Jenis & Sub Jenis
                    if (evidence.jenis != null) ...[
                      SizedBox(height: 6),
                      Text(
                        evidence.jenisSubJenisDisplay,
                        style: TextStyle(
                          fontSize: isWeb ? 13 : 11,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    SizedBox(height: isWeb ? 10 : 8),
                    
                    // Lokasi
                    Text(
                      evidence.lokasiName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isWeb ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    
                    // Uploader
                    Row(
                      children: [
                        Icon(Icons.person, 
                            size: isWeb ? 16 : 14, 
                            color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          evidence.uploaderName,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isWeb ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    // Date
                    Row(
                      children: [
                        Icon(Icons.access_time, 
                            size: isWeb ? 16 : 14, 
                            color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          evidence.formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isWeb ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                    
                    // Description preview
                    if (evidence.description != null && 
                        evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        evidence.description!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: isWeb ? 14 : 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Quick Actions
              if (evidence.status == StatusEvidence.pending)
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _quickApprove(evidence),
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      iconSize: isWeb ? 24 : 20,
                      tooltip: 'Setujui',
                    ),
                    IconButton(
                      onPressed: () => _showRejectDialog(evidence),
                      icon: Icon(Icons.cancel, color: Colors.red),
                      iconSize: isWeb ? 24 : 20,
                      tooltip: 'Tolak',
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<EvidenceModel> _filterEvidence(List<EvidenceModel> evidenceList) {
    return evidenceList.where((evidence) {
      final matchesSearch = evidence.lokasiName.toLowerCase().contains(_searchQuery) ||
          evidence.uploaderName.toLowerCase().contains(_searchQuery) ||
          (evidence.jenis?.toLowerCase().contains(_searchQuery) ?? false) ||
          (evidence.subJenis?.toLowerCase().contains(_searchQuery) ?? false) ||
          (evidence.description?.toLowerCase().contains(_searchQuery) ?? false);
      
      final matchesKategori = _selectedKategoriFilter == null ||
          evidence.kategori == _selectedKategoriFilter;
      final matchesJenis = _selectedJenisFilter == null ||
          evidence.jenis == _selectedJenisFilter;
      final matchesSubJenis = _selectedSubJenisFilter == null ||
          evidence.subJenis == _selectedSubJenisFilter;
      
      return matchesSearch && matchesKategori && matchesJenis && matchesSubJenis;
    }).toList();
  }

  void _showDetailDialog(EvidenceModel evidence) {
    showDialog(
      context: context,
      builder: (context) => ApprovalEvidenceDetailDialog(
        evidence: evidence,
        onApproved: () => _refreshData(),
        onRejected: () => _refreshData(),
      ),
    );
  }

  void _quickApprove(EvidenceModel evidence) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await EvidenceService.approveEvidence(evidence.evidenceId, currentUser.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence berhasil disetujui'),
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

  void _showRejectDialog(EvidenceModel evidence) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tolak Evidence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan penolakan:'),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alasan penolakan harus diisi')),
                );
                return;
              }
              
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                await EvidenceService.rejectEvidence(
                  evidence.evidenceId,
                  currentUser.uid,
                  reasonController.text.trim(),
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Evidence berhasil ditolak'),
                    backgroundColor: Colors.red,
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _refreshData() {
    setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Extension untuk StatusEvidence
extension StatusEvidenceExtension on StatusEvidence {
  String get statusDisplayName {
    switch (this) {
      case StatusEvidence.pending:
        return 'Pending';
      case StatusEvidence.approved:
        return 'Approved';
      case StatusEvidence.rejected:
        return 'Rejected';
    }
  }

  Color get statusColor {
    switch (this) {
      case StatusEvidence.pending:
        return Colors.orange;
      case StatusEvidence.approved:
        return Colors.green;
      case StatusEvidence.rejected:
        return Colors.red;
    }
  }
}

// Detail Dialog
class ApprovalEvidenceDetailDialog extends StatelessWidget {
  final EvidenceModel evidence;
  final VoidCallback onApproved;
  final VoidCallback onRejected;

  const ApprovalEvidenceDetailDialog({
    Key? key,
    required this.evidence,
    required this.onApproved,
    required this.onRejected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
      child: Container(
        width: isWeb ? 600.0 : screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: evidence.kategoriColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: evidence.kategoriColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(evidence.kategoriIcon, color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Review Evidence',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    // File Preview
                    Container(
                      width: double.infinity,
                      height: isWeb ? 250 : 200,
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
                                    child: Icon(evidence.kategoriIcon, size: 48),
                                  );
                                },
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(evidence.kategoriIcon, 
                                        size: isWeb ? 64 : 48, 
                                        color: evidence.kategoriColor),
                                    SizedBox(height: 12),
                                    Text(
                                      evidence.kategoriDisplayName,
                                      style: TextStyle(
                                        fontSize: isWeb ? 18 : 16,
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
                    
                    // Action Buttons (for video/document)
                    if (evidence.kategori != KategoriEvidence.foto)
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _openFile(),
                              icon: Icon(_getActionIcon()),
                              label: Text(_getActionText()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: evidence.kategoriColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(),
                            icon: Icon(Icons.download),
                            label: Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    if (evidence.kategori != KategoriEvidence.foto)
                      SizedBox(height: 20),
                    
                    // Info
                    _buildInfoRow('Lokasi', evidence.lokasiName, Icons.location_on),
                    _buildInfoRow('Uploader', evidence.uploaderName, Icons.person),
                    _buildInfoRow('Tanggal', evidence.formattedDate, Icons.calendar_today),
                    _buildInfoRow('Kategori', evidence.kategoriDisplayName, Icons.category),
                    
                    if (evidence.jenis != null)
                      _buildInfoRow('Jenis', evidence.jenis!, Icons.list_alt),
                    if (evidence.subJenis != null)
                      _buildInfoRow('Sub Jenis', evidence.subJenis!, Icons.subdirectory_arrow_right),
                    
                    // Description
                    if (evidence.description != null && 
                        evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Deskripsi:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          evidence.description!,
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],

                    // Rejection Reason
                    if (evidence.status == StatusEvidence.rejected &&
                        evidence.rejectionReason != null) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
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
                                Icon(Icons.error, color: Colors.red.shade700, size: 20),
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
            
            // Actions
            if (evidence.status == StatusEvidence.pending)
              Container(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectEvidence(context),
                        icon: Icon(Icons.cancel, size: 20),
                        label: Text('Tolak'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: Size(0, isWeb ? 50 : 45),
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
                          minimumSize: Size(0, isWeb ? 50 : 45),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Padding(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Tutup'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(0, isWeb ? 50 : 45),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return Icons.zoom_in;
      case KategoriEvidence.video:
        return Icons.play_arrow;
      default:
        return Icons.open_in_new;
    }
  }

  String _getActionText() {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return 'Lihat Full';
      case KategoriEvidence.video:
        return 'Putar Video';
      default:
        return 'Buka File';
    }
  }

  Future<void> _openFile() async {
    try {
      final Uri uri = Uri.parse(evidence.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  Future<void> _downloadFile() async {
    try {
      final Uri uri = Uri.parse(evidence.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }

  void _approveEvidence(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      await EvidenceService.approveEvidence(evidence.evidenceId, currentUser.uid);
      
      Navigator.pop(context);
      onApproved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Evidence berhasil disetujui'),
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

  void _rejectEvidence(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tolak Evidence'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan penolakan:'),
            SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Masukkan alasan penolakan...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Alasan penolakan harus diisi')),
                );
                return;
              }
              
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) return;

                await EvidenceService.rejectEvidence(
                  evidence.evidenceId,
                  currentUser.uid,
                  reasonController.text.trim(),
                );
                
                Navigator.pop(context); // Close reject dialog
                Navigator.pop(context); // Close detail dialog
                onRejected();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Evidence berhasil ditolak'),
                    backgroundColor: Colors.red,
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Tolak', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}