import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:management_event/session_manager.dart';

class BADismantleFormPage extends StatefulWidget {
  final String? docId;

  const BADismantleFormPage({Key? key, this.docId}) : super(key: key);

  @override
  State<BADismantleFormPage> createState() => _BADismantleFormPageState();
}

class _BADismantleFormPageState extends State<BADismantleFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tilokController = TextEditingController();
  final _alamatController = TextEditingController();
  final _pesertaController = TextEditingController();
  final _hariController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _bulanController = TextEditingController();
  final _koordinatorController = TextEditingController();
  final _pengawasController = TextEditingController();
  final _nipPengawasController = TextEditingController();

  final Map<String, TextEditingController> _bControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize controllers untuk field b1-b39
    for (int i in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,19,20,21,22,23,24,25,26,27,28,29,30,32,34,35,36,38,39]) {
      _bControllers['b$i'] = TextEditingController(text: '2');
    }

    if (widget.docId != null) {
      _loadData();
    } else {
      // Load sample data untuk form baru (testing)
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    // Sample data untuk testing - langsung bisa klik simpan
    _tilokController.text = 'Jakarta Convention Center';
    _alamatController.text = 'Jl. Gatot Subroto Kav. 52-53, Jakarta Selatan';
    _pesertaController.text = '150';
    _hariController.text = 'Senin';
    _tanggalController.text = '20';
    _bulanController.text = 'Januari';
    _koordinatorController.text = 'Budi Santoso';
    _pengawasController.text = 'Dr. Ahmad Rizki, M.T.';
    _nipPengawasController.text = '198501012010011001';
    
    // Sample jumlah peralatan
    _bControllers['b1']?.text = '3';  // UPS Router
    _bControllers['b2']?.text = '2';  // UPS Modem
    _bControllers['b3']?.text = '2';  // Metal Detector
    _bControllers['b4']?.text = '4';  // Laptop Registrasi
    _bControllers['b5']?.text = '4';  // Webcam Registrasi
    _bControllers['b6']?.text = '4';  // Barcode Scanner
    _bControllers['b7']?.text = '4';  // LED Ring Light
    _bControllers['b8']?.text = '2';  // Printer Registrasi
    _bControllers['b9']?.text = '2';  // Laptop Monitoring
    _bControllers['b10']?.text = '2'; // Webcam Monitoring
    _bControllers['b11']?.text = '1'; // Printer Panitia
    _bControllers['b12']?.text = '1'; // Laptop Admin
    _bControllers['b13']?.text = '5'; // Container Box
    _bControllers['b14']?.text = '1'; // LCD Projector
    _bControllers['b15']?.text = '1'; // Laptop LCD Projector
    _bControllers['b16']?.text = '4'; // CCTV
    _bControllers['b19']?.text = '2'; // TV LCD
    _bControllers['b20']?.text = '1'; // Hardisk 2TB
    _bControllers['b21']?.text = '10'; // Meja Cover Ujian
    _bControllers['b22']?.text = '20'; // Kursi Cover Ujian
    _bControllers['b23']?.text = '2';  // Meja Penitipan Barang
    _bControllers['b24']?.text = '4';  // Kursi Penitipan
    _bControllers['b25']?.text = '2';  // Meja Transit
    _bControllers['b26']?.text = '4';  // Kursi Transit
    _bControllers['b27']?.text = '150'; // Kursi Peserta
    _bControllers['b28']?.text = '4';  // Meja Registrasi
    _bControllers['b29']?.text = '8';  // Kursi Registrasi
    _bControllers['b30']?.text = '200'; // Tenda Semi Dekor (m²)
    _bControllers['b32']?.text = '100'; // Tenda Sarnafil (m²)
    _bControllers['b34']?.text = '10'; // Pembatas Antrian
    _bControllers['b35']?.text = '2';  // Sound Portable
    _bControllers['b36']?.text = '6';  // AC Standing
    _bControllers['b38']?.text = '4';  // Misty Fan
    _bControllers['b39']?.text = '50'; // Genset (KVA)
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('ba_dismantle')
          .doc(widget.docId)
          .get();
      
      if (doc.exists) {
        var data = doc.data()!;
        _tilokController.text = data['tilok'] ?? '';
        _alamatController.text = data['alamat'] ?? '';
        _pesertaController.text = (data['peserta'] ?? 0).toString();
        _hariController.text = data['hari'] ?? '';
        _tanggalController.text = data['tanggal'] ?? '';
        _bulanController.text = data['bulan'] ?? '';
        _koordinatorController.text = data['koordinator'] ?? '';
        _pengawasController.text = data['pengawas'] ?? '';
        _nipPengawasController.text = data['nipPengawas'] ?? '';

        _bControllers.forEach((key, controller) {
          controller.text = (data[key] ?? 0).toString();
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Tambah BA Dismantle' : 'Edit BA Dismantle'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Info Banner - Sample Data
                  if (widget.docId == null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Form sudah terisi dengan data contoh. Langsung klik Simpan untuk testing.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildSectionCard(
                    icon: Icons.info_outline,
                    title: 'Informasi Umum',
                    color: Colors.blue,
                    children: [
                      _buildTextField('Titik Lokasi (TILOK)', _tilokController, Icons.location_on),
                      _buildTextField('Alamat', _alamatController, Icons.home, maxLines: 2),
                      _buildTextField('Jumlah Peserta', _pesertaController, Icons.people, isNumber: true),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Hari', _hariController, Icons.calendar_today)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('Tanggal', _tanggalController, Icons.date_range)),
                        ],
                      ),
                      _buildTextField('Bulan', _bulanController, Icons.event),
                      _buildTextField('Koordinator', _koordinatorController, Icons.person),
                      _buildTextField('Pengawas', _pengawasController, Icons.supervisor_account),
                      _buildTextField('NIP Pengawas', _nipPengawasController, Icons.badge),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.computer,
                    title: 'Peralatan Komputer & Jaringan',
                    color: Colors.purple,
                    children: [
                      _buildNumberField('UPS Router/Switch Hub', 'b1'),
                      _buildNumberField('UPS Modem Internet & Switch', 'b2'),
                      _buildNumberField('Laptop Registrasi', 'b4'),
                      _buildNumberField('Laptop Monitoring', 'b9'),
                      _buildNumberField('Laptop Admin', 'b12'),
                      _buildNumberField('Laptop LCD Projector', 'b15'),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.devices_other,
                    title: 'Peralatan Registrasi & Keamanan',
                    color: Colors.orange,
                    children: [
                      _buildNumberField('Metal Detector', 'b3'),
                      _buildNumberField('Webcam Registrasi', 'b5'),
                      _buildNumberField('LED Ring Light', 'b7'),
                      _buildNumberField('Barcode Scanner', 'b6'),
                      _buildNumberField('Printer Registrasi', 'b8'),
                    ],
                  ),

                  _buildSectionCard(
                    icon: Icons.videocam,
                    title: 'Peralatan Monitoring & Display',
                    color: Colors.teal,
                    children: [
                      _buildNumberField('Webcam Monitoring', 'b10'),
                      _buildNumberField('CCTV', 'b16'),
                      _buildNumberField('LCD Projector', 'b14'),
                      _buildNumberField('TV LCD + Standing Bracket', 'b19'),
                      _buildNumberField('Hardisk 2TB', 'b20'),
                    ],
                  ),

                  _buildSectionCard(
                    icon: Icons.print,
                    title: 'Peralatan Kantor',
                    color: Colors.indigo,
                    children: [
                      _buildNumberField('Printer Panitia Ruang Ujian', 'b11'),
                      _buildNumberField('Container Box', 'b13'),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.chair,
                    title: 'Meja & Kursi',
                    color: Colors.brown,
                    children: [
                      _buildNumberField('Meja Cover Ujian', 'b21'),
                      _buildNumberField('Kursi Cover Ujian', 'b22'),
                      _buildNumberField('Meja Penitipan Barang', 'b23'),
                      _buildNumberField('Kursi Penitipan', 'b24'),
                      _buildNumberField('Meja Transit', 'b25'),
                      _buildNumberField('Kursi Transit', 'b26'),
                      _buildNumberField('Kursi Peserta', 'b27'),
                      _buildNumberField('Meja Registrasi', 'b28'),
                      _buildNumberField('Kursi Registrasi', 'b29'),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.home_work,
                    title: 'Tenda & Pendingin',
                    color: Colors.green,
                    children: [
                      _buildNumberField('Tenda Semi Dekor (m²)', 'b30'),
                      _buildNumberField('Tenda Sarnafil (m²)', 'b32'),
                      _buildNumberField('AC Standing', 'b36'),
                      _buildNumberField('Misty Fan', 'b38'),
                    ],
                  ),

                  _buildSectionCard(
                    icon: Icons.settings,
                    title: 'Peralatan Lainnya',
                    color: Colors.red,
                    children: [
                      _buildNumberField('Pembatas Antrian', 'b34'),
                      _buildNumberField('Sound Portable', 'b35'),
                      _buildNumberField('Genset (KVA)', 'b39'),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Text(
                      widget.docId == null ? 'Simpan BA' : 'Update BA',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildNumberField(String label, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _bControllers[key],
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.numbers, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        keyboardType: TextInputType.number,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Field tidak boleh kosong';
          }
          return null;
        },
      ),
    );
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    final currentProjectId = SessionManager.currentProjectId;
    if (currentProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Tidak ada proyek aktif'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      int peserta = int.parse(_pesertaController.text);
      int cadangan = (peserta * 0.05).ceil();

      Map<String, dynamic> data = {
        'projectId': currentProjectId,
        'tilok': _tilokController.text,
        'alamat': _alamatController.text,
        'peserta': peserta,
        'cadangan': cadangan,
        'hari': _hariController.text,
        'tanggal': _tanggalController.text,
        'bulan': _bulanController.text,
        'koordinator': _koordinatorController.text,
        'pengawas': _pengawasController.text,
        'nipPengawas': _nipPengawasController.text,
        'status': 'draft',
        'createdAt': FieldValue.serverTimestamp(),
      };

      _bControllers.forEach((key, controller) {
        data[key] = int.tryParse(controller.text) ?? 0;
      });

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('ba_dismantle').add(data);
      } else {
        data.remove('createdAt');
        data['updatedAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('ba_dismantle')
            .doc(widget.docId)
            .update(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.docId == null ? 'BA berhasil disimpan' : 'BA berhasil diupdate'),
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _tilokController.dispose();
    _alamatController.dispose();
    _pesertaController.dispose();
    _hariController.dispose();
    _tanggalController.dispose();
    _bulanController.dispose();
    _koordinatorController.dispose();
    _pengawasController.dispose();
    _nipPengawasController.dispose();
    _bControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}