import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:management_event/user_model.dart';
import 'evidence_service.dart';
import 'evidence_model.dart';
import 'evidence_categories.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';
import 'session_manager.dart';

class EvidencePage extends StatefulWidget {
  @override
  _EvidencePageState createState() => _EvidencePageState();
}

class _EvidencePageState extends State<EvidencePage> {
  final _searchController = TextEditingController();
  StatusEvidence? _selectedStatusFilter;
  KategoriEvidence? _selectedKategoriFilter;
  String? _selectedJenisFilter;
  String? _selectedSubJenisFilter;
  String _searchQuery = '';
  String? _currentProjectId;
  bool _isLoadingProject = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentProject();
  }

  Future<void> _loadCurrentProject() async {
    try {
      _currentProjectId = await SessionManager.getCurrentProject();
    } catch (e) {
      print('Error loading current project: $e');
    }
    setState(() => _isLoadingProject = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final isTablet = screenWidth > 600 && screenWidth <= 768;

    if (_isLoadingProject) {
      return Scaffold(
        appBar: AppBar(title: Text('Evidence')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentProjectId == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Evidence')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                'Tidak ada proyek aktif',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'Silakan pilih proyek terlebih dahulu',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

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
                      ? Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildStatusFilter(isWeb),
                            _buildKategoriFilter(isWeb),
                            _buildJenisFilter(isWeb),
                            _buildSubJenisFilter(isWeb),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildStatusFilter(isWeb),
                              SizedBox(width: 8),
                              _buildKategoriFilter(isWeb),
                              SizedBox(width: 8),
                              _buildJenisFilter(isWeb),
                              SizedBox(width: 8),
                              _buildSubJenisFilter(isWeb),
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
              stream: EvidenceService.getEvidenceByProject(_currentProjectId!),
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
        setState(() {
          _selectedKategoriFilter = value;
          _selectedJenisFilter = null;
          _selectedSubJenisFilter = null;
        });
      },
    );
  }

  Widget _buildJenisFilter(bool isWeb) {
    if (_selectedKategoriFilter == null) return SizedBox.shrink();
    
    final kategoriKey = _selectedKategoriFilter.toString().split('.').last;
    if (!EvidenceCategories.hasJenisSubJenis(kategoriKey)) {
      return SizedBox.shrink();
    }

    final jenisList = EvidenceCategories.getJenisByKategori(kategoriKey);
    if (jenisList.isEmpty) return SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedJenisFilter != null
              ? Colors.teal.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.list_alt,
              size: isWeb ? 18 : 16,
              color: _selectedJenisFilter != null
                  ? Colors.teal.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedJenisFilter ?? 'Jenis',
              style: TextStyle(
                color: _selectedJenisFilter != null
                    ? Colors.teal.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Jenis')),
        ...jenisList.map(
          (jenis) => PopupMenuItem(
            value: jenis,
            child: Text(jenis),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() {
          _selectedJenisFilter = value;
          _selectedSubJenisFilter = null;
        });
      },
    );
  }

  Widget _buildSubJenisFilter(bool isWeb) {
    if (_selectedKategoriFilter == null || _selectedJenisFilter == null) {
      return SizedBox.shrink();
    }

    final kategoriKey = _selectedKategoriFilter.toString().split('.').last;
    final subJenisList = EvidenceCategories.getSubJenisByJenis(
      kategoriKey, 
      _selectedJenisFilter!,
    );
    
    if (subJenisList.isEmpty) return SizedBox.shrink();

    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedSubJenisFilter != null
              ? Colors.indigo.shade100
              : Colors.white,
          borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subdirectory_arrow_right,
              size: isWeb ? 18 : 16,
              color: _selectedSubJenisFilter != null
                  ? Colors.indigo.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedSubJenisFilter ?? 'Sub Jenis',
              style: TextStyle(
                color: _selectedSubJenisFilter != null
                    ? Colors.indigo.shade600
                    : Colors.grey.shade600,
                fontSize: isWeb ? 14 : 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Icon(Icons.arrow_drop_down, size: isWeb ? 20 : 16),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(value: null, child: Text('Semua Sub Jenis')),
        ...subJenisList.map(
          (subJenis) => PopupMenuItem(
            value: subJenis,
            child: Text(subJenis),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() => _selectedSubJenisFilter = value);
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
            'Upload evidence pertama untuk proyek ini',
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
                    child: _buildFilePreview(evidence, isWeb),
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
                      
                      // Jenis & Sub Jenis
                      if (evidence.jenis != null) ...[
                        SizedBox(height: 4),
                        Text(
                          evidence.jenisSubJenisDisplay,
                          style: TextStyle(
                            fontSize: isWeb ? 11 : 10,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildFilePreview(EvidenceModel evidence, bool isWeb) {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return Image.network(
          evidence.fileUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFileIcon(evidence, isWeb);
          },
        );
      
      case KategoriEvidence.video:
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: evidence.kategoriColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(isWeb ? 16 : 12)),
              ),
              child: Center(
                child: Icon(
                  Icons.videocam,
                  size: isWeb ? 48 : 40,
                  color: evidence.kategoriColor,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.play_arrow,
                color: Colors.white,
                size: isWeb ? 24 : 20,
              ),
            ),
          ],
        );
      
      default:
        return _buildFileIcon(evidence, isWeb);
    }
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
          (evidence.jenis?.toLowerCase().contains(_searchQuery) ?? false) ||
          (evidence.subJenis?.toLowerCase().contains(_searchQuery) ?? false) ||
          evidence.kategoriDisplayName.toLowerCase().contains(_searchQuery);

      final matchesStatus = _selectedStatusFilter == null ||
          evidence.status == _selectedStatusFilter;
      final matchesKategori = _selectedKategoriFilter == null ||
          evidence.kategori == _selectedKategoriFilter;
      final matchesJenis = _selectedJenisFilter == null ||
          evidence.jenis == _selectedJenisFilter;
      final matchesSubJenis = _selectedSubJenisFilter == null ||
          evidence.subJenis == _selectedSubJenisFilter;

      return matchesSearch && matchesStatus && matchesKategori && 
             matchesJenis && matchesSubJenis;
    }).toList();
  }

  void _showUploadEvidenceDialog() {
    showDialog(
      context: context,
      builder: (context) => EvidenceUploadDialog(
        projectId: _currentProjectId!,
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

// Upload Dialog dengan Jenis & Sub Jenis
class EvidenceUploadDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onUploaded;

  const EvidenceUploadDialog({
    Key? key, 
    required this.projectId,
    required this.onUploaded,
  }) : super(key: key);

  @override
  _EvidenceUploadDialogState createState() => _EvidenceUploadDialogState();
}

class _EvidenceUploadDialogState extends State<EvidenceUploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  KategoriEvidence _selectedKategori = KategoriEvidence.foto;
  String? _selectedJenis;
  String? _selectedSubJenis;
  
  File? _selectedFile;
  Uint8List? _webFile;
  String? _fileName;
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

    if (user != null && user.locationId != null && user.locationId!.isNotEmpty) {
      try {
        final currentProjectLocations = await LocationService.getLocationsByProject(widget.projectId).first;
        final userLocation = currentProjectLocations.where((loc) => loc.id == user.locationId).firstOrNull;
        
        if (userLocation != null) {
          setState(() {
            _selectedLokasiId = userLocation.id;
            _selectedLokasiName = '${userLocation.name} - ${userLocation.city}';
          });
        } else {
          print('User location not found in current project');
        }
      } catch (e) {
        print('Error finding user location: $e');
      }
    }

    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final webImage = await pickedFile.readAsBytes();
        setState(() {
          _webFile = webImage;
          _selectedFile = null;
          _fileName = pickedFile.name;
        });
      }
    } else {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _webFile = null;
          _fileName = pickedFile.name;
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
          _webFile = null;
          _fileName = pickedFile.name;
        });
      }
    }
  }

  Future<void> _pickVideo() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      if (result != null && result.files.single.bytes != null) {
        setState(() {
          _webFile = result.files.single.bytes!;
          _selectedFile = null;
          _fileName = result.files.single.name;
        });
      }
    } else {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _webFile = null;
          _fileName = pickedFile.name;
        });
      }
    }
  }

  Future<void> _captureVideo() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera tidak tersedia di web')),
      );
    } else {
      final pickedFile = await picker.pickVideo(source: ImageSource.camera);
      if (pickedFile != null) {
        setState(() {
          _selectedFile = File(pickedFile.path);
          _webFile = null;
          _fileName = pickedFile.name;
        });
      }
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'],
      allowMultiple: false,
    );
    
    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _webFile = result.files.single.bytes!;
          _selectedFile = null;
          _fileName = result.files.single.name;
        });
      } else {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _webFile = null;
          _fileName = result.files.single.name;
        });
      }
    }
  }

  Future<String> _uploadFile() async {
    String docnya = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref()
        .child('evidence')
        .child(widget.projectId)
        .child(_selectedKategori.toString().split('.').last)
        .child(docnya);

    if (_webFile == null) {
      await ref.putFile(_selectedFile!);
    } else {
      await ref.putData(_webFile!);
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
                gradient: LinearGradient(
                  colors: [Colors.green.shade50, Colors.green.shade100],
                ),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.upload_file, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Upload Evidence',
                      style: TextStyle(
                        fontSize: isWeb ? 20 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
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
                          : (_currentUser?.role == UserRole.koordinator && _selectedLokasiId.isNotEmpty)
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
                                  stream: LocationService.getLocationsByProject(widget.projectId),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Center(child: CircularProgressIndicator());
                                    }
                                    final locations = snapshot.data ?? [];
                                    
                                    if (locations.isEmpty) {
                                      return Container(
                                        padding: EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange.shade200),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.warning_amber, color: Colors.orange.shade600),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Belum ada lokasi di proyek ini.',
                                                style: TextStyle(color: Colors.orange.shade600),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    
                                    return DropdownButtonFormField<String>(
                                      value: _selectedLokasiId.isEmpty ? null : _selectedLokasiId,
                                      decoration: InputDecoration(
                                        labelText: 'Lokasi *',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        prefixIcon: Icon(Icons.location_on_outlined),
                                      ),
                                      items: locations.map((location) {
                                        return DropdownMenuItem(
                                          value: location.id,
                                          child: Text('${location.name} - ${location.city}'),
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
                          labelText: 'Kategori *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(_getKategoriIcon(_selectedKategori)),
                        ),
                        items: KategoriEvidence.values.map((kategori) {
                          return DropdownMenuItem(
                            value: kategori,
                            child: Row(
                              children: [
                                Icon(_getKategoriIcon(kategori), size: 20),
                                SizedBox(width: 8),
                                Text(_getKategoriDisplayName(kategori)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedKategori = value!;
                            _selectedJenis = null;
                            _selectedSubJenis = null;
                            _selectedFile = null;
                            _webFile = null;
                            _fileName = null;
                          });
                        },
                      ),
                      SizedBox(height: isWeb ? 20 : 16),

                      // Jenis (hanya untuk Foto & Video)
                      if (EvidenceCategories.hasJenisSubJenis(
                        _selectedKategori.toString().split('.').last,
                      )) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedJenis,
                          decoration: InputDecoration(
                            labelText: 'Jenis *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.list_alt),
                          ),
                          items: EvidenceCategories.getJenisByKategori(
                            _selectedKategori.toString().split('.').last,
                          ).map((jenis) {
                            return DropdownMenuItem(
                              value: jenis,
                              child: Text(jenis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedJenis = value;
                              _selectedSubJenis = null;
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Jenis wajib dipilih'
                              : null,
                        ),
                        SizedBox(height: isWeb ? 20 : 16),
                      ],

                      // Sub Jenis (cascade dari Jenis)
                      if (_selectedJenis != null) ...[
                        DropdownButtonFormField<String>(
                          value: _selectedSubJenis,
                          decoration: InputDecoration(
                            labelText: 'Sub Jenis *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          ),
                          items: EvidenceCategories.getSubJenisByJenis(
                            _selectedKategori.toString().split('.').last,
                            _selectedJenis!,
                          ).map((subJenis) {
                            return DropdownMenuItem(
                              value: subJenis,
                              child: Text(subJenis),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSubJenis = value);
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Sub Jenis wajib dipilih'
                              : null,
                        ),
                        SizedBox(height: isWeb ? 20 : 16),
                      ],

                      // File Upload Section
                      _buildFileUploadSection(isWeb),
                      SizedBox(height: isWeb ? 20 : 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Tambahkan deskripsi...',
                          prefixIcon: Icon(Icons.description),
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
                      onPressed: _isUploading || (_selectedFile == null && _webFile == null) 
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
                        backgroundColor: Colors.green.shade600,
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

  Widget _buildFileUploadSection(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isWeb ? 20 : 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (_selectedFile == null && _webFile == null) ...[
            Icon(
              _getKategoriIcon(_selectedKategori),
              size: isWeb ? 56 : 48,
              color: _getKategoriColor(_selectedKategori),
            ),
            SizedBox(height: 12),
            Text(
              'Pilih ${_getKategoriDisplayName(_selectedKategori)}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
            SizedBox(height: isWeb ? 20 : 16),
            _buildUploadButtons(isWeb),
          ] else ...[
            Container(
              height: isWeb ? 150 : 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildFilePreview(isWeb),
              ),
            ),
            SizedBox(height: 12),
            Text(
              _fileName ?? 'Unknown file',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: isWeb ? 14 : 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() {
                    _selectedFile = null;
                    _webFile = null;
                    _fileName = null;
                  }),
                  icon: Icon(Icons.delete, size: 20),
                  label: Text('Hapus'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _handleFileSelection(),
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
    );
  }

  Widget _buildUploadButtons(bool isWeb) {
    switch (_selectedKategori) {
      case KategoriEvidence.foto:
        return Wrap(
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
              label: Text(kIsWeb ? 'Pilih Foto' : 'Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      
      case KategoriEvidence.video:
        return Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (!kIsWeb)
              ElevatedButton.icon(
                onPressed: _captureVideo,
                icon: Icon(Icons.videocam, size: 20),
                label: Text('Rekam Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ElevatedButton.icon(
              onPressed: _pickVideo,
              icon: Icon(Icons.video_library, size: 20),
              label: Text(kIsWeb ? 'Pilih Video' : 'Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      
      case KategoriEvidence.dokumen:
        return ElevatedButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.description, size: 20),
          label: Text('Pilih Dokumen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            foregroundColor: Colors.white,
          ),
        );
      
      default:
        return ElevatedButton.icon(
          onPressed: _pickDocument,
          icon: Icon(Icons.folder, size: 20),
          label: Text('Pilih File'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey,
            foregroundColor: Colors.white,
          ),
        );
    }
  }

  Widget _buildFilePreview(bool isWeb) {
    if (_selectedKategori == KategoriEvidence.foto && 
        (_webFile != null || _selectedFile != null)) {
      return _webFile != null
          ? Image.memory(_webFile!, fit: BoxFit.cover)
          : Image.file(_selectedFile!, fit: BoxFit.cover);
    }
    
    return Container(
      color: _getKategoriColor(_selectedKategori).withOpacity(0.1),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getKategoriIcon(_selectedKategori),
              size: isWeb ? 48 : 40,
              color: _getKategoriColor(_selectedKategori),
            ),
            SizedBox(height: 8),
            Text(
              _getKategoriDisplayName(_selectedKategori),
              style: TextStyle(
                color: _getKategoriColor(_selectedKategori),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFileSelection() {
    switch (_selectedKategori) {
      case KategoriEvidence.foto:
        _pickImage();
        break;
      case KategoriEvidence.video:
        _pickVideo();
        break;
      case KategoriEvidence.dokumen:
      case KategoriEvidence.lainnya:
        _pickDocument();
        break;
    }
  }

  String _getKategoriDisplayName(KategoriEvidence kategori) {
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

  IconData _getKategoriIcon(KategoriEvidence kategori) {
    switch (kategori) {
      case KategoriEvidence.foto:
        return Icons.photo;
      case KategoriEvidence.video:
        return Icons.videocam;
      case KategoriEvidence.dokumen:
        return Icons.description;
      case KategoriEvidence.lainnya:
        return Icons.folder;
    }
  }

  Color _getKategoriColor(KategoriEvidence kategori) {
    switch (kategori) {
      case KategoriEvidence.foto:
        return Colors.blue;
      case KategoriEvidence.video:
        return Colors.red;
      case KategoriEvidence.dokumen:
        return Colors.green;
      case KategoriEvidence.lainnya:
        return Colors.grey;
    }
  }

  Future<void> _uploadEvidence() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedFile == null && _webFile == null) {
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

      final fileUrl = await _uploadFile();

      final evidence = EvidenceModel( 
        projectId: widget.projectId,
        evidenceId: '',
        uploadedBy: currentUser.uid,
        uploaderName: currentUserData.name,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        kategori: _selectedKategori,
        jenis: _selectedJenis,
        subJenis: _selectedSubJenis,
        fileUrl: fileUrl,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      await EvidenceService.createEvidenceForProject(widget.projectId, evidence);
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

// Detail Dialog dengan Jenis & Sub Jenis
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
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: evidence.kategoriColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(evidence.kategoriIcon, color: Colors.white),
                  ),
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
                        child: _buildFileDisplay(isWeb),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openFile(),
                            icon: Icon(_getActionIcon()),
                            label: Text(_getActionText()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: evidence.kategoriColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        if (evidence.kategori != KategoriEvidence.foto) ...[
                          SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _downloadFile(),
                            icon: Icon(Icons.download),
                            label: Text('Download'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade600,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 20),

                    // Info
                    _buildInfoRow('Lokasi', evidence.lokasiName, Icons.location_on),
                    _buildInfoRow('Uploader', evidence.uploaderName, Icons.person),
                    _buildInfoRow('Tanggal', evidence.formattedDate, Icons.calendar_today),
                    _buildInfoRow('Kategori', evidence.kategoriDisplayName, Icons.category),
                    
                    // Jenis & Sub Jenis
                    if (evidence.jenis != null) ...[
                      _buildInfoRow('Jenis', evidence.jenis!, Icons.list_alt),
                    ],
                    if (evidence.subJenis != null) ...[
                      _buildInfoRow('Sub Jenis', evidence.subJenis!, Icons.subdirectory_arrow_right),
                    ],

                    // Description
                    if (evidence.description != null && evidence.description!.isNotEmpty) ...[
                      SizedBox(height: 20),
                      Text('Deskripsi:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(evidence.description!, style: TextStyle(fontSize: 16)),
                      ),
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
                            Row(
                              children: [
                                Icon(Icons.error, color: Colors.red.shade700, size: 20),
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

  Widget _buildFileDisplay(bool isWeb) {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return Image.network(
          evidence.fileUrl,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              Center(child: Icon(Icons.error)),
        );
      
      default:
        return Container(
          color: evidence.kategoriColor.withOpacity(0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  evidence.kategoriIcon,
                  size: isWeb ? 64 : 48,
                  color: evidence.kategoriColor,
                ),
                SizedBox(height: 12),
                Text(
                  evidence.kategoriDisplayName,
                  style: TextStyle(
                    fontSize: isWeb ? 18 : 16,
                    fontWeight: FontWeight.w500,
                    color: evidence.kategoriColor,
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  IconData _getActionIcon() {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return Icons.zoom_in;
      case KategoriEvidence.video:
        return Icons.play_arrow;
      default:
        return Icons.open_in_new;
    }
  }

  String _getActionText() {
    switch (evidence.kategori) {
      case KategoriEvidence.foto:
        return 'Lihat Full';
      case KategoriEvidence.video:
        return 'Putar Video';
      default:
        return 'Buka File';
    }
  }

  Future<void> _openFile() async {
    try {
      final Uri uri = Uri.parse(evidence.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch ${evidence.fileUrl}';
      }
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  Future<void> _downloadFile() async {
    try {
      final Uri uri = Uri.parse(evidence.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not download ${evidence.fileUrl}';
      }
    } catch (e) {
      print('Error downloading file: $e');
    }
  }
}