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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Lihat BA Harian'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _generateAndSharePDF(context),
            tooltip: 'Export PDF',
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContentCard(data),
                const SizedBox(height: 16),
                _buildInfoSection(data),
              ],
            ),
          );
        },
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description, color: Colors.green[700], size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BA Harian',
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
        ],
      ),
    );
  }

  Widget _buildInfoSection(Map<String, dynamic> data) {
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
          const Text(
            'Status Pelaksanaan',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatusItem('Status Harian', data['status1']),
          _buildStatusItem('Sesi 1', data['status2']),
          _buildStatusItem('Sesi 2', data['status3']),
          _buildStatusItem('Sesi 3', data['status4']),
          _buildStatusItem('Laptop Tersedia', data['status6']),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey[700]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: (value ?? '').toLowerCase().contains('terlaksana') || 
                     (value ?? '').toLowerCase().contains('tersedia')
                  ? Colors.green[50]
                  : Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value ?? '-',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: (value ?? '').toLowerCase().contains('terlaksana') || 
                       (value ?? '').toLowerCase().contains('tersedia')
                    ? Colors.green[700]
                    : Colors.orange[700],
              ),
            ),
          ),
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

      // Load images
      pw.MemoryImage? image1;
      pw.MemoryImage? image2;

      try {
        final imageData1 = await rootBundle.load('assets/baharian1.png');
        final imageData2 = await rootBundle.load('assets/baharian2.png');
        image1 = pw.MemoryImage(imageData1.buffer.asUint8List());
        image2 = pw.MemoryImage(imageData2.buffer.asUint8List());
      } catch (e) {
        print('Logo images not found: $e');
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(30),
          header: (context) {
            return pw.Column(
              children: [
                if (image1 != null && image2 != null)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Image(image1, width: 60, height: 60),
                      pw.Image(image2, width: 60, height: 60),
                    ],
                  ),
                pw.SizedBox(height: 16),
              ],
            );
          },
          build: (context) => [
            // Title
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('BERITA ACARA HARIAN',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('JASA PENDUKUNG PENYELENGGARAAN KEGIATAN',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('SELEKSI KOMPETENSI PPPK TAHAP II',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('KATEGORI JUMLAH PESERTA PER SESI ${data['peserta']} ORANG',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('TITIK LOKASI SELEKSI MANDIRI BKN ${data['tilok']}',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 4),
                  pw.Text('TAHUN 2025',
                      style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // Intro paragraph
            pw.Text(
              'Pada hari ini ${data['hari']}, tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua Ribu Dua Puluh Lima, telah dilaksanakan pekerjaan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori Jumlah Peserta Per Sesi ${data['peserta']} Orang di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']} rincian kegiatan sebagai berikut :',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 16),

            // A. PELAKSANAAN PEKERJAAN
            pw.Text('A. PELAKSANAAN PEKERJAAN',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildSimpleTable([
              ['No.', 'Uraian', 'Status', 'Keterangan'],
              ['1', 'Pelaksanaan Ujian Seleksi Harian', data['status1'] ?? '', ''],
              ['a', 'Pelaksanaan Ujian Seleksi Sesi 1', data['status2'] ?? '', ''],
              ['b', 'Pelaksanaan Ujian Seleksi Sesi 2', data['status3'] ?? '', ''],
              ['c', 'Pelaksanaan Ujian Seleksi Sesi 3', data['status4'] ?? '', ''],
              ['2', 'Jumlah laptop yang dapat digunakan', data['status6'] ?? '', data['laptop'] ?? ''],
              ['3', 'Tenaga teknis yang standby', data['status7'] ?? '', ''],
              ['4', 'Terjadi permasalahan terhadap sarana dan prasarana yang mengakibatkan penundaan jadwal seleksi hingga mundur satu hari atau lebih yang disebabkan oleh kesalahan penyedia', data['status8'] ?? '', ''],
              ['5', 'Terjadi permasalahan terhadap sarana dan prasarana yang mengakibatkan penundaan jadwal seleksi hingga mundur satu sesi atau lebih yang disebabkan oleh kesalahan penyedia', data['status9'] ?? '', ''],
              ['6', 'Volume sarana prasarana berikut tidak terpenuhi pada saat pelaksanaan seleksi : laptop ujian, laptop registrasi, CCTV, web cam dan tripod, UPS, meja ujian, serta kursi ujian', data['status10'] ?? '', ''],
              ['7', 'Volume sarana prasarana selain yang disebutkan pada angka 6 tidak tersedia pada saat pelaksanaan seleksi (contoh: volume meja registrasi, kursi ruang tunggu, sound portable, genset)', data['status11'] ?? '', ''],
            ]),
            pw.SizedBox(height: 16),

            // B. SARANA PRASARANA YANG TERSEDIA
            pw.Text('B. SARANA PRASARANA YANG TERSEDIA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildSaranaTable(data),
            pw.SizedBox(height: 16),

            // C. TENDA SEMI DEKOR
            pw.Text('C. TENDA SEMI DEKOR, TENDA SARNAFIL, AC STANDING, DAN MISTY FAN YANG TERSEDIA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildTendaTable(data),
            pw.SizedBox(height: 16),

            // D. BACKUP/CADANGAN
            pw.Text('D. SARANA PRASARANA BACKUP/CADANGAN',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildCadanganTable(data),
            pw.SizedBox(height: 16),

            // E. LAINNYA
            pw.Text('E. SARANA PRASARANA LAINNYA',
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            _buildLainnyaTable(),
            pw.SizedBox(height: 20),

            // Closing
            pw.Text(
              'Demikianlah berita acara ini dibuat dengan sebenarnya, untuk dapat diketahui dan dipergunakan sebagaimana mestinya.',
              textAlign: pw.TextAlign.justify,
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 30),

            // Signatures
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('Menerima dan menyetujui:',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Tim Pengawas Pekerjaan BKN',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 50),
                      pw.Text(data['pengawas'] ?? '',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('NIP. ${data['nipPengawas'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                pw.Expanded(
                  child: pw.Column(
                    children: [
                      pw.Text('Dibuat Oleh :',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('PT. Mitra Era Global',
                          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 50),
                      pw.Text(data['koordinator'] ?? '',
                          style: const pw.TextStyle(fontSize: 10)),
                      pw.Text('Koordinator',
                          style: const pw.TextStyle(fontSize: 10)),
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
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'BA Harian - ${data['tilok']}');
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

  // Fungsi helper untuk tabel sederhana (4 kolom)
  pw.Widget _buildSimpleTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(30),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(60),
        3: const pw.FixedColumnWidth(60),
      },
      children: rows.map((row) {
        bool isHeader = rows.indexOf(row) == 0;
        return pw.TableRow(
          decoration: pw.BoxDecoration(color: isHeader ? PdfColors.blue100 : null),
          children: row.map((cell) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                cell,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
                ),
                textAlign: (row.indexOf(cell) == 1 && !isHeader)
                    ? pw.TextAlign.left
                    : pw.TextAlign.center,
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  // Fungsi untuk tabel Sarana Prasarana (7 kolom dengan header merged)
  pw.Widget _buildSaranaTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(35),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(35),
        5: const pw.FixedColumnWidth(30),
        6: const pw.FixedColumnWidth(35),
        7: const pw.FixedColumnWidth(35),
        8: const pw.FixedColumnWidth(45),
      },
      children: [
        // Header row 1
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('No', true),
            _cell('Uraian', true),
            _cell('Jumlah sesuai kontrak dan perubahannnya', true),
            _cell('', true),
            _cell('Jumlah terpasang', true),
            _cell('', true),
            _cell('Status', true),
            _cell('', true),
            _cell('Keterangan', true),
          ],
        ),
        // Header row 2
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('', true),
            _cell('', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Baik', true),
            _cell('Tidak Baik', true),
            _cell('**)', true),
          ],
        ),
        // Data rows - SEMUA 34 item
        _dataRow8('1', 'Sewa laptop client untuk peserta ujian termasuk jaringan lan dan elektrikal',
            data['peserta'], 'unit', data['peserta'], 'unit', data['peserta'], '-', ''),
        _dataRow8('2', 'Sewa UPS untuk router/switch hub',
            data['b1'], 'unit', data['b1'], 'unit', data['b1'], '-', ''),
        _dataRow8('3', 'Sewa UPS untuk modem internet dan switch',
            data['b2'], 'unit', data['b2'], 'unit', data['b2'], '-', ''),
        _dataRow8('4', 'Sewa laptop client untuk registrasi peserta termasuk jaringan lan dan elektrikal',
            data['b4'], 'unit', data['b4'], 'unit', data['b4'], '-', ''),
        _dataRow8('5', 'Sewa Metal Detector',
            data['b3'], 'unit', data['b3'], 'unit', data['b3'], '-', ''),
        _dataRow8('6', 'Sewa webcam eksternal include tripod untuk registrasi peserta',
            data['b5'], 'unit', data['b5'], 'unit', data['b5'], '-', ''),
        _dataRow8('7', 'Sewa LED ring light include tripod untuk registrasi',
            data['b7'], 'unit', data['b7'], 'unit', data['b7'], '-', ''),
        _dataRow8('8', 'Sewa barcode scanner untuk registrasi peserta',
            data['b6'], 'unit', data['b6'], 'unit', data['b6'], '-', ''),
        _dataRow8('9', 'Sewa laptop client untuk monitoring ruang ujian termasuk jaringan lan dan elektrikal',
            data['b9'], 'unit', data['b9'], 'unit', data['b9'], '-', ''),
        _dataRow8('10', 'Sewa Webcam eksternal include tripod untuk monitoring ruang ujian',
            data['b10'], 'unit', data['b10'], 'unit', data['b10'], '-', ''),
        _dataRow8('11', 'Sewa laptop untuk admin termasuk jaringan lan dan elektrikal',
            data['b12'], 'unit', data['b12'], 'unit', data['b12'], '-', ''),
        _dataRow8('12', 'Sewa Meja Cover untuk Penerimaan dan pengambilan tempat penitipan barang',
            data['b23'], 'unit', data['b23'], 'unit', data['b23'], '-', ''),
        _dataRow8('13', 'Sewa Kursi susun tanpa cover untuk Penerimaan dan pengambilan tempat penitipan barang',
            data['b24'], 'unit', data['b24'], 'unit', data['b24'], '-', ''),
        _dataRow8('14', 'Sewa Container box',
            data['b13'], 'unit', data['b13'], 'unit', data['b13'], '-', ''),
        _dataRow8('15', 'Sewa Printer termasuk toner/tinta panitia ruang ujian',
            data['b11'], 'unit', data['b11'], 'unit', data['b11'], '-', ''),
        _dataRow8('16', 'Sewa laptop untuk LCD Projector termasuk elektrikal',
            data['b15'], 'unit', data['b15'], 'unit', data['b15'], '-', ''),
        _dataRow8('17', 'Sewa LCD Projector termasuk screen untuk ruang ujian min 3000 lumens',
            data['b14'], 'unit', data['b14'], 'unit', data['b14'], '-', ''),
        _dataRow8('18', 'Sewa CCTV termasuk display dan media penyimpanan',
            data['b16'], 'unit', data['b16'], 'unit', data['b16'], '-', ''),
        _dataRow8('19', 'Hardisk 2 TB',
            data['b20'], 'unit', data['b20'], 'unit', data['b20'], '-', ''),
        _dataRow8('20', 'Sewa TV LCD termasuk standing bracket, elektrikal, dan Flashdisk min 2GB',
            data['b19'], 'unit', data['b19'], 'unit', data['b19'], '-', ''),
        _dataRow8('21', 'Sewa meja cover untuk ruang ujian (${data['peserta']} unit + ${data['cadangan']} unit untuk cadangan)',
            data['b21'], 'unit', data['b21'], 'unit', data['b21'], '-', ''),
        _dataRow8('22', 'Sewa kursi susun cover untuk ruang ujian (${data['peserta']} unit + ${data['cadangan']} unit untuk cadangan)',
            data['b22'], 'unit', data['b22'], 'unit', data['b22'], '-', ''),
        _dataRow8('23', 'Sewa Meja Cover untuk panitia ruang transit',
            data['b25'], 'unit', data['b25'], 'unit', data['b25'], '-', ''),
        _dataRow8('24', 'Sewa Kursi susun tanpa cover untuk panitia ruang transit',
            data['b26'], 'unit', data['b26'], 'unit', data['b26'], '-', ''),
        _dataRow8('25', 'Sewa Printer termasuk toner/tinta registrasi',
            data['b8'], 'unit', data['b8'], 'unit', data['b8'], '-', ''),
        _dataRow8('26', 'Sewa kursi susun tanpa cover untuk peserta ruang transit, Registrasi, Steril',
            data['b27'], 'unit', data['b27'], 'unit', data['b27'], '-', ''),
        _dataRow8('27', 'Sewa Meja Cover untuk panitia ruang registrasi',
            data['b28'], 'unit', data['b28'], 'unit', data['b28'], '-', ''),
        _dataRow8('28', 'Sewa Kursi susun tanpa cover untuk panitia ruang registrasi',
            data['b29'], 'unit', data['b29'], 'unit', data['b29'], '-', ''),
        _dataRow8('29', 'Sewa pembatas antrian (1 kaki, 1 tiang,1 tali)',
            data['b34'], 'unit', data['b34'], 'unit', data['b34'], '-', ''),
        _dataRow8('30', 'Sewa Sound portable untuk ruang transit, registrasi, steril, ruang ujian dan Elektrikal',
            data['b35'], 'unit', data['b35'], 'unit', data['b35'], '-', ''),
        _dataRow8('31', 'Sewa Genset ${data['peserta']} KVA termasuk Solar + Teknisi Stanby min 12 Jam',
            data['b39'], 'unit', data['b39'], 'unit', data['b39'], '-', ''),
        _dataRow8('32', 'ATK peserta dan panitia',
            '1', 'paket', '1', 'paket', '1', '-', ''),
        _dataRow8('33', 'Sewa Gedung (Ruang untuk ujian)',
            '1', 'unit', '1', 'unit', '1', '-', ''),
        _dataRow8('34', 'Sistem Aplikasi Pengelolaan dan Pengendalian Pelaksanaan Seleksi di Seluruh Titik Lokasi Tes secara Online',
            '1', 'aplikasi', '1', 'aplikasi', '1', '-', ''),
      ],
    );
  }

  // Fungsi untuk tabel Tenda
  pw.Widget _buildTendaTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(50),
        3: const pw.FixedColumnWidth(40),
        4: const pw.FixedColumnWidth(40),
        5: const pw.FixedColumnWidth(50),
        6: const pw.FixedColumnWidth(50),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('No', true),
            _cell('Uraian', true),
            _cell('Jumlah terpasang', true),
            _cell('', true),
            _cell('Status', true),
            _cell('', true),
            _cell('Keterangan', true),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('', true),
            _cell('', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Baik', true),
            _cell('Tidak Baik', true),
            _cell('**)', true),
          ],
        ),
        _dataRow6('1', 'Sewa Tenda Semi Dekor Ruang Transit, Steril, Registrasi, Penitipan Barang + lampu min 40watt (tiap 25 m2) termasuk Elektrikal',
            data['b30'], 'm2', data['b30'], '-', ''),
        _dataRow6('2', 'Sewa tenda sarnafil untuk ruang medis termasuk elektrikal dan lampu (tiap 25 m2)',
            data['b32'], 'm2', data['b32'], '-', ''),
        _dataRow6('3', 'Sewa AC Standing untuk ruang ujian dan medis termasuk Elektrikal',
            data['b36'], 'unit', data['b36'], '-', ''),
        _dataRow6('4', 'Sewa Misty Fan termasuk pengisian airnya dan elektrikal untuk ruang transit, registrasi, steril',
            data['b38'], 'unit', data['b38'], '-', ''),
      ],
    );
  }

  // Fungsi untuk tabel Cadangan
  pw.Widget _buildCadanganTable(Map<String, dynamic> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(35),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(35),
        5: const pw.FixedColumnWidth(30),
        6: const pw.FixedColumnWidth(35),
        7: const pw.FixedColumnWidth(35),
        8: const pw.FixedColumnWidth(45),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('No', true),
            _cell('Uraian', true),
            _cell('Jumlah sesuai kontrak dan perubahannnya', true),
            _cell('', true),
            _cell('Jumlah terpasang', true),
            _cell('', true),
            _cell('Status', true),
            _cell('', true),
            _cell('Keterangan', true),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('', true),
            _cell('', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Baik', true),
            _cell('Tidak Baik', true),
            _cell('**)', true),
          ],
        ),
        _dataRow8('1', 'Laptop Cadangan Touch Screen (5% dari total laptop ujian)',
            data['cadangan'], 'unit', data['cadangan'], 'unit', data['cadangan'], '-', ''),
      ],
    );
  }

  // Fungsi untuk tabel Lainnya
  pw.Widget _buildLainnyaTable() {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey),
      columnWidths: {
        0: const pw.FixedColumnWidth(20),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(35),
        3: const pw.FixedColumnWidth(30),
        4: const pw.FixedColumnWidth(35),
        5: const pw.FixedColumnWidth(30),
        6: const pw.FixedColumnWidth(35),
        7: const pw.FixedColumnWidth(35),
        8: const pw.FixedColumnWidth(45),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('No', true),
            _cell('Uraian', true),
            _cell('Jumlah sesuai kontrak dan perubahannnya', true),
            _cell('', true),
            _cell('Jumlah terpasang', true),
            _cell('', true),
            _cell('Status', true),
            _cell('', true),
            _cell('Keterangan', true),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _cell('', true),
            _cell('', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Kuantitas', true),
            _cell('Satuan', true),
            _cell('Baik', true),
            _cell('Tidak Baik', true),
            _cell('**)', true),
          ],
        ),
        _dataRow8('1', 'APAR Powder 9 Kg', '2', 'Buah', '2', 'Buah', '2', '-', ''),
        _dataRow8('2', 'Kotak P3K Tipe C + Lengkap Dengan Isi', '1', 'Buah', '1', 'Buah', '1', '-', ''),
        _dataRow8('3', 'Oksigen 500cc', '12', 'Buah', '12', 'Buah', '12', '-', ''),
        _dataRow8('4', 'Kursi Roda', '2', 'Buah', '2', 'Buah', '2', '-', ''),
      ],
    );
  }

  // Helper functions
  pw.Widget _cell(String text, bool isBold) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.TableRow _dataRow8(String no, String uraian, dynamic k1, String s1,
      dynamic k2, String s2, dynamic baik, String tidakBaik, String ket) {
    return pw.TableRow(
      children: [
        _cell(no, false),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(uraian,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.left),
        ),
        _cell('$k1', false),
        _cell(s1, false),
        _cell('$k2', false),
        _cell(s2, false),
        _cell('$baik', false),
        _cell(tidakBaik, false),
        _cell(ket, false),
      ],
    );
  }

  pw.TableRow _dataRow6(String no, String uraian, dynamic k, String s,
      dynamic baik, String tidakBaik, String ket) {
    return pw.TableRow(
      children: [
        _cell(no, false),
        pw.Padding(
          padding: const pw.EdgeInsets.all(4),
          child: pw.Text(uraian,
              style: const pw.TextStyle(fontSize: 8),
              textAlign: pw.TextAlign.left),
        ),
        _cell('$k', false),
        _cell(s, false),
        _cell('$baik', false),
        _cell(tidakBaik, false),
        _cell(ket, false),
      ],
    );
  }
}