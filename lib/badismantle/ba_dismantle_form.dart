import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    
    // Initialize B controllers
    for (int i in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,19,20,21,22,23,24,25,26,27,28,29,30,32,34,35,36,38,39]) {
      _bControllers['b$i'] = TextEditingController();
    }

    if (widget.docId != null) {
      _loadData();
    }
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
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Tambah BA Dismantle' : 'Edit BA Dismantle'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSection('Informasi Umum', [
                    _buildTextField('Titik Lokasi (TILOK)', _tilokController),
                    _buildTextField('Alamat', _alamatController, maxLines: 2),
                    _buildTextField('Jumlah Peserta', _pesertaController, isNumber: true),
                    _buildTextField('Hari', _hariController),
                    _buildTextField('Tanggal', _tanggalController),
                    _buildTextField('Bulan', _bulanController),
                    _buildTextField('Koordinator', _koordinatorController),
                    _buildTextField('Pengawas', _pengawasController),
                    _buildTextField('NIP Pengawas', _nipPengawasController),
                  ]),
                  
                  _buildSection('Sarana Prasarana', [
                    _buildNumberField('UPS Router/Switch (B1)', 'b1'),
                    _buildNumberField('UPS Modem Internet (B2)', 'b2'),
                    _buildNumberField('Metal Detector (B3)', 'b3'),
                    _buildNumberField('Laptop Registrasi (B4)', 'b4'),
                    _buildNumberField('Webcam Registrasi (B5)', 'b5'),
                    _buildNumberField('Barcode Scanner (B6)', 'b6'),
                    _buildNumberField('LED Ring Light (B7)', 'b7'),
                    _buildNumberField('Printer Registrasi (B8)', 'b8'),
                    _buildNumberField('Laptop Monitoring (B9)', 'b9'),
                    _buildNumberField('Webcam Monitoring (B10)', 'b10'),
                    _buildNumberField('Printer Panitia (B11)', 'b11'),
                    _buildNumberField('Laptop Admin (B12)', 'b12'),
                    _buildNumberField('Container Box (B13)', 'b13'),
                    _buildNumberField('LCD Projector (B14)', 'b14'),
                    _buildNumberField('Laptop LCD (B15)', 'b15'),
                    _buildNumberField('CCTV (B16)', 'b16'),
                    _buildNumberField('TV LCD (B19)', 'b19'),
                    _buildNumberField('Hardisk 2TB (B20)', 'b20'),
                    _buildNumberField('Meja Cover Ujian (B21)', 'b21'),
                    _buildNumberField('Kursi Cover Ujian (B22)', 'b22'),
                    _buildNumberField('Meja Penitipan (B23)', 'b23'),
                    _buildNumberField('Kursi Penitipan (B24)', 'b24'),
                    _buildNumberField('Meja Transit (B25)', 'b25'),
                    _buildNumberField('Kursi Transit (B26)', 'b26'),
                    _buildNumberField('Kursi Peserta Transit (B27)', 'b27'),
                    _buildNumberField('Meja Registrasi (B28)', 'b28'),
                    _buildNumberField('Kursi Registrasi (B29)', 'b29'),
                  ]),
                  
                  _buildSection('Tenda & AC', [
                    _buildNumberField('Tenda Semi Dekor (m2) (B30)', 'b30'),
                    _buildNumberField('Tenda Sarnafil (m2) (B32)', 'b32'),
                    _buildNumberField('Pembatas Antrian (B34)', 'b34'),
                    _buildNumberField('Sound Portable (B35)', 'b35'),
                    _buildNumberField('AC Standing (B36)', 'b36'),
                    _buildNumberField('Misty Fan (B38)', 'b38'),
                    _buildNumberField('Genset KVA (B39)', 'b39'),
                  ]),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.docId == null ? 'Simpan' : 'Update'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool isNumber = false, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        'createdAt': FieldValue.serverTimestamp(),
      };

      _bControllers.forEach((key, controller) {
        data[key] = int.parse(controller.text);
      });

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('ba_dismantle').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('ba_dismantle')
            .doc(widget.docId)
            .update(data);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.docId == null ? 'BA berhasil disimpan' : 'BA berhasil diupdate')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
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