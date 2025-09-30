import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BADismantleViewPage extends StatelessWidget {
  final String docId;

  const BADismantleViewPage({Key? key, required this.docId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat BA Dismantle'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Export/Share functionality
            },
          ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('ba_dismantle')
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
                _buildTable3(data),
                const SizedBox(height: 24),
                _buildTable4(data),
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

  Widget _buildHeader(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/badismantle1.png', height: 80),
            const SizedBox(width: 16),
            Image.asset('assets/badismantle2.png', height: 80),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'BERITA ACARA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Text(
          'PEMBONGKARAN SARANA PRASARANA',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Text(
          'JASA PENDUKUNG PENYELENGGARAAN KEGIATAN SELEKSI KOMPETENSI',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          'PPPK TAHAP II KATEGORI JUMLAH PESERTA PER SESI ${data['peserta']} ORANG',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          'TITIK LOKASI SELEKSI MANDIRI BKN ${data['tilok']}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const Text(
          'TAHUN 2025',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildIntro(Map<String, dynamic> data) {
    return Text(
      'Pada hari ini ${data['hari']} tanggal ${data['tanggal']} bulan ${data['bulan']} tahun Dua Ribu Dua Puluh Lima, telah dilakukan pembongkaran sarana dan prasarana untuk keperluan Jasa Pendukung Penyelenggaraan Kegiatan Seleksi Kompetensi PPPK Tahap II Kategori Jumlah Peserta Per Sesi ${data['peserta']} Orang di titik lokasi mandiri ${data['tilok']} Tahun Anggaran 2025 yang berlokasi di ${data['alamat']} dengan rincian sebagai berikut :',
      textAlign: TextAlign.justify,
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _buildTable1(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '1. SARANA PRASARANA',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Qty', 'Satuan', 'Baik', 'Tidak Baik'],
          ['1', 'Laptop client peserta ujian', '${data['peserta']}', 'Unit', '${data['peserta']}', '-'],
          ['2', 'UPS router/switch hub', '${data['b1']}', 'Unit', '${data['b1']}', '-'],
          ['3', 'UPS modem internet', '${data['b2']}', 'Unit', '${data['b2']}', '-'],
          ['4', 'Laptop registrasi', '${data['b4']}', 'Unit', '${data['b4']}', '-'],
          ['5', 'Metal Detector', '${data['b3']}', 'Unit', '${data['b3']}', '-'],
          ['6', 'Webcam registrasi', '${data['b5']}', 'Unit', '${data['b5']}', '-'],
          ['7', 'LED ring light', '${data['b7']}', 'Unit', '${data['b7']}', '-'],
          ['8', 'Barcode scanner', '${data['b6']}', 'Unit', '${data['b6']}', '-'],
          ['9', 'Laptop monitoring', '${data['b9']}', 'Unit', '${data['b9']}', '-'],
          ['10', 'Webcam monitoring', '${data['b10']}', 'Unit', '${data['b10']}', '-'],
          ['11', 'Laptop admin', '${data['b12']}', 'Unit', '${data['b12']}', '-'],
          ['12', 'Meja penitipan barang', '${data['b23']}', 'Unit', '${data['b23']}', '-'],
          ['13', 'Kursi penitipan barang', '${data['b24']}', 'Unit', '${data['b24']}', '-'],
          ['14', 'Container box', '${data['b13']}', 'Unit', '${data['b13']}', '-'],
          ['15', 'Printer panitia', '${data['b11']}', 'Unit', '${data['b11']}', '-'],
          ['16', 'Laptop LCD Projector', '${data['b15']}', 'Unit', '${data['b15']}', '-'],
          ['17', 'LCD Projector', '${data['b14']}', 'Unit', '${data['b14']}', '-'],
          ['18', 'CCTV', '${data['b16']}', 'Unit', '${data['b16']}', '-'],
          ['19', 'Hardisk 2TB', '${data['b20']}', 'Unit', '${data['b20']}', '-'],
          ['20', 'TV LCD', '${data['b19']}', 'Unit', '${data['b19']}', '-'],
          ['21', 'Meja ujian', '${data['b21']}', 'Unit', '${data['b21']}', '-'],
          ['22', 'Kursi ujian', '${data['b22']}', 'Unit', '${data['b22']}', '-'],
          ['23', 'Meja transit', '${data['b25']}', 'Unit', '${data['b25']}', '-'],
          ['24', 'Kursi transit', '${data['b26']}', 'Unit', '${data['b26']}', '-'],
          ['25', 'Printer registrasi', '${data['b8']}', 'Unit', '${data['b8']}', '-'],
          ['26', 'Kursi peserta', '${data['b27']}', 'Unit', '${data['b27']}', '-'],
          ['27', 'Meja registrasi', '${data['b28']}', 'Unit', '${data['b28']}', '-'],
          ['28', 'Kursi registrasi', '${data['b29']}', 'Unit', '${data['b29']}', '-'],
          ['29', 'Pembatas antrian', '${data['b34']}', 'Unit', '${data['b34']}', '-'],
          ['30', 'Sound portable', '${data['b35']}', 'Unit', '${data['b35']}', '-'],
          ['31', 'Genset', '${data['b39']}', 'Unit', '${data['b39']}', '-'],
          ['32', 'ATK', '1', 'Paket', '1', '-'],
          ['33', 'Sewa Gedung', '1', 'Unit', '1', '-'],
          ['34', 'Sistem Aplikasi', '1', 'aplikasi', '1', '-'],
        ]),
      ],
    );
  }

  Widget _buildTable2(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. TENDA SEMI DEKOR, TENDA SARNAFIL, AC STANDING, DAN MISTY FAN',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Qty', 'Satuan', 'Baik', 'Tidak Baik'],
          ['1', 'Tenda Semi Dekor', '${data['b30']}', 'm2', '${data['b30']}', '-'],
          ['2', 'Tenda sarnafil', '${data['b32']}', 'm2', '${data['b32']}', '-'],
          ['3', 'AC Standing', '${data['b36']}', 'unit', '${data['b36']}', '-'],
          ['4', 'Misty Fan', '${data['b38']}', 'unit', '${data['b38']}', '-'],
        ]),
      ],
    );
  }

  Widget _buildTable3(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '3. SARANA PRASARANA BACKUP/CADANGAN',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Qty Kontrak', 'Satuan', 'Qty Pasang', 'Satuan', 'Baik', 'Tidak Baik'],
          ['1', 'Laptop Cadangan', '${data['cadangan']}', 'unit', '${data['cadangan']}', 'unit', '${data['cadangan']}', '-'],
        ]),
      ],
    );
  }

  Widget _buildTable4(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '4. SARANA PRASARANA LAINNYA',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDataTable([
          ['No', 'Uraian', 'Qty Kontrak', 'Satuan', 'Qty Pasang', 'Satuan', 'Baik', 'Tidak Baik'],
          ['1', 'APAR Powder 9 Kg', '2', 'Buah', '2', 'Buah', '2', '-'],
          ['2', 'Kotak P3K Tipe C', '1', 'Buah', '1', 'Buah', '1', '-'],
          ['3', 'Oksigen 500cc', '12', 'Buah', '12', 'Buah', '12', '-'],
          ['4', 'Kursi Roda', '2', 'Buah', '2', 'Buah', '2', '-'],
        ]),
      ],
    );
  }

  Widget _buildDataTable(List<List<String>> rows) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
      ),
      child: Table(
        border: TableBorder.all(color: Colors.grey),
        columnWidths: const {
          0: FixedColumnWidth(40),
        },
        children: rows.map((row) {
          bool isHeader = rows.indexOf(row) == 0;
          return TableRow(
            decoration: BoxDecoration(
              color: isHeader ? Colors.blue[100] : Colors.white,
            ),
            children: row.map((cell) {
              return Padding(
                padding: const EdgeInsets.all(6),
                child: Text(
                  cell,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooter(Map<String, dynamic> data) {
    return const Text(
      'Demikian Berita Acara ini dibuat dengan sebenarnya, untuk dapat diketahui dan dipergunakan sebagaimana mestinya.',
      textAlign: TextAlign.justify,
      style: TextStyle(fontSize: 12),
    );
  }

  Widget _buildSignature(Map<String, dynamic> data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [
              const Text(
                'Yang Menerima :',
                style: TextStyle(fontSize: 11),
              ),
              const Text(
                'Koordinator',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const Text(
                'PT. Mitra Era Global',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Text(
                data['koordinator'],
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            children: [
              const Text(
                'Yang menyerahkan :',
                style: TextStyle(fontSize: 11),
              ),
              const Text(
                'Tim Pengawas Pekerjaan BKN',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 60),
              Text(
                data['pengawas'],
                style: const TextStyle(fontSize: 11),
              ),
              Text(
                'NIP. ${data['nipPengawas']}',
                style: const TextStyle(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}