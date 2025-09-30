import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:io';

class BAPerubahanVolumeLuarKontrakViewPage extends StatelessWidget {
  final String docId;

  const BAPerubahanVolumeLuarKontrakViewPage({Key? key, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat BA'),
        backgroundColor: Colors.purple[700],
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
            .collection('ba_perubahan_volume_luar_kontrak')
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
                _buildPartyInfo(data),
                const SizedBox(height: 24),
                _buildContent(data),
                const SizedBox(height: 24),
                _buildItemsList(data),
                const SizedBox(height: 24),
                _buildFooter(),
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
          .collection('ba_perubahan_volume_luar_kontrak')
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
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Image(image1, width: 60, height: 80),
                pw.SizedBox(width: 16),
                pw.Image(image2, width: 280, height: 80),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(
                    'BERITA ACARA PENAMBAHAN VOLUME',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'SARANA PRASARANA DI LUAR PENAMBAHAN NILAI KONTRAK',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'NOMOR : ${data['nomorBA']}',
                    style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'Pada hari ini ${data['hari']} tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua ribu dua puluh lima (${data['tanggal']}-${_getMonthNumber(data['bulan'])}-2025), kami yang bertanda tangan di bawah ini:',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 16),
            _buildPdfPartyTable(data),
            pw.SizedBox(height: 16),
            pw.Text(
              '       Kedua belah pihak telah melakukan peninjauan Titik Lokasi seleksi CPPPK mandiri BKN ${data['tilok']}, dimana PIHAK PERTAMA dan PIHAK KEDUA telah menyetujui bahwa untuk meningkatkan kenyamanan dari peserta seleksi dan meningkatkan pelayanan kepada seluruh stakeholder selama pelaksanaan seleksi CPPPK ini, maka diperlukan tambahan volume sarana prasarana yang melebihi dari dokumen kontrak dan volume sarana prasarana diluar kontrak. Selain penambahan volume, juga terdapat penambahan sarana dan Prasarana Pelaksanaan Seleksi PPPK yang tidak tercantum dalam dokumen kontrak dan perubahannya. Adapun sarana prasana tersebut adalah:',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 11),
            ),
            pw.SizedBox(height: 12),
            ...List.generate((data['items'] as List).length, (index) {
              var item = data['items'][index];
              return pw.Padding(
                padding: const pw.EdgeInsets.only(left: 20, bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${index + 1}. ', style: const pw.TextStyle(fontSize: 11)),
                    pw.Expanded(
                      child: pw.Text(
                        '${item['deskripsi']} sejumlah ${item['jumlah']}',
                        style: const pw.TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
            pw.SizedBox(height: 20),
            pw.Padding(
              padding: const pw.EdgeInsets.only(left: 20),
              child: pw.Text(
                'Demikian Berita Acara ini dibuat, agar dapat dipergunakan sebagaimana mestinya.',
                textAlign: pw.TextAlign.justify,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.SizedBox(height: 30),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('PIHAK PERTAMA', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 60),
                      pw.Text(data['namaPihakPertama'], style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text('NIP. ${data['nipPihakPertama']}', style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('PIHAK KEDUA', style: const pw.TextStyle(fontSize: 11)),
                      pw.SizedBox(height: 60),
                      pw.Text(data['namaPihakKedua'], style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                      pw.Text(data['jabatanPihakKedua'], style: const pw.TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File('${output.path}/BA_Penambahan_${data['tilok']}.pdf');
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
                  await Share.shareXFiles([XFile(file.path)], text: 'BA Penambahan Volume - ${data['tilok']}');
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

  String _getMonthNumber(String bulan) {
    const months = {
      'Januari': '01', 'Februari': '02', 'Maret': '03', 'April': '04',
      'Mei': '05', 'Juni': '06', 'Juli': '07', 'Agustus': '08',
      'September': '09', 'Oktober': '10', 'November': '11', 'Desember': '12'
    };
    return months[bulan] ?? '01';
  }

  pw.Widget _buildPdfPartyTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FixedColumnWidth(130),
        2: const pw.FixedColumnWidth(15),
        3: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Center(child: pw.Text('I', style: const pw.TextStyle(fontSize: 11))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nama/NIP', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Jabatan', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(':', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(':', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('${data['namaPihakPertama']} / ${data['nipPihakPertama']}', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(data['jabatanPihakPertama'], style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Selanjutnya disebut sebagai PIHAK PERTAMA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
          ],
        ),
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Center(child: pw.Text('II', style: const pw.TextStyle(fontSize: 11))),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Nama', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text('Jabatan', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(':', style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(':', style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(data['namaPihakKedua'], style: const pw.TextStyle(fontSize: 11)),
                  pw.Text(data['jabatanPihakKedua'], style: const pw.TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
        pw.TableRow(
          children: [
            pw.SizedBox(),
            pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Text('Selanjutnya disebut sebagai PIHAK KEDUA', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
            ),
            pw.SizedBox(),
            pw.SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset('assets/baharian1.png', height: 70),
            const SizedBox(width: 16),
            Image.asset('assets/baharian2.png', height: 70),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'BERITA ACARA PENAMBAHAN VOLUME',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Text(
          'SARANA PRASARANA DI LUAR PENAMBAHAN NILAI KONTRAK',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'NOMOR : ${data['nomorBA']}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPartyInfo(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pada hari ini ${data['hari']} tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua ribu dua puluh lima, kami yang bertanda tangan di bawah ini:',
          textAlign: TextAlign.justify,
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 16),
        Table(
          border: TableBorder.all(color: Colors.black),
          columnWidths: const {
            0: FixedColumnWidth(40),
            1: FixedColumnWidth(120),
            2: FixedColumnWidth(20),
            3: FlexColumnWidth(),
          },
          children: [
            TableRow(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: Text('I', style: TextStyle(fontSize: 12))),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama/NIP', style: TextStyle(fontSize: 12)),
                      Text('Jabatan', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(':', style: TextStyle(fontSize: 12)),
                      Text(':', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${data['namaPihakPertama']} / ${data['nipPihakPertama']}', style: const TextStyle(fontSize: 12)),
                      Text(data['jabatanPihakPertama'], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const TableRow(
              children: [
                SizedBox(),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Selanjutnya disebut sebagai PIHAK PERTAMA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                SizedBox(),
                SizedBox(),
              ],
            ),
            TableRow(
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(child: Text('II', style: TextStyle(fontSize: 12))),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nama', style: TextStyle(fontSize: 12)),
                      Text('Jabatan', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(':', style: TextStyle(fontSize: 12)),
                      Text(':', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['namaPihakKedua'], style: const TextStyle(fontSize: 12)),
                      Text(data['jabatanPihakKedua'], style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const TableRow(
              children: [
                SizedBox(),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Selanjutnya disebut sebagai PIHAK KEDUA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                SizedBox(),
                SizedBox(),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContent(Map<String, dynamic> data) {
    return Text(
      '       Kedua belah pihak telah melakukan peninjauan Titik Lokasi seleksi CPPPK mandiri BKN ${data['tilok']}, dimana PIHAK PERTAMA dan PIHAK KEDUA telah menyetujui bahwa untuk meningkatkan kenyamanan dari peserta seleksi dan meningkatkan pelayanan kepada seluruh stakeholder selama pelaksanaan seleksi CPPPK ini, maka diperlukan tambahan volume sarana prasarana yang melebihi dari dokumen kontrak dan volume sarana prasarana diluar kontrak. Selain penambahan volume, juga terdapat penambahan sarana dan Prasarana Pelaksanaan Seleksi PPPK yang tidak tercantum dalam dokumen kontrak dan perubahannya. Adapun sarana prasana tersebut adalah:',
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildItemsList(Map<String, dynamic> data) {
    var items = data['items'] as List;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items.length, (index) {
        var item = items[index];
        return Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${index + 1}. ', style: const TextStyle(fontSize: 12)),
              Expanded(
                child: Text(
                  '${item['deskripsi']} sejumlah ${item['jumlah']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.only(left: 20),
      child: Text(
        'Demikian Berita Acara ini dibuat, agar dapat dipergunakan sebagaimana mestinya.',
        textAlign: TextAlign.justify,
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildSignature(Map<String, dynamic> data) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Text('PIHAK PERTAMA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              Text(data['namaPihakPertama'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text('NIP. ${data['nipPihakPertama']}', style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text('PIHAK KEDUA', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 60),
              Text(data['namaPihakKedua'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              Text(data['jabatanPihakKedua'], style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}