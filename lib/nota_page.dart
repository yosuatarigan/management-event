import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'nota_service.dart';
import 'nota_model.dart';
import 'nota_categories.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';
import 'session_manager.dart';

class NotaPage extends StatefulWidget {
  @override
  _NotaPageState createState() => _NotaPageState();
}

class _NotaPageState extends State<NotaPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedJenisFilter;

  @override
  Widget build(BuildContext context) {
    final currentProjectId = SessionManager.currentProjectId;
    
    if (currentProjectId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Nota Pengeluaran'),
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.folder_off, size: 64, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text(
                'Tidak ada proyek yang dipilih',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pilih proyek terlebih dahulu',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Nota Pengeluaran',
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
                onPressed: () => _showAddNotaDialog(currentProjectId),
                icon: Icon(Icons.add, size: 18),
                label: Text('Tambah Nota'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            )
          else
            IconButton(
              onPressed: () => _showAddNotaDialog(currentProjectId),
              icon: Icon(Icons.add),
              tooltip: 'Tambah Nota',
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Section
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(isWeb ? 24 : 16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari nota...',
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

                    // Jenis Filter
                    _buildJenisFilter(isWeb),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 1200 : double.infinity),
                child: Column(
                  children: [
                    // Total Amount Summary
                    StreamBuilder<List<NotaModel>>(
                      stream: NotaService.getCurrentUserNotaByProject(currentProjectId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final notaList = snapshot.data!;
                          final totalAmount = notaList.fold<double>(0, (sum, n) => sum + n.nominal);

                          return Container(
                            margin: EdgeInsets.all(isWeb ? 24 : 16),
                            padding: EdgeInsets.all(isWeb ? 20 : 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  blurRadius: isWeb ? 8 : 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: isWeb 
                              ? Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long, 
                                        color: Colors.orange, 
                                        size: 28,
                                      ),
                                    ),
                                    SizedBox(width: 20),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Pengeluaran',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(
                                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                              (Match match) => '${match[1]}.',
                                            )}',
                                            style: TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${notaList.length} Nota',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.receipt_long, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text(
                                          'Total Pengeluaran',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(
                                        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                        (Match match) => '${match[1]}.',
                                      )}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade700,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      '${notaList.length} Nota',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }
                        return SizedBox.shrink();
                      },
                    ),

                    // List
                    Expanded(
                      child: StreamBuilder<List<NotaModel>>(
                        stream: NotaService.getCurrentUserNotaByProject(currentProjectId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.receipt_long_outlined,
                                    size: isWeb ? 80 : 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Belum ada nota',
                                    style: TextStyle(
                                      fontSize: isWeb ? 18 : 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tambahkan nota pengeluaran baru',
                                    style: TextStyle(color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            );
                          }

                          var notaList = snapshot.data!;

                          // Apply search filter
                          if (_searchQuery.isNotEmpty) {
                            notaList = notaList.where((nota) {
                              return nota.jenis.toLowerCase().contains(_searchQuery) ||
                                     nota.keperluan.toLowerCase().contains(_searchQuery) ||
                                     nota.lokasiName.toLowerCase().contains(_searchQuery) ||
                                     nota.formattedNominal.toLowerCase().contains(_searchQuery);
                            }).toList();
                          }

                          // Apply jenis filter
                          if (_selectedJenisFilter != null && _selectedJenisFilter != 'Semua') {
                            notaList = notaList.where((nota) => nota.jenis == _selectedJenisFilter).toList();
                          }

                          if (notaList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
                                  SizedBox(height: 16),
                                  Text(
                                    'Tidak ada hasil',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: EdgeInsets.symmetric(
                              horizontal: isWeb ? 24 : 16,
                              vertical: isWeb ? 12 : 8,
                            ),
                            itemCount: notaList.length,
                            itemBuilder: (context, index) {
                              final nota = notaList[index];
                              return _buildNotaCard(nota, isWeb);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJenisFilter(bool isWeb) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('Semua', isWeb),
          ...NotaCategories.jenisNota.map(
            (jenis) => _buildFilterChip(jenis, isWeb),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isWeb) {
    final isSelected = _selectedJenisFilter == label || (_selectedJenisFilter == null && label == 'Semua');
    final jenisStyle = label != 'Semua' ? NotaCategories.getJenisStyle(label) : {'color': Colors.grey, 'icon': Icons.all_inclusive};

    return Padding(
      padding: EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(jenisStyle['icon'], size: 16, color: isSelected ? Colors.white : jenisStyle['color']),
            SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: isWeb ? 14 : 13)),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedJenisFilter = selected ? (label == 'Semua' ? null : label) : null;
          });
        },
        selectedColor: jenisStyle['color'],
        backgroundColor: Colors.white,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : jenisStyle['color'],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? jenisStyle['color'] : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildNotaCard(NotaModel nota, bool isWeb) {
    final jenisStyle = NotaCategories.getJenisStyle(nota.jenis);
    
    return Card(
      margin: EdgeInsets.only(bottom: isWeb ? 12 : 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 16 : 12)),
      child: InkWell(
        onTap: () => _showDetailDialog(nota),
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 16 : 12),
          child: Row(
            children: [
              Container(
                width: isWeb ? 70 : 60,
                height: isWeb ? 70 : 60,
                decoration: BoxDecoration(
                  color: jenisStyle['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  jenisStyle['icon'],
                  color: jenisStyle['color'],
                  size: isWeb ? 30 : 26,
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nota.jenis,
                      style: TextStyle(
                        fontSize: isWeb ? 16 : 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      nota.keperluan,
                      style: TextStyle(
                        fontSize: isWeb ? 14 : 13,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Text(
                          nota.lokasiName,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                        SizedBox(width: 4),
                        Text(
                          nota.formattedTanggal,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: nota.tipeKoordinator == TipeKoordinator.koordinatorIT 
                            ? Colors.blue.shade50 
                            : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        nota.tipeKoordinatorDisplayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: nota.tipeKoordinator == TipeKoordinator.koordinatorIT 
                              ? Colors.blue.shade700 
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    nota.formattedNominal,
                    style: TextStyle(
                      fontSize: isWeb ? 16 : 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: nota.statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(nota.statusIcon, size: 14, color: nota.statusColor),
                        SizedBox(width: 4),
                        Text(
                          nota.statusDisplayName,
                          style: TextStyle(
                            fontSize: 12,
                            color: nota.statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddNotaDialog(String projectId) {
    showDialog(
      context: context,
      builder: (context) => AddNotaDialog(
        projectId: projectId,
        onAdded: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nota berhasil ditambahkan')),
          );
        },
      ),
    );
  }

  void _showDetailDialog(NotaModel nota) {
    showDialog(
      context: context,
      builder: (context) => NotaDetailDialog(nota: nota),
    );
  }
}

// Add Nota Dialog
class AddNotaDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onAdded;

  const AddNotaDialog({
    Key? key,
    required this.projectId,
    required this.onAdded,
  }) : super(key: key);

  @override
  _AddNotaDialogState createState() => _AddNotaDialogState();
}

class _AddNotaDialogState extends State<AddNotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keperluanController = TextEditingController();
  final _nominalController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  String _lokasiFullAddress = '';
  String _selectedJenis = 'Lain-lain';
  TipeKoordinator _selectedTipeKoordinator = TipeKoordinator.koordinator;
  DateTime _selectedDate = DateTime.now();
  File? _selectedPhoto;
  Uint8List? _webImage;
  bool _isUploading = false;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserLocation();
  }

  Future<void> _loadUserLocation() async {
    try {
      final currentUser = await UserService.getCurrentUser();
      if (currentUser == null || currentUser.locationId == null) {
        setState(() => _isLoadingLocation = false);
        return;
      }

      final location = await LocationService.getLocationById(currentUser.locationId!);
      if (location != null) {
        setState(() {
          _selectedLokasiId = location.id;
          _selectedLokasiName = location.name;
          _lokasiFullAddress = location.fullAddress;
          _isLoadingLocation = false;
        });
      } else {
        setState(() => _isLoadingLocation = false);
      }
    } catch (e) {
      print('Error loading user location: $e');
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb && source == ImageSource.camera) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kamera tidak tersedia di web')),
      );
      return;
    }
    
    if (kIsWeb) {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final webImage = await pickedFile.readAsBytes();
        setState(() {
          _webImage = webImage;
          _selectedPhoto = null;
        });
      }
    } else {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedPhoto = File(pickedFile.path);
          _webImage = null;
        });
      }
    }
  }

  Future<String> uploadImage(File? image, Uint8List? webimage) async {
    String docnya = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = FirebaseStorage.instance.ref().child('nota_pengeluaran').child(docnya);

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
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.receipt_long, 
                    color: Colors.orange, 
                    size: isWeb ? 24 : 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Nota Pengeluaran',
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tipe Koordinator
                      Text(
                        'Tipe Koordinator',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKoordinatorTypeCard(
                              TipeKoordinator.koordinator,
                              'Koordinator',
                              Icons.person,
                              Colors.green,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildKoordinatorTypeCard(
                              TipeKoordinator.koordinatorIT,
                              'Koordinator IT',
                              Icons.computer,
                              Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isWeb ? 20 : 16),

                      // Lokasi (Read-only from user data)
                      if (_isLoadingLocation)
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Memuat lokasi...'),
                            ],
                          ),
                        )
                      else if (_selectedLokasiId.isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Lokasi',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                _selectedLokasiName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                _lokasiFullAddress,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
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
                                  'Anda belum memiliki lokasi yang ditugaskan.',
                                  style: TextStyle(color: Colors.orange.shade600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      SizedBox(height: isWeb ? 20 : 16),

                      // Jenis
                      DropdownButtonFormField<String>(
                        value: _selectedJenis,
                        decoration: InputDecoration(
                          labelText: 'Jenis Nota *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items: NotaCategories.jenisNota.map((jenis) {
                          final style = NotaCategories.getJenisStyle(jenis);
                          return DropdownMenuItem(
                            value: jenis,
                            child: Row(
                              children: [
                                Icon(style['icon'], size: 20, color: style['color']),
                                SizedBox(width: 8),
                                Text(jenis),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedJenis = value!);
                        },
                      ),
                      SizedBox(height: isWeb ? 20 : 16),
                      
                      // Tanggal
                      InkWell(
                        onTap: () => _selectDate(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal *',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(fontSize: isWeb ? 16 : 14),
                          ),
                        ),
                      ),
                      SizedBox(height: isWeb ? 20 : 16),
                      
                      // Nominal
                      TextFormField(
                        controller: _nominalController,
                        decoration: InputDecoration(
                          labelText: 'Nominal *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixText: 'Rp ',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Nominal wajib diisi';
                          if (double.tryParse(value!) == null) return 'Nominal tidak valid';
                          return null;
                        },
                      ),
                      SizedBox(height: isWeb ? 20 : 16),
                      
                      // Keperluan
                      TextFormField(
                        controller: _keperluanController,
                        decoration: InputDecoration(
                          labelText: 'Keperluan *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Jelaskan keperluan pengeluaran...',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true ? 'Keperluan wajib diisi' : null,
                      ),
                      SizedBox(height: isWeb ? 20 : 16),
                      
                      // Photo Upload
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(isWeb ? 20 : 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            if (_selectedPhoto != null || _webImage != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _webImage != null
                                    ? Image.memory(
                                        _webImage!,
                                        height: isWeb ? 200 : 150,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.file(
                                        _selectedPhoto!,
                                        height: isWeb ? 200 : 150,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                              SizedBox(height: 12),
                            ],
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!kIsWeb)
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.camera),
                                    icon: Icon(Icons.camera_alt, size: 18),
                                    label: Text('Kamera'),
                                    style: ElevatedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                                if (!kIsWeb) SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: () => _pickImage(ImageSource.gallery),
                                  icon: Icon(Icons.photo_library, size: 18),
                                  label: Text('Galeri'),
                                  style: ElevatedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Actions
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isUploading ? null : () => Navigator.pop(context),
                      child: Text('Batal'),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _submitNota,
                      child: _isUploading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: isWeb ? 16 : 14),
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

  Widget _buildKoordinatorTypeCard(TipeKoordinator type, String label, IconData icon, Color color) {
    final isSelected = _selectedTipeKoordinator == type;
    
    return InkWell(
      onTap: () => setState(() => _selectedTipeKoordinator = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? color : Colors.grey.shade400,
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitNota() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedPhoto == null && _webImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Foto nota wajib diupload')),
      );
      return;
    }

    if (_selectedLokasiId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi tidak ditemukan. Hubungi admin untuk menugaskan lokasi.')),
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

      final photoUrl = await uploadImage(_selectedPhoto, _webImage);

      final nota = NotaModel(
        notaId: '',
        koordinatorId: currentUser.uid,
        koordinatorName: currentUserData.name,
        tipeKoordinator: _selectedTipeKoordinator,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        projectId: widget.projectId,
        jenis: _selectedJenis,
        tanggal: _selectedDate,
        nominal: double.parse(_nominalController.text),
        keperluan: _keperluanController.text.trim(),
        fotoNotaUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await NotaService.createNotaForProject(widget.projectId, nota);
      widget.onAdded();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    setState(() => _isUploading = false);
  }

  @override
  void dispose() {
    _keperluanController.dispose();
    _nominalController.dispose();
    super.dispose();
  }
}

// Detail Dialog
class NotaDetailDialog extends StatelessWidget {
  final NotaModel nota;

  const NotaDetailDialog({Key? key, required this.nota}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 768;
    final jenisStyle = NotaCategories.getJenisStyle(nota.jenis);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(isWeb ? 20 : 16)),
      child: Container(
        width: isWeb ? 600.0 : screenWidth * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isWeb ? 24 : 20),
              decoration: BoxDecoration(
                color: jenisStyle['color'].withOpacity(0.1),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isWeb ? 20 : 16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: jenisStyle['color'],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(jenisStyle['icon'], color: Colors.white),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Detail Nota',
                          style: TextStyle(
                            fontSize: isWeb ? 20 : 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          nota.jenis,
                          style: TextStyle(
                            fontSize: 14,
                            color: jenisStyle['color'],
                          ),
                        ),
                      ],
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
                    // Photo
                    Container(
                      width: double.infinity,
                      height: isWeb ? 250 : 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          nota.fotoNotaUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) =>
                              Center(child: Icon(Icons.error)),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Amount
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isWeb ? 20 : 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Nominal Pengeluaran',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontSize: isWeb ? 16 : 14,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            nota.formattedNominal,
                            style: TextStyle(
                              fontSize: isWeb ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Info
                    _buildInfoRow('Tipe', nota.tipeKoordinatorDisplayName, Icons.badge, 
                        nota.tipeKoordinator == TipeKoordinator.koordinatorIT ? Colors.blue : Colors.green),
                    _buildInfoRow('Jenis', nota.jenis, jenisStyle['icon'], jenisStyle['color']),
                    _buildInfoRow('Tanggal', nota.formattedTanggal, Icons.calendar_today, Colors.grey.shade600),
                    _buildInfoRow('Lokasi', nota.lokasiName, Icons.location_on, Colors.grey.shade600),
                    _buildInfoRow('Keperluan', nota.keperluan, Icons.description, Colors.grey.shade600),
                    _buildInfoRow('Dibuat', nota.formattedDate, Icons.access_time, Colors.grey.shade600),
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
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(0, isWeb ? 50 : 45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
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
}