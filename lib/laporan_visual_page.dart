import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'session_manager.dart';
import 'project_model.dart';
import 'project_service.dart';

class LaporanVisualPage extends StatefulWidget {
  @override
  _LaporanVisualPageState createState() => _LaporanVisualPageState();
}

class _LaporanVisualPageState extends State<LaporanVisualPage> {
  ProjectModel? currentProject;
  bool _isLoading = true;
  bool _showForm = false;
  bool _isSaving = false;
  
  // Filter variables
  String? selectedTilok;
  String selectedJenisData = 'Foto';
  String selectedSubJenis = 'All';
  
  List<String> tilokList = [];
  List<String> subJenisList = [];
  List<Map<String, dynamic>> laporanData = [];
  
  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _tilokController = TextEditingController();
  final _eventController = TextEditingController();
  final _hariPertamaController = TextEditingController();
  final _jumlahSesiController = TextEditingController();
  final _sesiPertamaController = TextEditingController();
  final _jenisFotoController = TextEditingController();
  final _subJenisFotoController = TextEditingController();
  final _keteranganController = TextEditingController();
  
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _tilokController.dispose();
    _eventController.dispose();
    _hariPertamaController.dispose();
    _jumlahSesiController.dispose();
    _sesiPertamaController.dispose();
    _jenisFotoController.dispose();
    _subJenisFotoController.dispose();
    _keteranganController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error memilih gambar: $e')),
      );
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('laporan_visual')
          .child('${currentProject!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(_selectedImage!);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _saveData() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
      }
      
      await FirebaseFirestore.instance.collection('laporan_visual').add({
        'projectId': currentProject!.id,
        'tilok': _tilokController.text.trim(),
        'event': _eventController.text.trim(),
        'hariPertama': _hariPertamaController.text.trim(),
        'jumlahSesi': _jumlahSesiController.text.trim(),
        'sesiPertama': _sesiPertamaController.text.trim(),
        'jenisFoto': _jenisFotoController.text.trim(),
        'subJenisFoto': _subJenisFotoController.text.trim(),
        'keterangan': _keteranganController.text.trim(),
        'imageUrl': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data berhasil disimpan'),
          backgroundColor: Colors.green,
        ),
      );
      
      _clearForm();
      setState(() => _showForm = false);
      await _loadData();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menyimpan data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    setState(() => _isSaving = false);
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    _tilokController.clear();
    _eventController.clear();
    _hariPertamaController.clear();
    _jumlahSesiController.clear();
    _sesiPertamaController.clear();
    _jenisFotoController.clear();
    _subJenisFotoController.clear();
    _keteranganController.clear();
    setState(() => _selectedImage = null);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final projectId = await SessionManager.getCurrentProject();
      if (projectId != null) {
        currentProject = await ProjectService.getProjectById(projectId);
        await _loadTilokList();
        await _loadLaporanData();
      }
    } catch (e) {
      print('Error loading data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadTilokList() async {
    if (currentProject == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('laporan_visual')
          .where('projectId', isEqualTo: currentProject!.id)
          .get();
      
      Set<String> tiloks = {};
      for (var doc in snapshot.docs) {
        final tilok = doc.data()['tilok'] as String?;
        if (tilok != null && tilok.isNotEmpty) {
          tiloks.add(tilok);
        }
      }
      
      setState(() {
        tilokList = tiloks.toList()..sort();
        if (tilokList.isNotEmpty && selectedTilok == null) {
          selectedTilok = tilokList.first;
        }
      });
      
      await _loadSubJenisList();
    } catch (e) {
      print('Error loading tilok list: $e');
    }
  }

  Future<void> _loadSubJenisList() async {
    if (currentProject == null || selectedTilok == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('laporan_visual')
          .where('projectId', isEqualTo: currentProject!.id)
          .where('tilok', isEqualTo: selectedTilok)
          .get();
      
      Set<String> subJenis = {};
      for (var doc in snapshot.docs) {
        final jenis = doc.data()['subJenisFoto'] as String?;
        if (jenis != null && jenis.isNotEmpty) {
          subJenis.add(jenis);
        }
      }
      
      setState(() {
        subJenisList = ['All', ...subJenis.toList()..sort()];
        selectedSubJenis = 'All';
      });
    } catch (e) {
      print('Error loading sub jenis list: $e');
    }
  }

  Future<void> _loadLaporanData() async {
    if (currentProject == null || selectedTilok == null) return;
    
    try {
      Query query = FirebaseFirestore.instance
          .collection('laporan_visual')
          .where('projectId', isEqualTo: currentProject!.id)
          .where('tilok', isEqualTo: selectedTilok);
      
      if (selectedSubJenis != 'All') {
        query = query.where('subJenisFoto', isEqualTo: selectedSubJenis);
      }
      
      final snapshot = await query.orderBy('createdAt', descending: true).get();
      
      setState(() {
        laporanData = snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          return data;
        }).toList();
      });
    } catch (e) {
      print('Error loading laporan data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        title: Text('Laporan Visual Kegiatan'),
        elevation: 0,
        actions: [
          if (currentProject != null && !_showForm)
            IconButton(
              onPressed: () => setState(() => _showForm = true),
              icon: Icon(Icons.add_circle_outline),
              tooltip: 'Tambah Data',
            ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : currentProject == null
              ? _buildNoProjectWidget()
              : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isWeb ? 24 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeaderCard(isWeb),
                        SizedBox(height: 24),
                        
                        // Form Input (jika ditampilkan)
                        if (_showForm) ...[
                          _buildFormSection(isWeb),
                          SizedBox(height: 24),
                        ],
                        
                        // Filter Section
                        if (tilokList.isNotEmpty) ...[
                          _buildFilterSection(isWeb),
                          SizedBox(height: 24),
                        ],
                        
                        // Data Table
                        if (tilokList.isNotEmpty) _buildDataTable(isWeb),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildNoProjectWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
          SizedBox(height: 16),
          Text(
            'Tidak ada proyek aktif',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text('Silakan pilih proyek terlebih dahulu'),
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Data Laporan Visual',
                  style: TextStyle(
                    fontSize: isWeb ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() => _showForm = false);
                    _clearForm();
                  },
                  icon: Icon(Icons.close, color: Colors.blue.shade700),
                  tooltip: 'Hide',
                ),
              ],
            ),
            SizedBox(height: 20),
            
            if (isWeb)
              Row(
                children: [
                  Expanded(child: _buildTextField('Tilok', _tilokController, true)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField('Event', _eventController, true)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField('Hari pertama dimulai', _hariPertamaController, false)),
                ],
              )
            else ...[
              _buildTextField('Tilok', _tilokController, true),
              SizedBox(height: 12),
              _buildTextField('Event', _eventController, true),
              SizedBox(height: 12),
              _buildTextField('Hari pertama dimulai', _hariPertamaController, false),
            ],
            
            SizedBox(height: 12),
            
            if (isWeb)
              Row(
                children: [
                  Expanded(child: _buildTextField('Jumlah Sesi pada hari terakhir', _jumlahSesiController, false)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField('Sesi pada hari pertama', _sesiPertamaController, false)),
                ],
              )
            else ...[
              _buildTextField('Jumlah Sesi pada hari terakhir', _jumlahSesiController, false),
              SizedBox(height: 12),
              _buildTextField('Sesi pada hari pertama', _sesiPertamaController, false),
            ],
            
            SizedBox(height: 12),
            
            if (isWeb)
              Row(
                children: [
                  Expanded(child: _buildTextField('Jenis Foto', _jenisFotoController, true)),
                  SizedBox(width: 16),
                  Expanded(child: _buildTextField('Sub-jenis Foto', _subJenisFotoController, true)),
                ],
              )
            else ...[
              _buildTextField('Jenis Foto', _jenisFotoController, true),
              SizedBox(height: 12),
              _buildTextField('Sub-jenis Foto', _subJenisFotoController, true),
            ],
            
            SizedBox(height: 12),
            _buildTextField('Keterangan', _keteranganController, false, maxLines: 3),
            
            SizedBox(height: 16),
            
            // Image picker
            InkWell(
              onTap: _pickImage,
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade300, width: 2, style: BorderStyle.solid),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_photo_alternate, color: Colors.blue.shade600, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedImage != null ? 'Gambar dipilih' : 'Pilih Foto',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (_selectedImage != null)
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                  ],
                ),
              ),
            ),
            
            if (_selectedImage != null) ...[
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _selectedImage!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Simpan Data',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    bool required, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (required ? ' *' : ''),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.blue.shade900,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: required
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '$label harus diisi';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildHeaderCard(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.bar_chart, color: Colors.white, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LAPORAN VISUAL KEGIATAN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isWeb ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Divider(color: Colors.white.withOpacity(0.3), thickness: 1),
          SizedBox(height: 16),
          _buildProjectInfo('Nama Proyek', currentProject!.name, isWeb),
          SizedBox(height: 12),
          _buildProjectInfo('Titik Lokasi', currentProject!.city, isWeb),
          SizedBox(height: 12),
          _buildProjectInfo(
            'Tanggal Mulai',
            currentProject!.startDate != null
                ? _formatDate(currentProject!.startDate!)
                : 'Belum ditentukan',
            isWeb,
          ),
          SizedBox(height: 12),
          _buildProjectInfo(
            'Tanggal Selesai',
            currentProject!.endDate != null
                ? _formatDate(currentProject!.endDate!)
                : 'Belum ditentukan',
            isWeb,
          ),
          SizedBox(height: 12),
          // _buildProjectInfo(
          //   'Jangka Waktu',
          //   currentProject!.duration != null
          //       ? '${currentProject!.duration} Hari'
          //       : 'Belum ditentukan',
          //   isWeb,
          // ),
        ],
      ),
    );
  }

  Widget _buildProjectInfo(String label, String value, bool isWeb) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: isWeb ? 150 : 120,
          child: Text(
            '$label :',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: isWeb ? 15 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 15 : 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter Data',
            style: TextStyle(
              fontSize: isWeb ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          SizedBox(height: 16),
          if (isWeb)
            Row(
              children: [
                Expanded(child: _buildTilokDropdown(isWeb)),
                SizedBox(width: 16),
                Expanded(child: _buildSubJenisDropdown(isWeb)),
              ],
            )
          else
            Column(
              children: [
                _buildTilokDropdown(isWeb),
                SizedBox(height: 12),
                _buildSubJenisDropdown(isWeb),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTilokDropdown(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tilok',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedTilok,
              isExpanded: true,
              items: tilokList.map((tilok) {
                return DropdownMenuItem(
                  value: tilok,
                  child: Text(tilok),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() => selectedTilok = value);
                await _loadSubJenisList();
                await _loadLaporanData();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubJenisDropdown(bool isWeb) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jenis',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedSubJenis,
              isExpanded: true,
              items: subJenisList.map((jenis) {
                return DropdownMenuItem(
                  value: jenis,
                  child: Text(jenis),
                );
              }).toList(),
              onChanged: (value) async {
                setState(() => selectedSubJenis = value!);
                await _loadLaporanData();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(bool isWeb) {
    if (laporanData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Tidak ada data',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tilok',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Jenis Foto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Sub-jenis Foto',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Data rows
          ListView.separated(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: laporanData.length,
            separatorBuilder: (context, index) => Divider(height: 1),
            itemBuilder: (context, index) {
              final data = laporanData[index];
              return InkWell(
                onTap: () => _showDetailDialog(data, isWeb),
                child: Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          data['tilok'] ?? '-',
                          style: TextStyle(
                            color: index == 0 ? Colors.orange.shade700 : Colors.grey.shade800,
                            fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          data['jenisFoto'] ?? '-',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          data['subJenisFoto'] ?? '-',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showDetailDialog(Map<String, dynamic> data, bool isWeb) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail Laporan Visual'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Tilok', data['tilok'] ?? '-'),
              _buildDetailRow('Event', data['event'] ?? '-'),
              _buildDetailRow('Hari Pertama', data['hariPertama'] ?? '-'),
              _buildDetailRow('Jumlah Sesi', data['jumlahSesi'] ?? '-'),
              _buildDetailRow('Sesi Pertama', data['sesiPertama'] ?? '-'),
              _buildDetailRow('Jenis Foto', data['jenisFoto'] ?? '-'),
              _buildDetailRow('Sub-jenis Foto', data['subJenisFoto'] ?? '-'),
              if (data['keterangan'] != null && data['keterangan'].toString().isNotEmpty)
                _buildDetailRow('Keterangan', data['keterangan']),
              _buildDetailRow(
                'Tanggal',
                data['createdAt'] != null
                    ? _formatDate((data['createdAt'] as Timestamp).toDate())
                    : '-',
              ),
              if (data['imageUrl'] != null) ...[
                SizedBox(height: 16),
                Text(
                  'Foto:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    data['imageUrl'],
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: Icon(Icons.broken_image, size: 48),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.grey.shade800),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }
}