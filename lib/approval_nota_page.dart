import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nota_model.dart';
import 'nota_service.dart';
import 'user_service.dart';

class ApprovalNotaPage extends StatefulWidget {
  @override
  _ApprovalNotaPageState createState() => _ApprovalNotaPageState();
}

class _ApprovalNotaPageState extends State<ApprovalNotaPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  StatusNota _statusFilter = StatusNota.pending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approval Nota'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header dengan statistik
          Container(
            color: Colors.purple.withOpacity(0.1),
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
                    hintText: 'Cari nota...',
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
                    children: StatusNota.values.map((status) {
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
          
          // Nota List
          Expanded(
            child: StreamBuilder<List<NotaModel>>(
              stream: NotaService.getNotaByStatus(_statusFilter),
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

                final notaList = _filterNota(snapshot.data ?? []);

                if (notaList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notaList.length,
                  itemBuilder: (context, index) {
                    return _buildNotaCard(notaList[index]);
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
      stream: Stream.fromFuture(NotaService.getNotaStats()),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final pendingCount = stats['pending_count'] ?? 0;
        final approvedCount = stats['approved_count'] ?? 0;
        final rejectedCount = stats['rejected_count'] ?? 0;
        final reimbursedCount = stats['reimbursed_count'] ?? 0;
        
        final pendingTotal = stats['pending_total'] ?? 0.0;
        final approvedTotal = stats['approved_total'] ?? 0.0;

        return Column(
          children: [
            // Count Stats
            Row(
              children: [
                Expanded(child: _buildStatCard('Pending', pendingCount, Colors.orange)),
                SizedBox(width: 8),
                Expanded(child: _buildStatCard('Approved', approvedCount, Colors.green)),
                SizedBox(width: 8),
                Expanded(child: _buildStatCard('Rejected', rejectedCount, Colors.red)),
                SizedBox(width: 8),
                Expanded(child: _buildStatCard('Reimbursed', reimbursedCount, Colors.blue)),
              ],
            ),
            SizedBox(height: 12),
            
            // Amount Summary
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
                          'Pending Amount',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${pendingTotal.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match match) => '${match[1]}.',
                          )}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
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
                          'Approved Amount',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${approvedTotal.toStringAsFixed(0).replaceAllMapped(
                            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                            (Match match) => '${match[1]}.',
                          )}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
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
            _statusFilter == StatusNota.pending
                ? Icons.pending_actions
                : _statusFilter == StatusNota.approved
                    ? Icons.check_circle_outline
                    : _statusFilter == StatusNota.rejected
                        ? Icons.cancel_outlined
                        : Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            _statusFilter == StatusNota.pending
                ? 'Tidak ada nota yang pending'
                : 'Tidak ada nota ${_statusFilter.statusDisplayName.toLowerCase()}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Semua nota telah diproses',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCard(NotaModel nota) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(nota),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Icon with Amount
              Container(
                width: 70,
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: nota.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: nota.statusColor,
                      size: 20,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Rp ${nota.nominal > 1000000 ? '${(nota.nominal / 1000000).toStringAsFixed(1)}M' : '${(nota.nominal / 1000).toStringAsFixed(0)}K'}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: nota.statusColor,
                      ),
                    ),
                  ],
                ),
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
                            color: nota.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(nota.statusIcon, size: 12, color: nota.statusColor),
                              SizedBox(width: 4),
                              Text(
                                nota.statusDisplayName,
                                style: TextStyle(
                                  color: nota.statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Spacer(),
                        Text(
                          nota.formattedTanggal,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Full Amount
                    Text(
                      nota.formattedNominal,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 4),
                    
                    // Purpose
                    Text(
                      nota.keperluan,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    
                    // Coordinator and Location
                    Row(
                      children: [
                        Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Oleh ${nota.koordinatorName}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Text(
                          nota.lokasiName,
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
              
              // Quick Action untuk pending
              if (nota.status == StatusNota.pending)
                Column(
                  children: [
                    IconButton(
                      onPressed: () => _quickApprove(nota),
                      icon: Icon(Icons.check_circle, color: Colors.green),
                      iconSize: 20,
                      tooltip: 'Approve',
                    ),
                    IconButton(
                      onPressed: () => _showRejectDialog(nota),
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

  List<NotaModel> _filterNota(List<NotaModel> notaList) {
    return notaList.where((nota) {
      final matchesSearch = nota.keperluan.toLowerCase().contains(_searchQuery) ||
          nota.koordinatorName.toLowerCase().contains(_searchQuery) ||
          nota.lokasiName.toLowerCase().contains(_searchQuery) ||
          nota.formattedNominal.toLowerCase().contains(_searchQuery);
      
      return matchesSearch;
    }).toList();
  }

  void _showDetailDialog(NotaModel nota) {
    showDialog(
      context: context,
      builder: (context) => ApprovalNotaDetailDialog(
        nota: nota,
        onApproved: () => _refreshData(),
        onRejected: () => _refreshData(),
        onMarkedReimbursed: () => _refreshData(),
      ),
    );
  }

  void _quickApprove(NotaModel nota) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) return;

      await NotaService.approveNota(nota.notaId, currentUser.uid, currentUserData.name);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota berhasil disetujui'),
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

  void _showRejectDialog(NotaModel nota) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Nota'),
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
                final currentUserData = await UserService.getCurrentUser();
                
                if (currentUser == null || currentUserData == null) return;

                await NotaService.rejectNota(
                  nota.notaId,
                  currentUser.uid,
                  currentUserData.name,
                  reasonController.text.trim(),
                );
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nota berhasil ditolak'),
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

// Extension untuk menambah properti ke StatusNota
extension StatusNotaExtension on StatusNota {
  String get statusDisplayName {
    switch (this) {
      case StatusNota.pending:
        return 'Pending';
      case StatusNota.approved:
        return 'Approved';
      case StatusNota.rejected:
        return 'Rejected';
      case StatusNota.reimbursed:
        return 'Reimbursed';
    }
  }

  Color get statusColor {
    switch (this) {
      case StatusNota.pending:
        return Colors.orange;
      case StatusNota.approved:
        return Colors.green;
      case StatusNota.rejected:
        return Colors.red;
      case StatusNota.reimbursed:
        return Colors.blue;
    }
  }

  IconData get statusIcon {
    switch (this) {
      case StatusNota.pending:
        return Icons.pending;
      case StatusNota.approved:
        return Icons.check_circle;
      case StatusNota.rejected:
        return Icons.cancel;
      case StatusNota.reimbursed:
        return Icons.account_balance_wallet;
    }
  }
}

// Detail Dialog untuk Approval
class ApprovalNotaDetailDialog extends StatelessWidget {
  final NotaModel nota;
  final VoidCallback onApproved;
  final VoidCallback onRejected;
  final VoidCallback onMarkedReimbursed;

  const ApprovalNotaDetailDialog({
    Key? key,
    required this.nota,
    required this.onApproved,
    required this.onRejected,
    required this.onMarkedReimbursed,
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
                color: nota.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(nota.statusIcon, color: nota.statusColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Review Nota Pengeluaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nota.statusDisplayName,
                          style: TextStyle(
                            color: nota.statusColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: nota.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nota.statusDisplayName,
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
                    // Photo
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          nota.fotoNotaUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 48),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat foto'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Amount (prominent)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.purple.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Nominal Pengeluaran',
                            style: TextStyle(
                              color: Colors.purple.shade700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            nota.formattedNominal,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Info Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Tanggal', nota.formattedTanggal),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Lokasi', nota.lokasiName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Koordinator', nota.koordinatorName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Tanggal Submit', nota.formattedDate),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Purpose
                    _buildInfoItem('Keperluan', nota.keperluan),
                    
                    // Approval info if not pending
                    if (nota.status != StatusNota.pending) ...[
                      SizedBox(height: 16),
                      _buildInfoItem('Diproses oleh', nota.approverName ?? 'N/A'),
                      SizedBox(height: 16),
                      _buildInfoItem('Tanggal diproses', 
                          nota.approvedAt != null 
                              ? '${nota.approvedAt!.day}/${nota.approvedAt!.month}/${nota.approvedAt!.year}'
                              : 'N/A'),
                    ],

                    // Rejection reason
                    if (nota.status == StatusNota.rejected && nota.rejectionReason != null) ...[
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
                              nota.rejectionReason!,
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
            Container(
              padding: EdgeInsets.all(20),
              child: _buildActions(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    if (nota.status == StatusNota.pending) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _rejectNota(context),
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
              onPressed: () => _approveNota(context),
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
      );
    } else if (nota.status == StatusNota.approved) {
      return Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Tutup'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(0, 45),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _markAsReimbursed(context),
              icon: Icon(Icons.account_balance_wallet, size: 20),
              label: Text('Reimburse'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(0, 45),
              ),
            ),
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: () => Navigator.pop(context),
        child: Text('Tutup'),
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, 45),
        ),
      );
    }
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

  void _approveNota(BuildContext context) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) return;

      await NotaService.approveNota(nota.notaId, currentUser.uid, currentUserData.name);
      
      Navigator.pop(context);
      onApproved();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota berhasil disetujui'),
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

  void _rejectNota(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tolak Nota'),
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
                final currentUserData = await UserService.getCurrentUser();
                
                if (currentUser == null || currentUserData == null) return;

                await NotaService.rejectNota(
                  nota.notaId,
                  currentUser.uid,
                  currentUserData.name,
                  reasonController.text.trim(),
                );
                
                Navigator.pop(context); // Close reject dialog
                Navigator.pop(context); // Close detail dialog
                onRejected();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Nota berhasil ditolak'),
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

  void _markAsReimbursed(BuildContext context) async {
    try {
      await NotaService.markAsReimbursed(nota.notaId);
      
      Navigator.pop(context);
      onMarkedReimbursed();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nota berhasil ditandai sebagai reimbursed'),
          backgroundColor: Colors.blue,
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