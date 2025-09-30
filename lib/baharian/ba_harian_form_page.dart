import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BAHarianFormPage extends StatefulWidget {
  final String? docId;

  const BAHarianFormPage({Key? key, this.docId}) : super(key: key);

  @override
  State<BAHarianFormPage> createState() => _BAHarianFormPageState();
}

class _BAHarianFormPageState extends State<BAHarianFormPage> {
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
  final _laptopController = TextEditingController();

  // Status controllers
  String _status1 = 'Terlaksana';
  String _status2 = 'Terlaksana';
  String _status3 = 'Terlaksana';
  String _status4 = 'Tidak Terlaksana';
  String _status6 = 'Tersedia';
  String _status7 = 'Tersedia';
  String _status8 = 'Tidak Terjadi';
  String _status9 = 'Tidak Terjadi';
  String _status10 = 'Terpenuhi';
  String _status11 = 'Tersedia';

  final Map<String, TextEditingController> _bControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Sample data
    _tilokController.text = 'Jakarta Pusat';
    _alamatController.text = 'Jl. Sudirman No. 123, Jakarta';
    _pesertaController.text = '100';
    _hariController.text = 'Senin';
    _tanggalController.text = '15';
    _bulanController.text = 'Januari';
    _koordinatorController.text = 'Budi Santoso';
    _pengawasController.text = 'Ahmad Rizki';
    _nipPengawasController.text = '198501012010011001';
    _laptopController.text = '105';
    
    for (int i in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,19,20,21,22,23,24,25,26,27,28,29,30,32,34,35,36,38,39]) {
      _bControllers['b$i'] = TextEditingController(text: '2');
    }

    if (widget.docId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('ba_harian')
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
        _laptopController.text = data['laptop'] ?? '';
        
        _status1 = data['status1'] ?? 'Terlaksana';
        _status2 = data['status2'] ?? 'Terlaksana';
        _status3 = data['status3'] ?? 'Terlaksana';
        _status4 = data['status4'] ?? 'Tidak Terlaksana';
        _status6 = data['status6'] ?? 'Tersedia';
        _status7 = data['status7'] ?? 'Tersedia';
        _status8 = data['status8'] ?? 'Tidak Terjadi';
        _status9 = data['status9'] ?? 'Tidak Terjadi';
        _status10 = data['status10'] ?? 'Terpenuhi';
        _status11 = data['status11'] ?? 'Tersedia';

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
        title: Text(widget.docId == null ? 'Tambah BA Harian' : 'Edit BA Harian'),
        backgroundColor: Colors.green[700],
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
                    title: 'Informasi Umum',
                    color: Colors.green,
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
                    icon: Icons.assignment_turned_in,
                    title: 'Status Pelaksanaan',
                    color: Colors.orange,
                    children: [
                      _buildDropdownField('Pelaksanaan Ujian Harian', 1, ['Terlaksana', 'Tidak Terlaksana']),
                      _buildDropdownField('Pelaksanaan Sesi 1', 2, ['Terlaksana', 'Tidak Terlaksana']),
                      _buildDropdownField('Pelaksanaan Sesi 2', 3, ['Terlaksana', 'Tidak Terlaksana']),
                      _buildDropdownField('Pelaksanaan Sesi 3', 4, ['Tidak Terlaksana', 'Terlaksana']),
                      _buildTextField('Jumlah Laptop Digunakan', _laptopController, Icons.laptop, isNumber: true),
                      _buildDropdownField('Laptop Tersedia', 6, ['Tersedia', 'Tidak Tersedia']),
                      _buildDropdownField('Tenaga Teknis Standby', 7, ['Tersedia', 'Tidak Tersedia']),
                      _buildDropdownField('Penundaan 1 Hari+', 8, ['Tidak Terjadi', 'Terjadi']),
                      _buildDropdownField('Penundaan 1 Sesi+', 9, ['Tidak Terjadi', 'Terjadi']),
                      _buildDropdownField('Volume Utama Terpenuhi', 10, ['Terpenuhi', 'Tidak Terpenuhi']),
                      _buildDropdownField('Volume Lainnya Tersedia', 11, ['Tersedia', 'Tidak Tersedia']),
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
                    color: Colors.red,
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
                    color: Colors.cyan,
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
                    color: Colors.pink,
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
                      backgroundColor: Colors.green[700],
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

  Widget _buildDropdownField(String label, int statusNum, List<String> options) {
    String getStatusValue(int num) {
      switch(num) {
        case 1: return _status1;
        case 2: return _status2;
        case 3: return _status3;
        case 4: return _status4;
        case 6: return _status6;
        case 7: return _status7;
        case 8: return _status8;
        case 9: return _status9;
        case 10: return _status10;
        case 11: return _status11;
        default: return options[0];
      }
    }

    void setStatusValue(int num, String value) {
      setState(() {
        switch(num) {
          case 1: _status1 = value; break;
          case 2: _status2 = value; break;
          case 3: _status3 = value; break;
          case 4: _status4 = value; break;
          case 6: _status6 = value; break;
          case 7: _status7 = value; break;
          case 8: _status8 = value; break;
          case 9: _status9 = value; break;
          case 10: _status10 = value; break;
          case 11: _status11 = value; break;
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: getStatusValue(statusNum),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.check_circle_outline, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setStatusValue(statusNum, newValue);
          }
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

    setState(() => _isLoading = true);

    try {
      int peserta = int.parse(_pesertaController.text);
      int cadangan = (peserta * 0.05).ceil();

      Map<String, dynamic> data = {
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
        'laptop': _laptopController.text,
        'status1': _status1, 'status2': _status2, 'status3': _status3,
        'status4': _status4, 'status6': _status6, 'status7': _status7,
        'status8': _status8, 'status9': _status9, 'status10': _status10,
        'status11': _status11,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      _bControllers.forEach((key, controller) {
        data[key] = int.tryParse(controller.text) ?? 0;
      });

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('ba_harian').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('ba_harian')
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
    _laptopController.dispose();
    _bControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }
}