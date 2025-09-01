import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:management_event/user_model.dart';
import 'evidence_service.dart';
import 'evidence_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';

class EvidencePage extends StatefulWidget {
  @override
  _EvidencePageState createState() => _EvidencePageState();
}

class _EvidencePageState extends State<EvidencePage> {
  final _searchController = TextEditingController();
  StatusEvidence? _selectedStatusFilter;
  KategoriEvidence? _selectedKategoriFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evidence'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showUploadEvidenceDialog(),
            icon: Icon(Icons.add_a_photo),
            tooltip: 'Upload Evidence',
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
                    hintText: 'Cari evidence...',
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
                      _buildKategoriFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Evidence List
          Expanded(
            child: StreamBuilder<List<EvidenceModel>>(
              stream: EvidenceService.getCurrentUserEvidence(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final evidenceList = _filterEvidence(snapshot.data ?? []);

                if (evidenceList.isEmpty) {
                  return _buildEmptyState();
                }

                return GridView.builder(
                  padding: EdgeInsets.all(16),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: evidenceList.length,
                  itemBuilder: (context, index) {
                    return _buildEvidenceCard(evidenceList[index]);
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
    Color getStatusColor(StatusEvidence? status) {
      if (status == null) return Colors.grey.shade600;
      switch (status) {
        case StatusEvidence.pending:
          return Colors.orange;
        case StatusEvidence.approved:
          return Colors.green;
        case StatusEvidence.rejected:
          return Colors.red;
      }
    }

    return PopupMenuButton<StatusEvidence?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              _selectedStatusFilter != null
                  ? getStatusColor(_selectedStatusFilter).withOpacity(0.1)
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 16,
              color:
                  _selectedStatusFilter != null
                      ? getStatusColor(_selectedStatusFilter)
                      : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedStatusFilter?.toString().split('.').last ?? 'Status',
              style: TextStyle(
                color:
                    _selectedStatusFilter != null
                        ? getStatusColor(_selectedStatusFilter)
                        : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(value: null, child: Text('Semua Status')),
            ...StatusEvidence.values.map(
              (status) => PopupMenuItem(
                value: status,
                child: Text(status.toString().split('.').last),
              ),
            ),
          ],
      onSelected: (value) {
        setState(() => _selectedStatusFilter = value);
      },
    );
  }

  Widget _buildKategoriFilter() {
    String getKategoriDisplayName(KategoriEvidence kategori) {
      switch (kategori) {
        case KategoriEvidence.foto:
          return 'Foto';
        case KategoriEvidence.video:
          return 'Video';
        case KategoriEvidence.dokumen:
          return 'Dokumen';
        case KategoriEvidence.lainnya:
          return 'Lainnya';
      }
    }

    return PopupMenuButton<KategoriEvidence?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              _selectedKategoriFilter != null
                  ? Colors.purple.shade100
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 16,
              color:
                  _selectedKategoriFilter != null
                      ? Colors.purple.shade600
                      : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedKategoriFilter != null
                  ? getKategoriDisplayName(_selectedKategoriFilter!)
                  : 'Kategori',
              style: TextStyle(
                color:
                    _selectedKategoriFilter != null
                        ? Colors.purple.shade600
                        : Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            PopupMenuItem(value: null, child: Text('Semua Kategori')),
            ...KategoriEvidence.values.map(
              (kategori) => PopupMenuItem(
                value: kategori,
                child: Text(getKategoriDisplayName(kategori)),
              ),
            ),
          ],
      onSelected: (value) {
        setState(() => _selectedKategoriFilter = value);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada evidence',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload evidence pertama Anda',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showUploadEvidenceDialog(),
            icon: Icon(Icons.add_a_photo),
            label: Text('Upload Evidence'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence) {
    return GestureDetector(
      onTap: () => _showDetailDialog(evidence),
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File Preview
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  child:
                      evidence.isImage
                          ? Image.network(
                            evidence.fileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFileIcon(evidence);
                            },
                          )
                          : _buildFileIcon(evidence),
                ),
              ),
            ),

            // Info Section
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Category Row
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            evidence.statusDisplayName,
                            style: TextStyle(
                              color: evidence.statusColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: evidence.kategoriColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            evidence.kategoriDisplayName,
                            style: TextStyle(
                              color: evidence.kategoriColor,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),

                    // Location
                    Text(
                      evidence.lokasiName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),

                    // Date
                    Text(
                      evidence.formattedDate,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 10,
                      ),
                    ),

                    // Description if available
                    if (evidence.description != null &&
                        evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 4),
                      Text(
                        evidence.description!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(EvidenceModel evidence) {
    return Container(
      decoration: BoxDecoration(
        color: evidence.kategoriColor.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              evidence.kategoriIcon,
              size: 40,
              color: evidence.kategoriColor,
            ),
            SizedBox(height: 8),
            Text(
              evidence.kategoriDisplayName,
              style: TextStyle(
                color: evidence.kategoriColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<EvidenceModel> _filterEvidence(List<EvidenceModel> evidenceList) {
    return evidenceList.where((evidence) {
      final matchesSearch =
          evidence.lokasiName.toLowerCase().contains(_searchQuery) ||
          (evidence.description?.toLowerCase().contains(_searchQuery) ??
              false) ||
          evidence.kategoriDisplayName.toLowerCase().contains(_searchQuery);

      final matchesStatus =
          _selectedStatusFilter == null ||
          evidence.status == _selectedStatusFilter;
      final matchesKategori =
          _selectedKategoriFilter == null ||
          evidence.kategori == _selectedKategoriFilter;

      return matchesSearch && matchesStatus && matchesKategori;
    }).toList();
  }

  void _showUploadEvidenceDialog() {
    showDialog(
      context: context,
      builder:
          (context) => EvidenceUploadDialog(
            onUploaded: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Evidence berhasil diupload')),
              );
            },
          ),
    );
  }

  void _showDetailDialog(EvidenceModel evidence) {
    showDialog(
      context: context,
      builder: (context) => EvidenceDetailDialog(evidence: evidence),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Upload Dialog Widget
class EvidenceUploadDialog extends StatefulWidget {
  final VoidCallback onUploaded;

  const EvidenceUploadDialog({Key? key, required this.onUploaded})
    : super(key: key);

  @override
  _EvidenceUploadDialogState createState() => _EvidenceUploadDialogState();
}

class _EvidenceUploadDialogState extends State<EvidenceUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  KategoriEvidence _selectedKategori = KategoriEvidence.foto;
  File? _selectedFile;
  bool _isUploading = false;

  // --- PERUBAHAN DIMULAI DI SINI ---
  UserModel? _currentUser;
  bool _isLoadingUser = true; // State untuk loading data user

  @override
  void initState() {
    super.initState();
    _loadUserDataAndSetLocation();
  }

  /// Fungsi untuk mengambil data user dan mengatur lokasi jika user adalah koordinator
  Future<void> _loadUserDataAndSetLocation() async {
    final user = await UserService.getCurrentUser();

    // Jika user adalah koordinator dan memiliki locationId
    if (user != null &&
        user.role == UserRole.koordinator &&
        user.locationId != null &&
        user.locationId!.isNotEmpty) {
      // Ambil semua data lokasi untuk menemukan nama lokasi berdasarkan ID
      // .first akan mengambil snapshot data terbaru dari stream
      final locations = await LocationService.getAllLocations().first;
      try {
        final userLocation = locations.firstWhere(
          (loc) => loc.id == user.locationId,
        );
        setState(() {
          _selectedLokasiId = userLocation.id;
          _selectedLokasiName =
              '${userLocation.name} - ${userLocation.city}'; // Set nama lokasi untuk ditampilkan
        });
      } catch (e) {
        // Handle jika ID lokasi user tidak ditemukan di collection lokasi
        print('Error: Lokasi untuk koordinator tidak ditemukan: $e');
        setState(() {
          _selectedLokasiName = 'Lokasi tidak valid';
        });
      }
    }

    // Update state setelah selesai
    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }
  // --- PERUBAHAN SELESAI DI SINI ---

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload Evidence',
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
                      // --- PERUBAHAN PADA FIELD LOKASI ---
                      // Tampilkan loading, field read-only, atau dropdown berdasarkan status & role
                      _isLoadingUser
                          ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                          : (_currentUser?.role == UserRole.koordinator)
                          ? TextFormField(
                            initialValue: _selectedLokasiName,
                            readOnly: true, // Field tidak bisa diubah
                            decoration: InputDecoration(
                              labelText: 'Lokasi (Otomatis)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on_outlined),
                              filled: true,
                              fillColor:
                                  Colors
                                      .grey[200], // Warna abu-abu untuk menandakan non-aktif
                            ),
                            validator: (value) {
                              if (_selectedLokasiId.isEmpty) {
                                return 'Lokasi koordinator tidak terdaftar';
                              }
                              return null;
                            },
                          )
                          : StreamBuilder<List<LocationModel>>(
                            // Tampilkan dropdown untuk role lain (e.g. Admin)
                            stream: LocationService.getAllLocations(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              final locations = snapshot.data ?? [];
                              return DropdownButtonFormField<String>(
                                value:
                                    _selectedLokasiId.isEmpty
                                        ? null
                                        : _selectedLokasiId,
                                decoration: InputDecoration(
                                  labelText: 'Lokasi *',
                                  border: OutlineInputBorder(),
                                ),
                                items:
                                    locations.map((location) {
                                      return DropdownMenuItem(
                                        value: location.id,
                                        child: Text(
                                          '${location.name} - ${location.city}',
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    final selectedLocation = locations
                                        .firstWhere((loc) => loc.id == value);
                                    setState(() {
                                      _selectedLokasiId = value;
                                      _selectedLokasiName =
                                          selectedLocation.name;
                                    });
                                  }
                                },
                                validator:
                                    (value) =>
                                        value?.isEmpty ?? true
                                            ? 'Lokasi wajib dipilih'
                                            : null,
                              );
                            },
                          ),
                      // --- AKHIR PERUBAHAN PADA FIELD LOKASI ---
                      SizedBox(height: 16),

                      // Kategori
                      DropdownButtonFormField<KategoriEvidence>(
                        value: _selectedKategori,
                        decoration: InputDecoration(
                          labelText: 'Kategori Evidence *',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            KategoriEvidence.values.map((kategori) {
                              String displayName;
                              switch (kategori) {
                                case KategoriEvidence.foto:
                                  displayName = 'Foto';
                                  break;
                                case KategoriEvidence.video:
                                  displayName = 'Video';
                                  break;
                                case KategoriEvidence.dokumen:
                                  displayName = 'Dokumen';
                                  break;
                                case KategoriEvidence.lainnya:
                                  displayName = 'Lainnya';
                                  break;
                              }
                              return DropdownMenuItem(
                                value: kategori,
                                child: Text(displayName),
                              );
                            }).toList(),
                        onChanged:
                            (value) =>
                                setState(() => _selectedKategori = value!),
                      ),
                      SizedBox(height: 16),

                      // File Upload Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (_selectedFile == null) ...[
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Pilih file untuk diupload',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed:
                                        () =>
                                            _captureFromCamera(isVideo: false),
                                    icon: Icon(Icons.camera_alt, size: 20),
                                    label: Text('Foto'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _captureFromCamera(isVideo: true),
                                    icon: Icon(Icons.videocam, size: 20),
                                    label: Text('Video'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // File Preview
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    _selectedKategori == KategoriEvidence.foto
                                        ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _selectedFile!,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                        : Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                _selectedKategori ==
                                                        KategoriEvidence.video
                                                    ? Icons.videocam
                                                    : Icons.description,
                                                size: 32,
                                                color: Colors.grey.shade600,
                                              ),
                                              SizedBox(height: 8),
                                              Text(
                                                _selectedFile!.path
                                                    .split('/')
                                                    .last,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => setState(
                                          () => _selectedFile = null,
                                        ),
                                    icon: Icon(Icons.delete, size: 20),
                                    label: Text('Hapus'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed:
                                        () => _captureFromCamera(
                                          isVideo:
                                              _selectedKategori ==
                                              KategoriEvidence.video,
                                        ),
                                    icon: Icon(Icons.refresh, size: 20),
                                    label: Text('Ganti'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Tambahkan deskripsi untuk evidence ini...',
                        ),
                        maxLines: 3,
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
                      onPressed:
                          _isUploading || _selectedFile == null
                              ? null
                              : _uploadEvidence,
                      child:
                          _isUploading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text('Upload'),
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

  void _captureFromCamera({required bool isVideo}) async {
    try {
      if (isVideo) {
        final XFile? video = await _imagePicker.pickVideo(
          source: ImageSource.camera,
          maxDuration: Duration(minutes: 5),
        );

        if (video != null) {
          setState(() {
            _selectedFile = File(video.path);
            _selectedKategori = KategoriEvidence.video;
          });
        }
      } else {
        final XFile? image = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 80,
        );

        if (image != null) {
          setState(() {
            _selectedFile = File(image.path);
            _selectedKategori = KategoriEvidence.foto;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error mengambil file: $e')));
    }
  }

  void _uploadEvidence() async {
    if (!_formKey.currentState!.validate() || _selectedFile == null) return;

    // Validate file
    if (!EvidenceService.isValidFileType(_selectedFile!, _selectedKategori)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tipe file tidak sesuai dengan kategori yang dipilih'),
        ),
      );
      return;
    }

    if (!EvidenceService.isValidFileSize(_selectedFile!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ukuran file terlalu besar (max 50MB)')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserData = await UserService.getCurrentUser();

      if (currentUser == null || currentUserData == null) {
        throw Exception('User not found');
      }

      // Create temporary evidence ID for file upload
      final tempEvidenceId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload file
      final fileUrl = await EvidenceService.uploadFile(
        _selectedFile!,
        tempEvidenceId,
        _selectedKategori,
      );

      final evidence = EvidenceModel(
        evidenceId: '',
        uploadedBy: currentUser.uid,
        uploaderName: currentUserData.name,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        kategori: _selectedKategori,
        fileUrl: fileUrl,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await EvidenceService.createEvidence(evidence);
      widget.onUploaded();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    setState(() => _isUploading = false);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

// Detail Dialog Widget
class EvidenceDetailDialog extends StatelessWidget {
  final EvidenceModel evidence;

  const EvidenceDetailDialog({Key? key, required this.evidence})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: evidence.kategoriColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(evidence.kategoriIcon, color: evidence.kategoriColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Evidence',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          evidence.kategoriDisplayName,
                          style: TextStyle(
                            color: evidence.kategoriColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: evidence.statusColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      evidence.statusDisplayName,
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
                    // File Preview
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child:
                            evidence.isImage
                                ? Image.network(
                                  evidence.fileUrl,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(evidence.kategoriIcon, size: 48),
                                          SizedBox(height: 8),
                                          Text('Gagal memuat file'),
                                        ],
                                      ),
                                    );
                                  },
                                )
                                : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        evidence.kategoriIcon,
                                        size: 48,
                                        color: evidence.kategoriColor,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        evidence.kategoriDisplayName,
                                        style: TextStyle(
                                          color: evidence.kategoriColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Info Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Lokasi', evidence.lokasiName),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem(
                            'Uploader',
                            evidence.uploaderName,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Tanggal',
                            evidence.formattedDate,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem(
                            'Kategori',
                            evidence.kategoriDisplayName,
                          ),
                        ),
                      ],
                    ),

                    // Description
                    if (evidence.description != null &&
                        evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text(
                        'Deskripsi:',
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
                          evidence.description!,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],

                    // Rejection reason
                    if (evidence.status == StatusEvidence.rejected &&
                        evidence.rejectionReason != null) ...[
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
                                Icon(
                                  Icons.cancel,
                                  color: Colors.red.shade600,
                                  size: 20,
                                ),
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
                              evidence.rejectionReason!,
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
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ],
    );
  }
}
