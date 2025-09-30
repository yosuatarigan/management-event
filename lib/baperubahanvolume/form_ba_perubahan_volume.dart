import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BAPerubahanVolumeFormPage extends StatefulWidget {
  final String? docId;

  const BAPerubahanVolumeFormPage({Key? key, this.docId}) : super(key: key);

  @override
  State<BAPerubahanVolumeFormPage> createState() => _BAPerubahanVolumeFormPageState();
}

class _BAPerubahanVolumeFormPageState extends State<BAPerubahanVolumeFormPage> {
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

  // Tenda Semi Dekor
  final _b30lController = TextEditingController();
  final _b30bController = TextEditingController();
  final _k1Controller = TextEditingController();
  
  // Tenda Sarnafil
  final _b32lController = TextEditingController();
  final _b32bController = TextEditingController();
  final _k2Controller = TextEditingController();
  
  // AC Standing
  final _b36lController = TextEditingController();
  final _b36bController = TextEditingController();
  final _k3Controller = TextEditingController();
  
  // Misty Fan
  final _b38lController = TextEditingController();
  final _b38bController = TextEditingController();
  final _k4Controller = TextEditingController();

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
    
    _b30lController.text = '50';
    _b30bController.text = '60';
    _k1Controller.text = 'Penambahan';
    
    _b32lController.text = '25';
    _b32bController.text = '25';
    _k2Controller.text = 'Sesuai kontrak';
    
    _b36lController.text = '4';
    _b36bController.text = '5';
    _k3Controller.text = 'Penambahan';
    
    _b38lController.text = '3';
    _b38bController.text = '2';
    _k4Controller.text = 'Pengurangan';

    if (widget.docId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('ba_perubahan_volume')
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
        
        _b30lController.text = (data['b30l'] ?? 0).toString();
        _b30bController.text = (data['b30b'] ?? 0).toString();
        _k1Controller.text = data['k1'] ?? '';
        
        _b32lController.text = (data['b32l'] ?? 0).toString();
        _b32bController.text = (data['b32b'] ?? 0).toString();
        _k2Controller.text = data['k2'] ?? '';
        
        _b36lController.text = (data['b36l'] ?? 0).toString();
        _b36bController.text = (data['b36b'] ?? 0).toString();
        _k3Controller.text = data['k3'] ?? '';
        
        _b38lController.text = (data['b38l'] ?? 0).toString();
        _b38bController.text = (data['b38b'] ?? 0).toString();
        _k4Controller.text = data['k4'] ?? '';
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
        title: Text(widget.docId == null ? 'Tambah BA Perubahan Volume' : 'Edit BA Perubahan Volume'),
        backgroundColor: Colors.orange[700],
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
                    color: Colors.orange,
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
                    icon: Icons.home_work,
                    title: 'Tenda Semi Dekor',
                    color: Colors.blue,
                    children: [
                      _buildTextField('Jumlah Kontrak (m²)', _b30lController, Icons.numbers, isNumber: true),
                      _buildTextField('Jumlah Terpasang (m²)', _b30bController, Icons.numbers, isNumber: true),
                      _buildTextField('Keterangan', _k1Controller, Icons.note),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.cabin,
                    title: 'Tenda Sarnafil',
                    color: Colors.teal,
                    children: [
                      _buildTextField('Jumlah Kontrak (m²)', _b32lController, Icons.numbers, isNumber: true),
                      _buildTextField('Jumlah Terpasang (m²)', _b32bController, Icons.numbers, isNumber: true),
                      _buildTextField('Keterangan', _k2Controller, Icons.note),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.ac_unit,
                    title: 'AC Standing',
                    color: Colors.cyan,
                    children: [
                      _buildTextField('Jumlah Kontrak (unit)', _b36lController, Icons.numbers, isNumber: true),
                      _buildTextField('Jumlah Terpasang (unit)', _b36bController, Icons.numbers, isNumber: true),
                      _buildTextField('Keterangan', _k3Controller, Icons.note),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.air,
                    title: 'Misty Fan',
                    color: Colors.purple,
                    children: [
                      _buildTextField('Jumlah Kontrak (unit)', _b38lController, Icons.numbers, isNumber: true),
                      _buildTextField('Jumlah Terpasang (unit)', _b38bController, Icons.numbers, isNumber: true),
                      _buildTextField('Keterangan', _k4Controller, Icons.note),
                    ],
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
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

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data = {
        'tilok': _tilokController.text,
        'alamat': _alamatController.text,
        'peserta': int.parse(_pesertaController.text),
        'hari': _hariController.text,
        'tanggal': _tanggalController.text,
        'bulan': _bulanController.text,
        'koordinator': _koordinatorController.text,
        'pengawas': _pengawasController.text,
        'nipPengawas': _nipPengawasController.text,
        'b30l': int.tryParse(_b30lController.text) ?? 0,
        'b30b': int.tryParse(_b30bController.text) ?? 0,
        'k1': _k1Controller.text,
        'b32l': int.tryParse(_b32lController.text) ?? 0,
        'b32b': int.tryParse(_b32bController.text) ?? 0,
        'k2': _k2Controller.text,
        'b36l': int.tryParse(_b36lController.text) ?? 0,
        'b36b': int.tryParse(_b36bController.text) ?? 0,
        'k3': _k3Controller.text,
        'b38l': int.tryParse(_b38lController.text) ?? 0,
        'b38b': int.tryParse(_b38bController.text) ?? 0,
        'k4': _k4Controller.text,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('ba_perubahan_volume').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('ba_perubahan_volume')
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
    _b30lController.dispose();
    _b30bController.dispose();
    _k1Controller.dispose();
    _b32lController.dispose();
    _b32bController.dispose();
    _k2Controller.dispose();
    _b36lController.dispose();
    _b36bController.dispose();
    _k3Controller.dispose();
    _b38lController.dispose();
    _b38bController.dispose();
    _k4Controller.dispose();
    super.dispose();
  }
}