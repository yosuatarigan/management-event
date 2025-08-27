import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'berita_acara_service.dart';
import 'berita_acara_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';

class BeritaAcaraPage extends StatefulWidget {
  @override
  _BeritaAcaraPageState createState() => _BeritaAcaraPageState();
}

class _BeritaAcaraPageState extends State<BeritaAcaraPage> {
  final _searchController = TextEditingController();
  StatusBA? _selectedStatusFilter;
  JenisBA? _selectedJenisFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Berita Acara'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddBeritaAcaraDialog(),
            icon: Icon(Icons.add),
            tooltip: 'Tambah Berita Acara',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berita acara...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                SizedBox(height: 12),
                
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusFilter(),
                      SizedBox(width: 8),
                      _buildJenisFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Berita Acara List
          Expanded(
            child: StreamBuilder<List<BeritaAcaraModel>>(
              stream: BeritaAcaraService.getCurrentUserBeritaAcara(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final beritaAcaraList = _filterBeritaAcara(snapshot.data ?? []);

                if (beritaAcaraList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: beritaAcaraList.length,
                  itemBuilder: (context, index) {
                    return _buildBeritaAcaraCard(beritaAcaraList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusFilter() {
    return PopupMenuButton<StatusBA?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedStatusFilter != null ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color: _selectedStatusFilter != null ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedStatusFilter?.name ?? 'Status',
              style: TextStyle(
                color: _selectedStatusFilter != null ? Colors.blue.shade600 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Semua Status'),
        ),
        ...StatusBA.values.map((status) => PopupMenuItem(
          value: status,
          child: Text(status.name),
        )),
      ],
      onSelected: (value) {
        setState(() => _selectedStatusFilter = value);
      },
    );
  }

  Widget _buildJenisFilter() {
    return PopupMenuButton<JenisBA?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedJenisFilter != null ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color: _selectedJenisFilter != null ? Colors.orange.shade600 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedJenisFilter?.name ?? 'Jenis',
              style: TextStyle(
                color: _selectedJenisFilter != null ? Colors.orange.shade600 : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: null,
          child: Text('Semua Jenis'),
        ),
        ...JenisBA.values.map((jenis) => PopupMenuItem(
          value: jenis,
          child: Text(jenis.name),
        )),
      ],
      onSelected: (value) {
        setState(() => _selectedJenisFilter = value);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada berita acara',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Buat berita acara pertama Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddBeritaAcaraDialog(),
            icon: Icon(Icons.add),
            label: Text('Tambah Berita Acara'),
          ),
        ],
      ),
    );
  }

  Widget _buildBeritaAcaraCard(BeritaAcaraModel ba) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ba.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ba.statusDisplayName,
                              style: TextStyle(
                                color: ba.statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ba.jenisBADisplayName,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        ba.lokasiName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        ba.formattedDate,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleBeritaAcaraAction(value, ba),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'detail',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 20),
                          SizedBox(width: 8),
                          Text('Detail'),
                        ],
                      ),
                    ),
                    if (ba.status == StatusBA.pending) ...[
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    ],
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 20, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Hapus', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Isi BA Preview
            Text(
              ba.isiBA,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            // Lampiran indicator
            if (ba.lampiranUrls.isNotEmpty) ...[
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: Colors.grey.shade600),
                  SizedBox(width: 4),
                  Text(
                    '${ba.lampiranUrls.length} lampiran',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            // Rejection reason
            if (ba.status == StatusBA.rejected && ba.rejectionReason != null) ...[
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.red.shade600),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ditolak: ${ba.rejectionReason}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<BeritaAcaraModel> _filterBeritaAcara(List<BeritaAcaraModel> beritaAcaraList) {
    return beritaAcaraList.where((ba) {
      final matchesSearch = ba.lokasiName.toLowerCase().contains(_searchQuery) ||
          ba.isiBA.toLowerCase().contains(_searchQuery) ||
          ba.jenisBADisplayName.toLowerCase().contains(_searchQuery);
      
      final matchesStatus = _selectedStatusFilter == null || ba.status == _selectedStatusFilter;
      final matchesJenis = _selectedJenisFilter == null || ba.jenisBA == _selectedJenisFilter;
      
      return matchesSearch && matchesStatus && matchesJenis;
    }).toList();
  }

  void _handleBeritaAcaraAction(String action, BeritaAcaraModel ba) {
    switch (action) {
      case 'detail':
        _showDetailDialog(ba);
        break;
      case 'edit':
        _showEditBeritaAcaraDialog(ba);
        break;
      case 'delete':
        _showDeleteConfirmation(ba);
        break;
    }
  }

  void _showAddBeritaAcaraDialog() {
    showDialog(
      context: context,
      builder: (context) => BeritaAcaraFormDialog(
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Berita acara berhasil ditambahkan')),
          );
        },
      ),
    );
  }

  void _showEditBeritaAcaraDialog(BeritaAcaraModel ba) {
    showDialog(
      context: context,
      builder: (context) => BeritaAcaraFormDialog(
        beritaAcara: ba,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Berita acara berhasil diperbarui')),
          );
        },
      ),
    );
  }

  void _showDetailDialog(BeritaAcaraModel ba) {
    showDialog(
      context: context,
      builder: (context) => BeritaAcaraDetailDialog(beritaAcara: ba),
    );
  }

  void _showDeleteConfirmation(BeritaAcaraModel ba) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Berita Acara'),
        content: Text('Apakah Anda yakin ingin menghapus berita acara ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteBeritaAcara(ba),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteBeritaAcara(BeritaAcaraModel ba) async {
    Navigator.pop(context);
    
    try {
      await BeritaAcaraService.deleteBeritaAcara(ba.baId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Berita acara berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Form Dialog Widget
class BeritaAcaraFormDialog extends StatefulWidget {
  final BeritaAcaraModel? beritaAcara;
  final VoidCallback onSaved;

  const BeritaAcaraFormDialog({
    Key? key,
    this.beritaAcara,
    required this.onSaved,
  }) : super(key: key);

  @override
  _BeritaAcaraFormDialogState createState() => _BeritaAcaraFormDialogState();
}

class _BeritaAcaraFormDialogState extends State<BeritaAcaraFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _isiBAController = TextEditingController();
  
  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  JenisBA _selectedJenisBA = JenisBA.pembukaan;
  List<File> _selectedFiles = [];
  List<String> _existingLampiranUrls = [];
  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.beritaAcara != null) {
      _loadBeritaAcaraData(widget.beritaAcara!);
    }
  }

  void _loadBeritaAcaraData(BeritaAcaraModel ba) {
    _isiBAController.text = ba.isiBA;
    _selectedLokasiId = ba.lokasiId;
    _selectedLokasiName = ba.lokasiName;
    _selectedJenisBA = ba.jenisBA;
    _existingLampiranUrls = List.from(ba.lampiranUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: Theme.of(context).primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.beritaAcara == null ? 'Tambah Berita Acara' : 'Edit Berita Acara',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Lokasi
                      StreamBuilder<List<LocationModel>>(
                        stream: LocationService.getAllLocations(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          
                          final locations = snapshot.data ?? [];
                          
                          return DropdownButtonFormField<String>(
                            value: _selectedLokasiId.isEmpty ? null : _selectedLokasiId,
                            decoration: InputDecoration(
                              labelText: 'Lokasi *',
                              border: OutlineInputBorder(),
                            ),
                            items: locations.map((location) {
                              return DropdownMenuItem(
                                value: location.id,
                                child: Text('${location.name} - ${location.city}'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final selectedLocation = locations.firstWhere((loc) => loc.id == value);
                                setState(() {
                                  _selectedLokasiId = value;
                                  _selectedLokasiName = selectedLocation.name;
                                });
                              }
                            },
                            validator: (value) => value?.isEmpty ?? true ? 'Lokasi wajib dipilih' : null,
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Jenis BA
                      DropdownButtonFormField<JenisBA>(
                        value: _selectedJenisBA,
                        decoration: InputDecoration(
                          labelText: 'Jenis Berita Acara *',
                          border: OutlineInputBorder(),
                        ),
                        items: JenisBA.values.map((jenis) {
                          return DropdownMenuItem(
                            value: jenis,
                            child: Text(jenis.name),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedJenisBA = value!),
                      ),
                      SizedBox(height: 16),
                      
                      // Isi BA
                      TextFormField(
                        controller: _isiBAController,
                        decoration: InputDecoration(
                          labelText: 'Isi Berita Acara *',
                          border: OutlineInputBorder(),
                          hintText: 'Deskripsikan detail kegiatan atau kejadian...',
                        ),
                        maxLines: 5,
                        validator: (value) => value?.isEmpty ?? true ? 'Isi berita acara wajib diisi' : null,
                      ),
                      SizedBox(height: 16),
                      
                      // Lampiran Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Lampiran (Opsional)',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _showImageSourceDialog,
                                  icon: Icon(Icons.camera_alt, size: 20),
                                  label: Text('Ambil Foto'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            
                            // Selected Files Preview
                            if (_selectedFiles.isNotEmpty) ...[
                              Text('File yang dipilih:'),
                              SizedBox(height: 8),
                              ...List.generate(_selectedFiles.length, (index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _selectedFiles[index].path.split('/').last,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedFiles.removeAt(index);
                                          });
                                        },
                                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            
                            // Existing Files Preview
                            if (_existingLampiranUrls.isNotEmpty) ...[
                              Text('File yang sudah ada:'),
                              SizedBox(height: 8),
                              ...List.generate(_existingLampiranUrls.length, (index) {
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.photo, size: 20),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Lampiran ${index + 1}',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _existingLampiranUrls.removeAt(index);
                                          });
                                        },
                                        icon: Icon(Icons.delete, color: Colors.red, size: 20),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBeritaAcara,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.beritaAcara == null ? 'Tambah' : 'Update'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pilih Sumber Gambar'),
          content: Text('Ambil foto dari mana?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.camera);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.camera_alt),
                  SizedBox(width: 8),
                  Text('Kamera'),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _pickImageFromSource(ImageSource.gallery);
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library),
                  SizedBox(width: 8),
                  Text('Galeri'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _pickImageFromSource(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (image != null) {
        setState(() {
          _selectedFiles.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil gambar: $e')),
      );
    }
  }

  void _saveBeritaAcara() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();
      
      if (currentUser == null || currentUserData == null) {
        throw Exception('User not found');
      }

      // Create temporary BA ID for file uploads
      final tempBaId = widget.beritaAcara?.baId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload new files
      List<String> newLampiranUrls = [];
      if (_selectedFiles.isNotEmpty) {
        newLampiranUrls = await BeritaAcaraService.uploadMultipleFiles(_selectedFiles, tempBaId);
      }
      
      // Combine existing and new lampiran URLs
      final allLampiranUrls = [..._existingLampiranUrls, ...newLampiranUrls];

      final beritaAcara = BeritaAcaraModel(
        baId: widget.beritaAcara?.baId ?? '',
        koordinatorId: currentUser.uid,
        koordinatorName: currentUserData.name,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        jenisBA: _selectedJenisBA,
        isiBA: _isiBAController.text.trim(),
        lampiranUrls: allLampiranUrls,
        status: widget.beritaAcara?.status ?? StatusBA.pending,
        approvedBy: widget.beritaAcara?.approvedBy,
        approvedAt: widget.beritaAcara?.approvedAt,
        rejectionReason: widget.beritaAcara?.rejectionReason,
        createdAt: widget.beritaAcara?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.beritaAcara == null) {
        await BeritaAcaraService.createBeritaAcara(beritaAcara);
      } else {
        await BeritaAcaraService.updateBeritaAcara(widget.beritaAcara!.baId, beritaAcara);
      }

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _isiBAController.dispose();
    super.dispose();
  }
}

// Detail Dialog Widget
class BeritaAcaraDetailDialog extends StatelessWidget {
  final BeritaAcaraModel beritaAcara;

  const BeritaAcaraDetailDialog({Key? key, required this.beritaAcara}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: beritaAcara.statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.description, color: beritaAcara.statusColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Berita Acara',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: beritaAcara.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      beritaAcara.statusDisplayName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Jenis', beritaAcara.jenisBADisplayName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Lokasi', beritaAcara.lokasiName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Koordinator', beritaAcara.koordinatorName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Tanggal', beritaAcara.formattedDate),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    
                    // Isi BA
                    Text(
                      'Isi Berita Acara:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Text(
                        beritaAcara.isiBA,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    
                    // Lampiran
                    if (beritaAcara.lampiranUrls.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Lampiran:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: beritaAcara.lampiranUrls.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                beritaAcara.lampiranUrls[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, color: Colors.grey),
                                        Text('Gagal memuat', style: TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Rejection Reason
                    if (beritaAcara.status == StatusBA.rejected && beritaAcara.rejectionReason != null) ...[
                      SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red.shade600, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Alasan Penolakan:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              beritaAcara.rejectionReason!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // Actions
            Container(
              padding: EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Tutup'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}