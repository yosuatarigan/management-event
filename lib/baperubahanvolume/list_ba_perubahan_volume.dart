import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:management_event/baperubahanvolume/form_ba_perubahan_volume.dart';
import 'package:management_event/baperubahanvolume/view_ba_perubahan_volume.dart';
import 'package:management_event/session_manager.dart';

class BAPerubahanVolumeListPage extends StatelessWidget {
  final String role; // 'coordinator' atau 'approver'

  const BAPerubahanVolumeListPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentProjectId = SessionManager.currentProjectId;

    if (currentProjectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('BA Perubahan Volume'),
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('Tidak ada proyek aktif'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(role == 'coordinator' ? 'BA Perubahan Volume' : 'Approval BA Perubahan Volume'),
        backgroundColor: role == 'coordinator' ? Colors.orange[700] : Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ba_perubahan_volume')
            .where('projectId', isEqualTo: currentProjectId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    role == 'coordinator' ? 'Belum ada BA' : 'Belum ada BA untuk di-approve',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  if (role == 'coordinator') ...[
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol + untuk membuat BA baru',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              String status = data['status'] ?? 'draft';
              Color statusColor = status == 'approved'
                  ? Colors.green
                  : status == 'pending'
                      ? Colors.orange
                      : Colors.grey;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: statusColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BAPerubahanVolumeViewPage(
                            docId: doc.id,
                            role: role,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [statusColor.withOpacity(0.7), statusColor],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              status == 'approved'
                                  ? Icons.check_circle_outline
                                  : status == 'pending'
                                      ? Icons.pending_outlined
                                      : Icons.swap_horiz_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        data['tilok'] ?? 'No Title',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: status == 'approved'
                                            ? Colors.green[50]
                                            : status == 'pending'
                                                ? Colors.orange[50]
                                                : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        status == 'approved'
                                            ? 'Approved'
                                            : status == 'pending'
                                                ? 'Pending'
                                                : 'Draft',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: statusColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['hari']}, ${data['tanggal']} ${data['bulan']} 2025',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people,
                                        size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${data['peserta']} peserta',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                if (role == 'approver' && status == 'pending') ...[
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.hourglass_empty,
                                          size: 14, color: Colors.orange[600]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Menunggu approval Anda',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (role == 'coordinator')
                            PopupMenuButton<String>(
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.more_vert, size: 20),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility,
                                          size: 20, color: Colors.orange[700]),
                                      const SizedBox(width: 12),
                                      const Text('Lihat'),
                                    ],
                                  ),
                                ),
                                if (status == 'draft')
                                  PopupMenuItem<String>(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit,
                                            size: 20, color: Colors.blue[700]),
                                        const SizedBox(width: 12),
                                        const Text('Edit'),
                                      ],
                                    ),
                                  ),
                                if (status == 'draft') const PopupMenuDivider(),
                                if (status == 'draft')
                                  const PopupMenuItem<String>(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Hapus',
                                            style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                              ],
                              onSelected: (value) {
                                if (value == 'view') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BAPerubahanVolumeViewPage(
                                        docId: doc.id,
                                        role: role,
                                      ),
                                    ),
                                  );
                                } else if (value == 'edit') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BAPerubahanVolumeFormPage(docId: doc.id),
                                    ),
                                  );
                                } else if (value == 'delete') {
                                  _showDeleteDialog(context, doc.id);
                                }
                              },
                            )
                          else
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey[400]),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: role == 'coordinator'
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BAPerubahanVolumeFormPage()),
                );
              },
              backgroundColor: Colors.orange[700],
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Buat BA',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  void _showDeleteDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
            const SizedBox(width: 12),
            const Text('Hapus BA'),
          ],
        ),
        content: const Text(
            'Yakin ingin menghapus BA ini? Data tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('ba_perubahan_volume')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('BA berhasil dihapus'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}