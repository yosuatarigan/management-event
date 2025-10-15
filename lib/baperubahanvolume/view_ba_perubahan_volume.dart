import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/user_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class BAPerubahanVolumeViewPage extends StatefulWidget {
  final String docId;
  final String role;

  const BAPerubahanVolumeViewPage({
    Key? key,
    required this.docId,
    required this.role,
  }) : super(key: key);

  @override
  State<BAPerubahanVolumeViewPage> createState() => _BAPerubahanVolumeViewPageState();
}

class _BAPerubahanVolumeViewPageState extends State<BAPerubahanVolumeViewPage> {
  SignatureController? _signatureController;

  @override
  void initState() {
    super.initState();
    _initSignatureController();
  }

  void _initSignatureController() {
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController?.dispose();
    super.dispose();
  }

  Future<void> _generateAndSharePDF(BuildContext context, Map<String, dynamic> data) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final pdf = pw.Document();

      pw.MemoryImage? image1;
      pw.MemoryImage? image2;
      
      try {
        final imageData1 = await rootBundle.load('assets/badismantle1.png');
        final imageData2 = await rootBundle.load('assets/badismantle2.png');
        image1 = pw.MemoryImage(imageData1.buffer.asUint8List());
        image2 = pw.MemoryImage(imageData2.buffer.asUint8List());
      } catch (e) {
        print('Logo images not found: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            if (image1 != null && image2 != null)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                children: [
                  pw.Image(image1, width: 60, height: 60),
                  pw.SizedBox(width: 16),
                  pw.Image(image2, width: 60, height: 60),
                ],
              ),
            if (image1 != null && image2 != null) pw.SizedBox(height: 16),
            
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('BERITA ACARA PERUBAHAN VOLUME SARANA PRASARANA', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('JASA PENDUKUNG PENYELENGGARAAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('KEGIATAN SELEKSI KOMPETENSI PPPK TAHAP II', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('KATEGORI JUMLAH PESERTA PER SESI ${data['peserta']} ORANG',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('TITIK LOKASI SELEKSI MANDIRI BKN ${data['tilok']}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('TAHUN 2025', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Pada hari ini ${data['hari']}, tanggal ${data['tanggal']} bulan ${data['bulan']} tahun dua ribu dua puluh lima, telah dilaksanakan perhitungan perubahan volume tenda semi dekor/tenda sarnafil/AC Standing/Misty Fan untuk pekerjaan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori Jumlah Peserta Per Sesi ${data['peserta']} Orang di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']} rincian kegiatan sebagai berikut :',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            _buildPdfTable([
              ['No', 'Uraian', 'Jumlah Kontrak', 'Satuan', 'Jumlah Terpasang', 'Satuan', 'Keterangan'],
              ['1', 'Tenda Semi Dekor', '${data['b30l']}', 'm2', '${data['b30b']}', 'm2', data['k1']],
              ['2', 'Tenda Sarnafil', '${data['b32l']}', 'm2', '${data['b32b']}', 'm2', data['k2']],
              ['3', 'AC Standing', '${data['b36l']}', 'unit', '${data['b36b']}', 'unit', data['k3']],
              ['4', 'Misty Fan', '${data['b38l']}', 'unit', '${data['b38b']}', 'unit', data['k4']],
            ]),
            pw.SizedBox(height: 20),
            pw.Text(
              'Demikianlah berita acara ini dibuat dengan sebenarnya, untuk dapat diketahui dan dipergunakan sebagaimana mestinya.',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('Menerima dan menyetujui:', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Tim Pengawas Pekerjaan BKN', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      if (data['approverSignature'] != null)
                        pw.Container(
                          height: 50,
                          child: pw.Image(pw.MemoryImage(base64Decode(data['approverSignature']))),
                        )
                      else
                        pw.SizedBox(height: 50),
                      pw.SizedBox(height: 5),
                      pw.Text(data['pengawas'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('NIP. ${data['nipPengawas'] ?? ''}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('Dibuat Oleh :', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('PT. Mitra Era Global', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 10),
                      if (data['coordinatorSignature'] != null)
                        pw.Container(
                          height: 50,
                          child: pw.Image(pw.MemoryImage(base64Decode(data['coordinatorSignature']))),
                        )
                      else
                        pw.SizedBox(height: 50),
                      pw.SizedBox(height: 5),
                      pw.Text(data['koordinator'] ?? '', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Koordinator', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/BA_Perubahan_Volume_${data['tilok']}.pdf');
      await file.writeAsBytes(await pdf.save());

      Navigator.pop(context);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('PDF Berhasil Dibuat'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.share, color: Colors.orange),
                title: const Text('Share PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(file.path)], text: 'BA Perubahan Volume - ${data['tilok']}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.green),
                title: const Text('Preview PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await Printing.layoutPdf(onLayout: (format) async => await pdf.save());
                },
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  pw.Widget _buildPdfTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      children: rows.map((row) {
        bool isHeader = rows.indexOf(row) == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: isHeader ? PdfColors.orange100 : null),
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Future<void> _saveSignature(Map<String, dynamic> data) async {
    if (_signatureController == null || _signatureController!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan tanda tangan terlebih dahulu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final signatureBytes = await _signatureController!.toPngBytes();
      if (signatureBytes == null) return;

      final signatureBase64 = base64Encode(signatureBytes);
      final currentUser = await UserService.getCurrentUser();
      final userId = FirebaseAuth.instance.currentUser?.uid;

      Map<String, dynamic> updateData = {};

      if (widget.role == 'coordinator') {
        updateData = {
          'coordinatorSignature': signatureBase64,
          'coordinatorSignedAt': FieldValue.serverTimestamp(),
          'coordinatorSignedBy': userId,
          'coordinatorName': currentUser?.name ?? '',
          'status': 'pending',
        };
      } else {
        updateData = {
          'approverSignature': signatureBase64,
          'approverSignedAt': FieldValue.serverTimestamp(),
          'approverSignedBy': userId,
          'approverName': currentUser?.name ?? '',
          'status': 'approved',
        };
      }

      await FirebaseFirestore.instance
          .collection('ba_perubahan_volume')
          .doc(widget.docId)
          .update(updateData);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.role == 'coordinator'
                  ? 'Tanda tangan berhasil disimpan. BA menunggu approval.'
                  : 'BA berhasil di-approve',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSignatureDialog(Map<String, dynamic> data) {
    _signatureController?.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.draw, color: Colors.orange[700], size: 24),
                    const SizedBox(width: 12),
                    const Text(
                      'Tanda Tangan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[50],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Signature(
                      controller: _signatureController!,
                      backgroundColor: Colors.grey[50]!,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tanda tangan di area di atas',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _signatureController?.clear();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveSignature(data);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Simpan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lihat BA Perubahan Volume'),
        backgroundColor: widget.role == 'coordinator' ? Colors.orange[700] : Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              final doc = await FirebaseFirestore.instance
                  .collection('ba_perubahan_volume')
                  .doc(widget.docId)
                  .get();
              if (doc.exists) {
                _generateAndSharePDF(context, doc.data()!);
              }
            },
            tooltip: 'Export PDF',
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('ba_perubahan_volume')
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
          bool hasCoordinatorSign = data['coordinatorSignature'] != null;
          bool hasApproverSign = data['approverSignature'] != null;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Badge
                _buildStatusBadge(status),
                const SizedBox(height: 16),

                // BA Content
                _buildContentCard(data),
                const SizedBox(height: 16),

                // Volume Details
                _buildVolumeSection(data),
                const SizedBox(height: 16),

                // Signature Section
                _buildSignatureSection(data, status, hasCoordinatorSign, hasApproverSign),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'approved'
        ? Colors.green
        : status == 'pending'
            ? Colors.orange
            : Colors.grey;

    IconData icon = status == 'approved'
        ? Icons.check_circle
        : status == 'pending'
            ? Icons.hourglass_empty
            : Icons.edit_note;

    String text = status == 'approved'
        ? 'Approved'
        : status == 'pending'
            ? 'Menunggu Approval'
            : 'Draft';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: status == 'approved' 
            ? Colors.green[50]
            : status == 'pending'
                ? Colors.orange[50]
                : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'approved' 
              ? Colors.green[200]!
              : status == 'pending'
                  ? Colors.orange[200]!
                  : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.swap_horiz_rounded, color: Colors.orange[700], size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BA Perubahan Volume',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      data['tilok'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow(Icons.location_on, 'Alamat', data['alamat']),
          _buildInfoRow(Icons.people, 'Peserta', '${data['peserta']} orang'),
          _buildInfoRow(Icons.calendar_today, 'Tanggal', '${data['hari']}, ${data['tanggal']} ${data['bulan']} 2025'),
          _buildInfoRow(Icons.person, 'Koordinator', data['koordinator']),
          _buildInfoRow(Icons.supervisor_account, 'Pengawas', data['pengawas']),
          _buildInfoRow(Icons.badge, 'NIP Pengawas', data['nipPengawas']),
        ],
      ),
    );
  }

  Widget _buildVolumeSection(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assessment, color: Colors.purple[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Rincian Perubahan Volume',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVolumeItem('Tenda Semi Dekor', '${data['b30l']} m²', '${data['b30b']} m²', data['k1']),
          _buildVolumeItem('Tenda Sarnafil', '${data['b32l']} m²', '${data['b32b']} m²', data['k2']),
          _buildVolumeItem('AC Standing', '${data['b36l']} unit', '${data['b36b']} unit', data['k3']),
          _buildVolumeItem('Misty Fan', '${data['b38l']} unit', '${data['b38b']} unit', data['k4']),
        ],
      ),
    );
  }

  Widget _buildVolumeItem(String label, String kontrak, String terpasang, String? keterangan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kontrak',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      kontrak,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terpasang',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    Text(
                      terpasang,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (keterangan != null && keterangan.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Keterangan: $keterangan',
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureSection(
      Map<String, dynamic> data, String status, bool hasCoordinatorSign, bool hasApproverSign) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.draw, color: Colors.orange[700], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tanda Tangan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Coordinator Signature
          _buildSignatureCard(
            title: 'Koordinator',
            name: data['coordinatorName'],
            signedAt: data['coordinatorSignedAt'],
            signatureBase64: data['coordinatorSignature'],
            canSign: widget.role == 'coordinator' && !hasCoordinatorSign,
            onSign: () => _showSignatureDialog(data),
            cardColor: Colors.orange[50]!,
            borderColor: Colors.orange[200]!,
            iconColor: Colors.orange[700]!,
            buttonColor: Colors.orange[700]!,
          ),

          const SizedBox(height: 16),

          // Approver Signature
          _buildSignatureCard(
            title: 'Approver',
            name: data['approverName'],
            signedAt: data['approverSignedAt'],
            signatureBase64: data['approverSignature'],
            canSign: widget.role == 'approver' && hasCoordinatorSign && !hasApproverSign,
            onSign: () => _showSignatureDialog(data),
            cardColor: Colors.green[50]!,
            borderColor: Colors.green[200]!,
            iconColor: Colors.green[700]!,
            buttonColor: Colors.green[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard({
    required String title,
    String? name,
    dynamic signedAt,
    String? signatureBase64,
    required bool canSign,
    required VoidCallback onSign,
    required Color cardColor,
    required Color borderColor,
    required Color iconColor,
    required Color buttonColor,
  }) {
    bool hasSigned = signatureBase64 != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasSigned ? cardColor : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasSigned ? borderColor : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSigned ? Icons.check_circle : Icons.pending,
                color: hasSigned ? iconColor : Colors.grey[400],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasSigned ? iconColor : Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (hasSigned) ...[
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  base64Decode(signatureBase64),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (signedAt != null)
              Text(
                'Ditandatangani: ${_formatTimestamp(signedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
          ] else if (canSign) ...[
            ElevatedButton.icon(
              onPressed: onSign,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.draw, size: 18),
              label: const Text('Tanda Tangan'),
            ),
          ] else ...[
            Text(
              'Belum ditandatangani',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }
}