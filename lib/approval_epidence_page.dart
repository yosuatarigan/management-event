import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'evidence_model.dart';
import 'evidence_service.dart';
import 'user_service.dart';

class ApprovalEvidencePage extends StatefulWidget {
  @override
  _ApprovalEvidencePageState createState() => _ApprovalEvidencePageState();
}

class _ApprovalEvidencePageState extends State<ApprovalEvidencePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StatusEvidence _statusFilter = StatusEvidence.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approval Evidence'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan statistik
          Container(
            color: Colors.green.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: _buildHeaderStats(),
          ),
          
          // Search dan Filter
          Container(
            color: Colors.grey.shade50,
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
                
                // Status Filter
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: StatusEvidence.values.map((status) {
                      final isSelected = _statusFilter == status;
                      return GestureDetector(
                        onTap: () => setState(() => _statusFilter = status),
                        child: Container(
                          margin: EdgeInsets.only(right: 8),
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? status.statusColor : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: status.statusColor,
                            ),
                          ),
                          child: Text(
                            status.statusDisplayName,
                            style: TextStyle(
                              color: isSelected ? Colors.white : status.statusColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          // Evidence List
          Expanded(
            child: StreamBuilder<List<EvidenceModel>>(
              stream: EvidenceService.getEvidenceByStatus(_statusFilter),
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
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
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

  Widget _buildHeaderStats() {
    return StreamBuilder<Map<String, dynamic>>(
      stream: Stream.fromFuture(EvidenceService.getEvidenceStats()),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final pending = stats['pending'] ?? 0;
        final approved = stats['approved'] ?? 0;
        final rejected = stats['rejected'] ?? 0;

        return Row(
          children: [
            Expanded(child: _buildStatCard('Pending', pending, Colors.orange)),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('Approved', approved, Colors.green)),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard('Rejected', rejected, Colors.red)),
          ],
        );
      },
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
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
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
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            _statusFilter == StatusEvidence.pending
                ? 'Tidak ada evidence yang pending'
                : 'Tidak ada evidence ${_statusFilter.statusDisplayName.toLowerCase()}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Semua evidence telah diproses',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(evidence),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Preview
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: evidence.kategoriColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: evidence.isImage
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          evidence.fileUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(evidence.kategoriIcon, 
                                color: evidence.kategoriColor, size: 24);
                          },
                        ),
                      )
                    : Icon(evidence.kategoriIcon, 
                          color: evidence.kategoriColor, size: 24),
              ),
              SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: evidence.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evidence.statusDisplayName,
                            style: TextStyle(
                              color: evidence.statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: evidence.kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            evidence.kategoriDisplayName,
                            style: TextStyle(
                              color: evidence.kategoriColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Lokasi
                    Text(
                      evidence.lokasiName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    
                    // Uploader
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          'Oleh ${evidence.uploaderName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    
                    // Date
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          evidence.formattedDate,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    
                    // Description preview
                    if (evidence.description != null && evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 8),
                      Text(
                        evidence.description!,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Quick Action untuk pending
              if (evidence.status == StatusEvidence.pending)
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _quickApprove(evidence),
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      iconSize: 20,
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      onPressed: () => _showRejectDialog(evidence),
                      icon: Icon(Icons.cancel, color: Colors.red),
                      iconSize: 20,
                      tooltip: 'Reject',
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
          (evidence.description?.toLowerCase().contains(_searchQuery) ?? false);
      
      return matchesSearch;
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

// Extension untuk menambah properti ke StatusEvidence
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

// Detail Dialog untuk Approval
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
                          'Review Evidence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          evidence.kategoriDisplayName,
                          style: TextStyle(
                            color: evidence.kategoriColor,
                            fontSize: 14,
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
                                    Icon(evidence.kategoriIcon, size: 48, color: evidence.kategoriColor),
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
                          child: _buildInfoItem('Uploader', evidence.uploaderName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Tanggal Upload', evidence.formattedDate),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Kategori', evidence.kategoriDisplayName),
                        ),
                      ],
                    ),
                    
                    // Description
                    if (evidence.description != null && evidence.description!.isNotEmpty) ...[
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
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          evidence.description!,
                          style: TextStyle(fontSize: 14),
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
                padding: EdgeInsets.all(20),
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
                ),
              )
            else
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