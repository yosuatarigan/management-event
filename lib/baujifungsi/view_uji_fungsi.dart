import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'dart:convert';

class BAUjiFungsiViewPage extends StatefulWidget {
  final String docId;
  final String role;

  const BAUjiFungsiViewPage({
    Key? key,
    required this.docId,
    required this.role,
  }) : super(key: key);

  @override
  State<BAUjiFungsiViewPage> createState() => _BAUjiFungsiViewPageState();
}

class _BAUjiFungsiViewPageState extends State<BAUjiFungsiViewPage> {
  SignatureController? _signatureController;

  @override
  void dispose() {
    _signatureController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat BA Uji Fungsi'),
        backgroundColor: Colors.teal[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('PDF Generator belum diimplementasikan')),
              );
            },
            tooltip: 'Save as PDF',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ba_uji_fungsi')
            .doc(widget.docId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Data tidak ditemukan'));
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          String status = data['status'] ?? 'draft';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),
                _buildInfoSection(data),
                const SizedBox(height: 24),
                _buildLaptopClientSection(data),
                const SizedBox(height: 16),
                _buildLaptopBackupSection(data),
                const SizedBox(height: 16),
                _buildPeralatanSection(data),
                const SizedBox(height: 24),
                _buildSignatureSection(data, status),
                const SizedBox(height: 24),
                _buildActionButton(status),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Text(
            'BERITA ACARA PENERIMAAN DAN UJI FUNGSI',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Text(
            'JASA PENDUKUNG PENYELENGGARAAN',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const Text(
            'KEGIATAN SELEKSI KOMPETENSI PPPK TAHAP II',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'KATEGORI ${data['jumlahPeserta']} PESERTA PER SESI',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          Text(
            'TITIK LOKASI ${data['tilok']}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Nomor: ${data['nomorBA']}',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pada hari ini ${data['hari']} tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua Ribu Dua Puluh Lima, telah dilakukan penerimaan dan uji fungsi sarana dan prasarana untuk keperluan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori ${data['jumlahPeserta']} Peserta Per Sesi di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']}.',
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildLaptopClientSection(Map<String, dynamic> data) {
    var laptopIds = data['laptopClientIds'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.laptop, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Laptop Client Ujian',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(laptopIds.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  '${index + 1}. ${laptopIds[index]}',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildLaptopBackupSection(Map<String, dynamic> data) {
    var laptopIds = data['laptopBackupIds'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.laptop_chromebook, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Laptop Cadangan/Backup',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(laptopIds.length, (index) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Text(
                  '${index + 1}. ${laptopIds[index]}',
                  style: const TextStyle(fontSize: 11),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPeralatanSection(Map<String, dynamic> data) {
    var peralatan = data['peralatan'] as Map<String, dynamic>? ?? {};
    
    final peralatanList = {
      'B1': 'UPS Router/Switch',
      'B2': 'UPS Modem & Switch',
      'B3': 'Metal Detector',
      'B4': 'Laptop Registrasi',
      'B5': 'Webcam & Tripod',
      'B6': 'Barcode',
      'B7': 'LED Ring Light',
      'B8': 'Printer Warna',
      'B9': 'Laptop Monitoring',
      'B10': 'Webcam & Tripod',
      'B11': 'Printer Admin',
      'B12': 'Laptop Admin',
      'B13': 'Container Box',
      'B14': 'LCD Projector',
      'B15': 'Laptop',
      'B16': 'CCTV Indoor',
      'B17': 'Display',
      'B18': 'Media Penyimpanan',
      'B19': 'TV LCD & Flashdisk',
      'B20': 'Hardisk 2TB',
      'B21': 'Meja Cover',
      'B22': 'Kursi Susun Cover',
      'B23': 'Meja Cover',
      'B24': 'Kursi Tanpa Cover',
      'B25': 'Meja Transit',
      'B26': 'Kursi Transit',
      'B27': 'Kursi Susun',
      'B28': 'Meja Registrasi',
      'B29': 'Kursi Registrasi',
      'B30': 'Tenda Semi Dekor',
      'B31': 'Lampu Tenda',
      'B32': 'Tenda Medis',
      'B33': 'Lampu Medis',
      'B34': 'Pembatas Antrian',
      'B35': 'Sound Portable',
      'B36': 'AC Ruang Ujian',
      'B37': 'AC Medis',
      'B38': 'Misty Fan',
      'B39': 'Genset',
    };
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_box, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Peralatan Pendukung',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...peralatanList.entries.map((entry) {
            String status = peralatan[entry.key] ?? '✓';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(
                    status == '✓' ? Icons.check_circle : Icons.cancel,
                    size: 16,
                    color: status == '✓' ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(Map<String, dynamic> data, String status) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                const Text('Koordinator', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data['coordinatorSignature'] != null) ...[
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      base64Decode(data['coordinatorSignature']),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['coordinatorName'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Belum ditandatangani',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(data['koordinator'], style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                const Text('Tim Pengawas BKN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (data['approverSignature'] != null) ...[
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Image.memory(
                      base64Decode(data['approverSignature']),
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data['approverName'] ?? '',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ] else
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        status == 'draft' ? 'Menunggu koordinator' : 'Menunggu approval',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(data['pengawas'], style: const TextStyle(fontSize: 11)),
                Text('NIP. ${data['nipPengawas']}', style: const TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String status) {
    if (widget.role == 'coordinator' && status == 'draft') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showSignatureDialog('coordinator'),
          icon: const Icon(Icons.draw, color: Colors.white),
          label: const Text('Tanda Tangan Koordinator', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    } else if (widget.role == 'approver' && status == 'pending') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showSignatureDialog('approver'),
          icon: const Icon(Icons.check_circle, color: Colors.white),
          label: const Text('Approve BA', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  void _showSignatureDialog(String signerRole) async {
    var doc = await FirebaseFirestore.instance
        .collection('ba_uji_fungsi')
        .doc(widget.docId)
        .get();
    
    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data BA tidak ditemukan')),
      );
      return;
    }
    
    var data = doc.data()!;
    String signerName = signerRole == 'coordinator' 
        ? data['koordinator'] 
        : data['pengawas'];

    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                signerRole == 'coordinator' ? 'Tanda Tangan Koordinator' : 'Tanda Tangan Approver',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                signerName,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.teal, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Signature(
                    controller: _signatureController!,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _signatureController!.clear();
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _signatureController?.dispose();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_signatureController!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Silakan tanda tangan terlebih dahulu')),
                          );
                          return;
                        }
                        await _saveSignature(signerRole, signerName);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Simpan'),
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

  Future<void> _saveSignature(String signerRole, String signerName) async {
    try {
      final signatureData = await _signatureController!.toPngBytes();
      final signatureBase64 = base64Encode(signatureData!);

      Map<String, dynamic> updateData = {};

      if (signerRole == 'coordinator') {
        updateData = {
          'coordinatorSignature': signatureBase64,
          'coordinatorSignedAt': FieldValue.serverTimestamp(),
          'coordinatorName': signerName,
          'status': 'pending',
        };
      } else {
        updateData = {
          'approverSignature': signatureBase64,
          'approverSignedAt': FieldValue.serverTimestamp(),
          'approverName': signerName,
          'status': 'approved',
        };
      }

      await FirebaseFirestore.instance
          .collection('ba_uji_fungsi')
          .doc(widget.docId)
          .update(updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(signerRole == 'coordinator' ? 'Tanda tangan berhasil disimpan' : 'BA berhasil di-approve'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}