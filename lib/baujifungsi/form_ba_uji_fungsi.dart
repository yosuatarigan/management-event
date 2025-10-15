import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BAUjiFungsiFormPage extends StatefulWidget {
  final String? docId;

  const BAUjiFungsiFormPage({Key? key, this.docId}) : super(key: key);

  @override
  State<BAUjiFungsiFormPage> createState() => _BAUjiFungsiFormPageState();
}

class _BAUjiFungsiFormPageState extends State<BAUjiFungsiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomorBAController = TextEditingController();
  final _hariController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _bulanController = TextEditingController();
  final _tilokController = TextEditingController();
  final _alamatController = TextEditingController();
  final _koordinatorController = TextEditingController();
  final _pengawasController = TextEditingController();
  final _nipPengawasController = TextEditingController();

  int _jumlahPeserta = 100;
  List<TextEditingController> _laptopClientControllers = [];
  List<TextEditingController> _laptopBackupControllers = [];
  Map<String, bool> _peralatan = {};

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPeralatan();
    _generateLaptopControllers();
    
    if (widget.docId != null) {
      _loadData();
    }
  }

  void _initPeralatan() {
    // B1-B39 default checked (✓)
    for (int i = 1; i <= 39; i++) {
      _peralatan['B$i'] = true;
    }
  }

  void _generateLaptopControllers() {
    // Clear existing
    for (var c in _laptopClientControllers) {
      c.dispose();
    }
    for (var c in _laptopBackupControllers) {
      c.dispose();
    }
    
    _laptopClientControllers.clear();
    _laptopBackupControllers.clear();

    // Generate Laptop Client IDs based on jumlahPeserta
    for (int i = 1; i <= _jumlahPeserta; i++) {
      _laptopClientControllers.add(TextEditingController(text: 'ID$i'));
    }

    // Laptop Backup = jumlahPeserta / 20
    int jumlahBackup = (_jumlahPeserta / 20).ceil();
    for (int i = 1; i <= jumlahBackup; i++) {
      int idNum = _jumlahPeserta + i;
      _laptopBackupControllers.add(TextEditingController(text: 'ID$idNum'));
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('ba_uji_fungsi')
          .doc(widget.docId)
          .get();
      
      if (doc.exists) {
        var data = doc.data()!;
        _nomorBAController.text = data['nomorBA'] ?? '';
        _hariController.text = data['hari'] ?? '';
        _tanggalController.text = data['tanggal'] ?? '';
        _bulanController.text = data['bulan'] ?? '';
        _tilokController.text = data['tilok'] ?? '';
        _alamatController.text = data['alamat'] ?? '';
        _koordinatorController.text = data['koordinator'] ?? '';
        _pengawasController.text = data['pengawas'] ?? '';
        _nipPengawasController.text = data['nipPengawas'] ?? '';
        
        _jumlahPeserta = data['jumlahPeserta'] ?? 100;
        _generateLaptopControllers();
        
        var laptopIds = data['laptopClientIds'] as List<dynamic>? ?? [];
        for (int i = 0; i < laptopIds.length && i < _laptopClientControllers.length; i++) {
          _laptopClientControllers[i].text = laptopIds[i];
        }
        
        var backupIds = data['laptopBackupIds'] as List<dynamic>? ?? [];
        for (int i = 0; i < backupIds.length && i < _laptopBackupControllers.length; i++) {
          _laptopBackupControllers[i].text = backupIds[i];
        }
        
        var peralatanData = data['peralatan'] as Map<String, dynamic>? ?? {};
        peralatanData.forEach((key, value) {
          _peralatan[key] = value == '✓';
        });
        
        setState(() {});
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
        title: Text(widget.docId == null ? 'Tambah BA Uji Fungsi' : 'Edit BA Uji Fungsi'),
        backgroundColor: Colors.teal[700],
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
                  _buildSectionCard(
                    icon: Icons.info_outline,
                    title: 'Informasi BA',
                    color: Colors.teal,
                    children: [
                      _buildTextField('Nomor BA', _nomorBAController, Icons.numbers),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('Hari', _hariController, Icons.calendar_today)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField('Tanggal', _tanggalController, Icons.date_range)),
                        ],
                      ),
                      _buildTextField('Bulan', _bulanController, Icons.event),
                      _buildTextField('Titik Lokasi', _tilokController, Icons.location_on),
                      _buildTextField('Alamat', _alamatController, Icons.place, maxLines: 2),
                    ],
                  ),

                  _buildSectionCard(
                    icon: Icons.people,
                    title: 'Jumlah Peserta',
                    color: Colors.blue,
                    children: [
                      DropdownButtonFormField<int>(
                        value: _jumlahPeserta,
                        decoration: InputDecoration(
                          labelText: 'Pilih Jumlah Peserta',
                          prefixIcon: const Icon(Icons.group, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: [100, 200, 300, 400, 500].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value Peserta'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _jumlahPeserta = value!;
                            _generateLaptopControllers();
                          });
                        },
                      ),
                    ],
                  ),

                  _buildLaptopClientSection(),
                  _buildLaptopBackupSection(),
                  _buildPeralatanSection(),

                  _buildSectionCard(
                    icon: Icons.edit,
                    title: 'Tanda Tangan',
                    color: Colors.purple,
                    children: [
                      _buildTextField('Koordinator', _koordinatorController, Icons.person),
                      _buildTextField('Pengawas', _pengawasController, Icons.person),
                      _buildTextField('NIP Pengawas', _nipPengawasController, Icons.badge),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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

  Widget _buildLaptopClientSection() {
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
              color: Colors.orange.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.laptop, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Laptop Client Ujian ($_jumlahPeserta unit)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 2,
              ),
              itemCount: _laptopClientControllers.length,
              itemBuilder: (context, index) {
                return TextFormField(
                  controller: _laptopClientControllers[index],
                  decoration: InputDecoration(
                    labelText: '${index + 1}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaptopBackupSection() {
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
              color: Colors.red.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.laptop_chromebook, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Laptop Backup (${_laptopBackupControllers.length} unit)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_laptopBackupControllers.length, (index) {
                return SizedBox(
                  width: 80,
                  child: TextFormField(
                    controller: _laptopBackupControllers[index],
                    decoration: InputDecoration(
                      labelText: '${index + 1}',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 12),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeralatanSection() {
    final peralatanList = [
      'B1: UPS Router/Switch',
      'B2: UPS Modem & Switch',
      'B3: Metal Detector',
      'B4: Laptop Registrasi',
      'B5: Webcam & Tripod',
      'B6: Barcode',
      'B7: LED Ring Light',
      'B8: Printer Warna',
      'B9: Laptop Monitoring',
      'B10: Webcam & Tripod',
      'B11: Printer Admin',
      'B12: Laptop Admin',
      'B13: Container Box',
      'B14: LCD Projector',
      'B15: Laptop',
      'B16: CCTV Indoor',
      'B17: Display',
      'B18: Media Penyimpanan',
      'B19: TV LCD & Flashdisk',
      'B20: Hardisk 2TB',
      'B21: Meja Cover',
      'B22: Kursi Susun Cover',
      'B23: Meja Cover',
      'B24: Kursi Tanpa Cover',
      'B25: Meja Transit',
      'B26: Kursi Transit',
      'B27: Kursi Susun',
      'B28: Meja Registrasi',
      'B29: Kursi Registrasi',
      'B30: Tenda Semi Dekor',
      'B31: Lampu Tenda',
      'B32: Tenda Medis',
      'B33: Lampu Medis',
      'B34: Pembatas Antrian',
      'B35: Sound Portable',
      'B36: AC Ruang Ujian',
      'B37: AC Medis',
      'B38: Misty Fan',
      'B39: Genset',
    ];

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
              color: Colors.green.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.check_box, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Peralatan Pendukung',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: peralatanList.map((item) {
                String key = item.split(':')[0];
                return CheckboxListTile(
                  title: Text(item, style: const TextStyle(fontSize: 13)),
                  value: _peralatan[key] ?? true,
                  dense: true,
                  onChanged: (value) {
                    setState(() {
                      _peralatan[key] = value ?? true;
                    });
                  },
                );
              }).toList(),
            ),
          ),
        ],
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
      {int maxLines = 1}) {
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

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> laptopClientIds = _laptopClientControllers.map((c) => c.text).toList();
      List<String> laptopBackupIds = _laptopBackupControllers.map((c) => c.text).toList();
      
      Map<String, String> peralatanData = {};
      _peralatan.forEach((key, value) {
        peralatanData[key] = value ? '✓' : '-';
      });

      Map<String, dynamic> data = {
        'nomorBA': _nomorBAController.text,
        'hari': _hariController.text,
        'tanggal': _tanggalController.text,
        'bulan': _bulanController.text,
        'tilok': _tilokController.text,
        'alamat': _alamatController.text,
        'jumlahPeserta': _jumlahPeserta,
        'laptopClientIds': laptopClientIds,
        'laptopBackupIds': laptopBackupIds,
        'peralatan': peralatanData,
        'koordinator': _koordinatorController.text,
        'pengawas': _pengawasController.text,
        'nipPengawas': _nipPengawasController.text,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.docId == null) {
        data['status'] = 'draft';
        await FirebaseFirestore.instance.collection('ba_uji_fungsi').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('ba_uji_fungsi')
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
    _nomorBAController.dispose();
    _hariController.dispose();
    _tanggalController.dispose();
    _bulanController.dispose();
    _tilokController.dispose();
    _alamatController.dispose();
    _koordinatorController.dispose();
    _pengawasController.dispose();
    _nipPengawasController.dispose();
    for (var c in _laptopClientControllers) {
      c.dispose();
    }
    for (var c in _laptopBackupControllers) {
      c.dispose();
    }
    super.dispose();
  }
}