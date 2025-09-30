import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:management_event/baperubahanvolumediluarkontrak/ba_perubahan_volume_luar_kontrak.dart';

class BAPerubahanVolumeLuarKontrakFormPage extends StatefulWidget {
  final String? docId;

  const BAPerubahanVolumeLuarKontrakFormPage({Key? key, this.docId}) : super(key: key);

  @override
  State<BAPerubahanVolumeLuarKontrakFormPage> createState() => _BAPerubahanVolumeLuarKontrakFormPageState();
}

class _BAPerubahanVolumeLuarKontrakFormPageState extends State<BAPerubahanVolumeLuarKontrakFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomorBAController = TextEditingController();
  final _hariController = TextEditingController();
  final _tanggalController = TextEditingController();
  final _bulanController = TextEditingController();
  final _namaPihakPertamaController = TextEditingController();
  final _nipPihakPertamaController = TextEditingController();
  final _jabatanPihakPertamaController = TextEditingController();
  final _namaPihakKeduaController = TextEditingController();
  final _jabatanPihakKeduaController = TextEditingController();
  final _tilokController = TextEditingController();
  
  List<Map<String, TextEditingController>> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Sample data
    _nomorBAController.text = 'xxx/BA-Penambahan/Jakarta Pusat/V/2025';
    _hariController.text = 'Senin';
    _tanggalController.text = '15';
    _bulanController.text = 'Mei';
    _namaPihakPertamaController.text = 'Rovvi Karnata';
    _nipPihakPertamaController.text = '198409022009121002';
    _jabatanPihakPertamaController.text = 'Pengawas Sarana Prasarana Titik Lokasi Mandiri BKN';
    _namaPihakKeduaController.text = 'Dimas Hakim Sutrisno';
    _jabatanPihakKeduaController.text = 'Koordinator PT. Mitra Era Global';
    _tilokController.text = 'Jakarta Pusat';
    
    _addItem();
    _addItem();
    _addItem();

    if (widget.docId != null) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('ba_perubahan_volume_luar_kontrak')
          .doc(widget.docId)
          .get();
      
      if (doc.exists) {
        var data = doc.data()!;
        _nomorBAController.text = data['nomorBA'] ?? '';
        _hariController.text = data['hari'] ?? '';
        _tanggalController.text = data['tanggal'] ?? '';
        _bulanController.text = data['bulan'] ?? '';
        _namaPihakPertamaController.text = data['namaPihakPertama'] ?? '';
        _nipPihakPertamaController.text = data['nipPihakPertama'] ?? '';
        _jabatanPihakPertamaController.text = data['jabatanPihakPertama'] ?? '';
        _namaPihakKeduaController.text = data['namaPihakKedua'] ?? '';
        _jabatanPihakKeduaController.text = data['jabatanPihakKedua'] ?? '';
        _tilokController.text = data['tilok'] ?? '';
        
        _items.clear();
        var items = data['items'] as List<dynamic>? ?? [];
        for (var item in items) {
          _items.add({
            'deskripsi': TextEditingController(text: item['deskripsi'] ?? ''),
            'jumlah': TextEditingController(text: item['jumlah'] ?? ''),
          });
        }
        setState(() {});
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    setState(() {
      _items.add({
        'deskripsi': TextEditingController(text: 'Tambahan ...'),
        'jumlah': TextEditingController(text: '... unit'),
      });
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index]['deskripsi']?.dispose();
      _items[index]['jumlah']?.dispose();
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.docId == null ? 'Tambah BA' : 'Edit BA'),
        backgroundColor: Colors.purple[700],
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
                    color: Colors.purple,
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
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.person,
                    title: 'Pihak Pertama',
                    color: Colors.blue,
                    children: [
                      _buildTextField('Nama', _namaPihakPertamaController, Icons.person),
                      _buildTextField('NIP', _nipPihakPertamaController, Icons.badge),
                      _buildTextField('Jabatan', _jabatanPihakPertamaController, Icons.work, maxLines: 2),
                    ],
                  ),
                  
                  _buildSectionCard(
                    icon: Icons.people,
                    title: 'Pihak Kedua',
                    color: Colors.orange,
                    children: [
                      _buildTextField('Nama', _namaPihakKeduaController, Icons.person),
                      _buildTextField('Jabatan', _jabatanPihakKeduaController, Icons.work, maxLines: 2),
                    ],
                  ),
                  
                  Container(
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.add_box, color: Colors.green, size: 24),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Daftar Penambahan Volume',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: Colors.green),
                                onPressed: _addItem,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: List.generate(_items.length, (index) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${index + 1}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (_items.length > 1)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                            onPressed: () => _removeItem(index),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _items[index]['deskripsi'],
                                      decoration: InputDecoration(
                                        labelText: 'Deskripsi',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _items[index]['jumlah'],
                                      decoration: InputDecoration(
                                        labelText: 'Jumlah',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        filled: true,
                                        fillColor: Colors.white,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Field tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saveData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
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
      List<ItemPenambahan> items = _items.map((item) {
        return ItemPenambahan(
          deskripsi: item['deskripsi']!.text,
          jumlah: item['jumlah']!.text,
        );
      }).toList();

      Map<String, dynamic> data = {
        'nomorBA': _nomorBAController.text,
        'hari': _hariController.text,
        'tanggal': _tanggalController.text,
        'bulan': _bulanController.text,
        'namaPihakPertama': _namaPihakPertamaController.text,
        'nipPihakPertama': _nipPihakPertamaController.text,
        'jabatanPihakPertama': _jabatanPihakPertamaController.text,
        'namaPihakKedua': _namaPihakKeduaController.text,
        'jabatanPihakKedua': _jabatanPihakKeduaController.text,
        'tilok': _tilokController.text,
        'items': items.map((item) => item.toMap()).toList(),
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (widget.docId == null) {
        await FirebaseFirestore.instance.collection('ba_perubahan_volume_luar_kontrak').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('ba_perubahan_volume_luar_kontrak')
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
    _namaPihakPertamaController.dispose();
    _nipPihakPertamaController.dispose();
    _jabatanPihakPertamaController.dispose();
    _namaPihakKeduaController.dispose();
    _jabatanPihakKeduaController.dispose();
    _tilokController.dispose();
    for (var item in _items) {
      item['deskripsi']?.dispose();
      item['jumlah']?.dispose();
    }
    super.dispose();
  }
}