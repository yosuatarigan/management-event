import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final isTablet = screenWidth > 600 && screenWidth <= 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Evidence',
          style: TextStyle(
            fontSize: isWeb ? 20 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        centerTitle: !isWeb,
        actions: [
          if (isWeb)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: ElevatedButton.icon(
                onPressed: () => _showUploadEvidenceDialog(),
                icon: Icon(Icons.add_a_photo, size: 18),
                label: Text('Upload Evidence'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            )
          else
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
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
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
                          borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isWeb ? 16 : 12,
                          vertical: isWeb ? 16 : 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.toLowerCase());
                      },
                    ),
                    SizedBox(height: isWeb ? 16 : 12),

                    // Filters
                    isWeb 
                      ? Row(
                          children: [
                            _buildStatusFilter(isWeb),
                            SizedBox(width: 16),
                            _buildKategoriFilter(isWeb),
                            Spacer(),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilter(isWeb),
                              SizedBox(width: 8),
                              _buildKategoriFilter(isWeb),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
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
                  return _buildEmptyState(isWeb);
                }

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                    child: _buildEvidenceGrid(evidenceList, isWeb, isTablet),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceGrid(List<EvidenceModel> evidenceList, bool isWeb, bool isTablet) {
    int crossAxisCount;
    double childAspectRatio;
    
    if (isWeb) {
      crossAxisCount = 4;
      childAspectRatio = 0.85;
    } else if (isTablet) {
      crossAxisCount = 3;
      childAspectRatio = 0.8;
    } else {
      crossAxisCount = 2;
      childAspectRatio = 0.8;
    }

    return GridView.builder(
      padding: EdgeInsets.all(isWeb ? 24 : 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: isWeb ? 20 : 12,
        mainAxisSpacing: isWeb ? 20 : 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: evidenceList.length,
      itemBuilder: (context, index) {
        return _buildEvidenceCard(evidenceList[index], isWeb);
      },
    );
  }

  Widget _buildStatusFilter(bool isWeb) {
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
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedStatusFilter != null
              ? getStatusColor(_selectedStatusFilter).withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: isWeb ? 18 : 16,
              color: _selectedStatusFilter != null
                  ? getStatusColor(_selectedStatusFilter)
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedStatusFilter?.toString().split('.').last ?? 'Status',
              style: TextStyle(
                color: _selectedStatusFilter != null
                    ? getStatusColor(_selectedStatusFilter)
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
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

  Widget _buildKategoriFilter(bool isWeb) {
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
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedKategoriFilter != null
              ? Colors.purple.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: isWeb ? 18 : 16,
              color: _selectedKategoriFilter != null
                  ? Colors.purple.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedKategoriFilter != null
                  ? getKategoriDisplayName(_selectedKategoriFilter!)
                  : 'Kategori',
              style: TextStyle(
                color: _selectedKategoriFilter != null
                    ? Colors.purple.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
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

  Widget _buildEmptyState(bool isWeb) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: isWeb ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            'Belum ada evidence',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Upload evidence pertama Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isWeb ? 16 : 14,
            ),
          ),
          SizedBox(height: isWeb ? 32 : 24),
          ElevatedButton.icon(
            onPressed: () => _showUploadEvidenceDialog(),
            icon: Icon(Icons.add_a_photo),
            label: Text('Upload Evidence'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 24 : 16,
                vertical: isWeb ? 16 : 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(EvidenceModel evidence, bool isWeb) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDetailDialog(evidence),
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        child: Card(
          elevation: isWeb ? 6 : 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // File Preview
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isWeb ? 16 : 12),
                    ),
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(isWeb ? 16 : 12),
                    ),
                    child: evidence.isImage
                        ? Image.network(
                            evidence.fileUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildFileIcon(evidence, isWeb);
                            },
                          )
                        : _buildFileIcon(evidence, isWeb),
                  ),
                ),
              ),

              // Info Section
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(isWeb ? 12 : 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status and Category Row
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 8 : 6,
                              vertical: isWeb ? 4 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: evidence.statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              evidence.statusDisplayName,
                              style: TextStyle(
                                color: evidence.statusColor,
                                fontSize: isWeb ? 10 : 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 8 : 6,
                              vertical: isWeb ? 4 : 2,
                            ),
                            decoration: BoxDecoration(
                              color: evidence.kategoriColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              evidence.kategoriDisplayName,
                              style: TextStyle(
                                color: evidence.kategoriColor,
                                fontSize: isWeb ? 10 : 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isWeb ? 8 : 6),

                      // Location
                      Text(
                        evidence.lokasiName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isWeb ? 14 : 12,
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
                          fontSize: isWeb ? 12 : 10,
                        ),
                      ),

                      // Description if available
                      if (evidence.description != null &&
                          evidence.description!.isNotEmpty) ...[
                        SizedBox(height: 4),
                        Expanded(
                          child: Text(
                            evidence.description!,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isWeb ? 12 : 10,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(EvidenceModel evidence, bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        color: evidence.kategoriColor.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(isWeb ? 16 : 12)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              evidence.kategoriIcon,
              size: isWeb ? 48 : 40,
              color: evidence.kategoriColor,
            ),
            SizedBox(height: 8),
            Text(
              evidence.kategoriDisplayName,
              style: TextStyle(
                color: evidence.kategoriColor,
                fontSize: isWeb ? 14 : 12,
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
          (evidence.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          evidence.kategoriDisplayName.toLowerCase().contains(_searchQuery);

      final matchesStatus = _selectedStatusFilter == null ||
          evidence.status == _selectedStatusFilter;
      final matchesKategori = _selectedKategoriFilter == null ||
          evidence.kategori == _selectedKategoriFilter;

      return matchesSearch && matchesStatus && matchesKategori;
    }).toList();
  }

  void _showUploadEvidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => EvidenceUploadDialog(
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

// Simple Upload Dialog
class EvidenceUploadDialog extends StatefulWidget {
  final VoidCallback onUploaded;

  const EvidenceUploadDialog({Key? key, required this.onUploaded}) : super(key: key);

  @override
  _EvidenceUploadDialogState createState() => _EvidenceUploadDialogState();
}

class _EvidenceUploadDialogState extends State<EvidenceUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  KategoriEvidence _selectedKategori = KategoriEvidence.foto;
  
  File? _selectedFile;
  Uint8List? _webImage;
  bool _isUploading = false;

  UserModel? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndSetLocation();
  }

  Future<void> _loadUserDataAndSetLocation() async {
    final user = await UserService.getCurrentUser();

    if (user != null &&
        user.role == UserRole.koordinator &&
        user.locationId != null &&
        user.locationId!.isNotEmpty) {
      final locations = await LocationService.getAllLocations().first;
      try {
        final userLocation = locations.firstWhere(
          (loc) => loc.id == user.locationId,
        );
        setState(() {
          _selectedLokasiId = userLocation.id;
          _selectedLokasiName = '${userLocation.name} - ${userLocation.city}';
        });
      } catch (e) {
        print('Error: Lokasi untuk koordinator tidak ditemukan: $e');
        setState(() {
          _selectedLokasiName = 'Lokasi tidak valid';
        });
      }
    }

    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }

  // Simple image picker like your example
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final webImage = await pickedFile.readAsBytes();
        setState(() {
          _webImage = webImage;
          _selectedFile = null;
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<void> _captureImage() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera tidak tersedia di web')),
      );
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  // Simple upload like your example
  Future<String> uploadImage(File? image, Uint8List? webimage) async {
    String docnya = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('evidence').child(docnya);

    if (webimage == null) {
      await ref.putFile(image!);
    } else {
      await ref.putData(webimage);
    }

    return await ref.getDownloadURL();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
      child: Container(
        width: isWeb ? 500.0 : screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.upload_file, color: Colors.green, size: isWeb ? 24 : 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload Evidence',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, size: isWeb ? 24 : 20),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Lokasi
                      _isLoadingUser
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : (_currentUser?.role == UserRole.koordinator)
                              ? TextFormField(
                                  initialValue: _selectedLokasiName,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Lokasi (Otomatis)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(Icons.location_on_outlined),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                )
                              : StreamBuilder<List<LocationModel>>(
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
                                      value: _selectedLokasiId.isEmpty
                                          ? null
                                          : _selectedLokasiId,
                                      decoration: InputDecoration(
                                        labelText: 'Lokasi *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      items: locations.map((location) {
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
                                            _selectedLokasiName = selectedLocation.name;
                                          });
                                        }
                                      },
                                      validator: (value) => value?.isEmpty ?? true
                                          ? 'Lokasi wajib dipilih'
                                          : null,
                                    );
                                  },
                                ),
                      SizedBox(height: isWeb ? 20 : 16),

                      // Kategori
                      DropdownButtonFormField<KategoriEvidence>(
                        value: _selectedKategori,
                        decoration: InputDecoration(
                          labelText: 'Kategori Evidence *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: KategoriEvidence.values.map((kategori) {
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
                        onChanged: (value) => setState(() => _selectedKategori = value!),
                      ),
                      SizedBox(height: isWeb ? 20 : 16),

                      // File Upload Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isWeb ? 20 : 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_selectedFile == null && _webImage == null) ...[
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: isWeb ? 56 : 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Pilih gambar untuk diupload',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  fontSize: isWeb ? 16 : 14,
                                ),
                              ),
                              SizedBox(height: isWeb ? 20 : 16),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                alignment: WrapAlignment.center,
                                children: [
                                  if (!kIsWeb)
                                    ElevatedButton.icon(
                                      onPressed: _captureImage,
                                      icon: Icon(Icons.camera_alt, size: 20),
                                      label: Text('Kamera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
                                    icon: Icon(Icons.photo_library, size: 20),
                                    label: Text(kIsWeb ? 'Pilih File' : 'Galeri'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              // Image Preview
                              Container(
                                height: isWeb ? 150 : 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _webImage != null
                                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                                      : Image.file(_selectedFile!, fit: BoxFit.cover),
                                ),
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() {
                                      _selectedFile = null;
                                      _webImage = null;
                                    }),
                                    icon: Icon(Icons.delete, size: 20),
                                    label: Text('Hapus'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _pickImage,
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
                      SizedBox(height: isWeb ? 20 : 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading || (_selectedFile == null && _webImage == null) 
                          ? null 
                          : _uploadEvidence,
                      child: _isUploading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 12),
                      ),
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

  Future<void> _uploadEvidence() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFile == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih file terlebih dahulu')),
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

      // Simple upload using your pattern
      final fileUrl = await uploadImage(_selectedFile, _webImage);

      final evidence = EvidenceModel( 
        projectId: '',
        evidenceId: '',
        uploadedBy: currentUser.uid,
        uploaderName: currentUserData.name,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        kategori: _selectedKategori,
        fileUrl: fileUrl,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await EvidenceService.createEvidence(evidence);
      widget.onUploaded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}

// Detail Dialog - Simple version
class EvidenceDetailDialog extends StatelessWidget {
  final EvidenceModel evidence;

  const EvidenceDetailDialog({Key? key, required this.evidence}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
      child: Container(
        width: isWeb ? 600.0 : screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: evidence.kategoriColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(evidence.kategoriIcon, color: evidence.kategoriColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Evidence',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                padding: EdgeInsets.all(isWeb ? 24 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // File Preview
                    Container(
                      width: double.infinity,
                      height: isWeb ? 250 : 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: evidence.isImage
                            ? Image.network(
                                evidence.fileUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(child: Icon(Icons.error)),
                              )
                            : Center(
                                child: Icon(
                                  evidence.kategoriIcon,
                                  size: 56,
                                  color: evidence.kategoriColor,
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Info
                    Text('Lokasi: ${evidence.lokasiName}',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Uploader: ${evidence.uploaderName}',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Tanggal: ${evidence.formattedDate}',
                        style: TextStyle(fontSize: 16)),
                    SizedBox(height: 8),
                    Text('Kategori: ${evidence.kategoriDisplayName}',
                        style: TextStyle(fontSize: 16)),

                    // Description
                    if (evidence.description != null &&
                        evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text('Deskripsi:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Text(evidence.description!, style: TextStyle(fontSize: 16)),
                    ],

                    // Rejection reason
                    if (evidence.status == StatusEvidence.rejected &&
                        evidence.rejectionReason != null) ...[
                      SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Alasan Penolakan:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red.shade700,
                              ),
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

            // Close Button
            Padding(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Tutup'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}