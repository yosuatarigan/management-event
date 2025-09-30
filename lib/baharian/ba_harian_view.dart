import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class BAHarianViewPage extends StatelessWidget {
  final String docId;

  const BAHarianViewPage({Key? key, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat BA Harian'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateAndSharePDF(context),
            tooltip: 'Save as PDF',
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('ba_harian')
            .doc(docId)
            .get(),
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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),
                _buildIntro(data),
                const SizedBox(height: 24),
                _buildTable1(data),
                const SizedBox(height: 24),
                _buildTable2(data),
                const SizedBox(height: 24),
                _buildFooter(data),
                const SizedBox(height: 24),
                _buildSignature(data),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateAndSharePDF(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      var doc = await FirebaseFirestore.instance
          .collection('ba_harian')
          .doc(docId)
          .get();

      if (!doc.exists) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tidak ditemukan')),
        );
        return;
      }

      var data = doc.data()!;
      final pdf = pw.Document();

      final imageData1 = await rootBundle.load('assets/baharian1.png');
      final imageData2 = await rootBundle.load('assets/baharian2.png');
      final image1 = pw.MemoryImage(imageData1.buffer.asUint8List());
      final image2 = pw.MemoryImage(imageData2.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          build: (context) => [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              children: [
                pw.Image(image1, width: 60, height: 60),
                pw.SizedBox(width: 16),
                pw.Image(image2, width: 60, height: 60),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('BERITA ACARA HARIAN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('JASA PENDUKUNG PENYELENGGARAAN KEGIATAN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                  pw.SizedBox(height: 4),
                  pw.Text('SELEKSI KOMPETENSI PPPK TAHAP II', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
              'Pada hari ini ${data['hari']}, tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua Ribu Dua Puluh Lima, telah dilaksanakan pekerjaan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori Jumlah Peserta Per Sesi ${data['peserta']} Orang di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']} rincian kegiatan sebagai berikut :',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),
            pw.Text('1. PELAKSANAAN PEKERJAAN', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildPdfTable([
              ['No', 'Uraian', 'Status', 'Keterangan'],
              ['1', 'Pelaksanaan Ujian Seleksi Harian', data['status1'], ''],
              ['a', 'Pelaksanaan Ujian Seleksi Sesi 1', data['status2'], ''],
              ['b', 'Pelaksanaan Ujian Seleksi Sesi 2', data['status3'], ''],
              ['c', 'Pelaksanaan Ujian Seleksi Sesi 3', data['status4'], ''],
              ['2', 'Jumlah laptop yang dapat digunakan', data['status6'], data['laptop']],
              ['3', 'Tenaga teknis yang standby', data['status7'], ''],
            ]),
            pw.SizedBox(height: 16),
            pw.Text('2. SARANA PRASARANA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildPdfTable([
              ['No', 'Uraian', 'Qty', 'Status'],
              ['1', 'Laptop peserta', '${data['peserta']}', 'Baik'],
              ['2', 'UPS router', '${data['b1']}', 'Baik'],
              ['3', 'UPS modem', '${data['b2']}', 'Baik'],
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
                      pw.SizedBox(height: 50),
                      pw.Text(data['pengawas'], style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('NIP. ${data['nipPengawas']}', style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('Dibuat Oleh :', style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('PT. Mitra Era Global', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 50),
                      pw.Text(data['koordinator'], style: const pw.TextStyle(fontSize: 10)),
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
      final file = File('${output.path}/BA_Harian_${data['tilok']}.pdf');
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
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Share PDF'),
                onTap: () async {
                  Navigator.pop(context);
                  await Share.shareXFiles([XFile(file.path)], text: 'BA Harian - ${data['tilok']}');
                },
              ),
              ListTile(
                leading: const Icon(Icons.remove_red_eye, color: Colors.blue),
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
          decoration: pw.BoxDecoration(color: isHeader ? PdfColors.blue100 : null),
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(cell, style: pw.TextStyle(fontSize: 8, fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal), textAlign: pw.TextAlign.center),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset('assets/baharian1.png', height: 70),
            const SizedBox(width: 16),
            Image.asset('assets/baharian2.png', height: 70),
          ],
        ),
        const SizedBox(height: 16),
        const Text('BERITA ACARA HARIAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const Text('JASA PENDUKUNG PENYELENGGARAAN KEGIATAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const Text('SELEKSI KOMPETENSI PPPK TAHAP II', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text('KATEGORI JUMLAH PESERTA PER SESI ${data['peserta']} ORANG', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        Text('TITIK LOKASI SELEKSI MANDIRI BKN ${data['tilok']}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
        const Text('TAHUN 2025', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildIntro(Map<String, dynamic> data) {
    return Text(
      'Pada hari ini ${data['hari']}, tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua Ribu Dua Puluh Lima, telah dilaksanakan pekerjaan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori Jumlah Peserta Per Sesi ${data['peserta']} Orang di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']} rincian kegiatan sebagai berikut :',
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildTable1(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('1. PELAKSANAAN PEKERJAAN', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Status', 'Keterangan'],
          ['1', 'Pelaksanaan Ujian Seleksi Harian', data['status1'], ''],
          ['a', 'Pelaksanaan Ujian Seleksi Sesi 1', data['status2'], ''],
          ['b', 'Pelaksanaan Ujian Seleksi Sesi 2', data['status3'], ''],
          ['c', 'Pelaksanaan Ujian Seleksi Sesi 3', data['status4'], ''],
          ['2', 'Jumlah laptop yang dapat digunakan', data['status6'], data['laptop']],
          ['3', 'Tenaga teknis yang standby', data['status7'], ''],
          ['4', 'Penundaan jadwal 1 hari+', data['status8'], ''],
          ['5', 'Penundaan jadwal 1 sesi+', data['status9'], ''],
          ['6', 'Volume utama terpenuhi', data['status10'], ''],
          ['7', 'Volume lainnya tersedia', data['status11'], ''],
        ]),
      ],
    );
  }

  Widget _buildTable2(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('2. SARANA PRASARANA', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Qty', 'Status'],
          ['1', 'Laptop peserta', '${data['peserta']}', 'Baik'],
          ['2', 'UPS router', '${data['b1']}', 'Baik'],
          ['3', 'UPS modem', '${data['b2']}', 'Baik'],
          ['4', 'Metal Detector', '${data['b3']}', 'Baik'],
          ['5', 'Laptop registrasi', '${data['b4']}', 'Baik'],
        ]),
      ],
    );
  }

  Widget _buildDataTable(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.grey)),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        children: rows.map((row) {
          bool isHeader = rows.indexOf(row) == 0;
          return TableRow(
            decoration: BoxDecoration(color: isHeader ? Colors.green[100] : Colors.white),
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Text(cell, style: TextStyle(fontSize: 10, fontWeight: isHeader ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(Map<String, dynamic> data) {
    return const Text(
      'Demikianlah berita acara ini dibuat dengan sebenarnya, untuk dapat diketahui dan dipergunakan sebagaimana mestinya.',
      textAlign: TextAlign.justify,
      style: TextStyle(fontSize: 12),
    );
  }

  Widget _buildSignature(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('Menerima dan menyetujui:', style: TextStyle(fontSize: 11)),
              const Text('Tim Pengawas Pekerjaan BKN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              Text(data['pengawas'], style: const TextStyle(fontSize: 11)),
              Text('NIP. ${data['nipPengawas']}', style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text('Dibuat Oleh :', style: TextStyle(fontSize: 11)),
              const Text('PT. Mitra Era Global', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              Text(data['koordinator'], style: const TextStyle(fontSize: 11)),
              const Text('Koordinator', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }
}