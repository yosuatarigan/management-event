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
import 'user_model.dart';
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
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${notaList.length} nota',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Icon(Icons.receipt_long, color: Colors.orange, size: 24),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Total Pengeluaran',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            'Rp ${totalAmount.toStringAsFixed(0).replaceAllMapped(
                                              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                              (Match match) => '${match[1]}.',
                                            )}',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Text(
                                        '${notaList.length} nota',
                                        style: TextStyle(
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        }
                        return Container();
                      },
                    ),
                    
                    // Nota List
                    Expanded(
                      child: StreamBuilder<List<NotaModel>>(
                        stream: NotaService.getCurrentUserNotaByProject(currentProjectId),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }

                          final notaList = _filterNota(snapshot.data ?? []);

                          if (notaList.isEmpty) {
                            return _buildEmptyState(isWeb, currentProjectId);
                          }

                          return _buildNotaList(notaList, isWeb);
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
    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isWeb ? 16 : 12,
          vertical: isWeb ? 12 : 8,
        ),
        decoration: BoxDecoration(
          color: _selectedJenisFilter != null
              ? Colors.orange.shade100
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
              color: _selectedJenisFilter != null
                  ? Colors.orange.shade600
                  : Colors.grey.shade600,
            ),
            SizedBox(width: 6),
            Text(
              _selectedJenisFilter ?? 'Semua Jenis',
              style: TextStyle(
                color: _selectedJenisFilter != null
                    ? Colors.orange.shade600
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
        PopupMenuItem(value: null, child: Text('Semua Jenis')),
        ...NotaCategories.jenisNota.map(
          (jenis) => PopupMenuItem(
            value: jenis,
            child: Text(jenis),
          ),
        ),
      ],
      onSelected: (value) {
        setState(() => _selectedJenisFilter = value);
      },
    );
  }

  Widget _buildNotaList(List<NotaModel> notaList, bool isWeb) {
    if (isWeb) {
      return GridView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 20,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
        ),
        itemCount: notaList.length,
        itemBuilder: (context, index) {
          return _buildNotaCard(notaList[index], isWeb);
        },
      );
    } else {
      return ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: notaList.length,
        itemBuilder: (context, index) {
          return _buildNotaCard(notaList[index], isWeb);
        },
      );
    }
  }

  Widget _buildEmptyState(bool isWeb, String projectId) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: isWeb ? 80 : 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: isWeb ? 24 : 16),
          Text(
            'Belum ada nota pengeluaran',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: isWeb ? 20 : 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan nota pengeluaran pertama Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: isWeb ? 16 : 14,
            ),
          ),
          SizedBox(height: isWeb ? 32 : 24),
          ElevatedButton.icon(
            onPressed: () => _showAddNotaDialog(projectId),
            icon: Icon(Icons.add),
            label: Text('Tambah Nota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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

  Widget _buildNotaCard(NotaModel nota, bool isWeb) {
    final jenisStyle = NotaCategories.getJenisStyle(nota.jenis);
    
    return Card(
      margin: isWeb ? EdgeInsets.zero : EdgeInsets.only(bottom: 12),
      elevation: isWeb ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(isWeb ? 16 : 12),
        onTap: () => _showDetailDialog(nota),
        child: Padding(
          padding: EdgeInsets.all(isWeb ? 20 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: isWeb ? 60 : 50,
                height: isWeb ? 60 : 50,
                decoration: BoxDecoration(
                  color: jenisStyle['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isWeb ? 12 : 8),
                ),
                child: Icon(
                  jenisStyle['icon'],
                  color: jenisStyle['color'],
                  size: isWeb ? 28 : 24,
                ),
              ),
              SizedBox(width: isWeb ? 16 : 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Jenis Badge
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWeb ? 10 : 8,
                        vertical: isWeb ? 5 : 4,
                      ),
                      decoration: BoxDecoration(
                        color: jenisStyle['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        nota.jenis,
                        style: TextStyle(
                          color: jenisStyle['color'],
                          fontSize: isWeb ? 11 : 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    SizedBox(height: isWeb ? 10 : 8),
                    
                    // Amount & Date
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nota.formattedNominal,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isWeb ? 20 : 18,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Text(
                          nota.formattedTanggal,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: isWeb ? 14 : 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isWeb ? 8 : 6),
                    
                    // Purpose
                    Text(
                      nota.keperluan,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: isWeb ? 16 : 14,
                      ),
                      maxLines: isWeb ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isWeb ? 6 : 4),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on, 
                          size: isWeb ? 16 : 14, 
                          color: Colors.grey.shade600,
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nota.lokasiName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isWeb ? 14 : 12,
                            ),
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  List<NotaModel> _filterNota(List<NotaModel> notaList) {
    return notaList.where((nota) {
      final matchesSearch = nota.keperluan.toLowerCase().contains(_searchQuery) ||
          nota.lokasiName.toLowerCase().contains(_searchQuery) ||
          nota.jenis.toLowerCase().contains(_searchQuery) ||
          nota.formattedNominal.toLowerCase().contains(_searchQuery);
      
      final matchesJenis = _selectedJenisFilter == null ||
          nota.jenis == _selectedJenisFilter;
      
      return matchesSearch && matchesJenis;
    }).toList();
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Add Nota Dialog dengan Jenis & Lokasi Otomatis
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
  String _selectedJenis = 'Lain-lain';
  DateTime _selectedDate = DateTime.now();
  File? _selectedPhoto;
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

    if (user != null && user.locationId != null && user.locationId!.isNotEmpty) {
      try {
        final userLocation = await LocationService.getLocationById(user.locationId!);
        
        if (userLocation != null) {
          setState(() {
            _selectedLokasiId = userLocation.id;
            _selectedLokasiName = '${userLocation.name} - ${userLocation.city}';
          });
        }
      } catch (e) {
        print('Error loading user location: $e');
      }
    }

    setState(() {
      _currentUser = user;
      _isLoadingUser = false;
    });
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
                    children: [
                      // Lokasi (Otomatis)
                      _isLoadingUser
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _selectedLokasiId.isNotEmpty
                              ? TextFormField(
                                  initialValue: _selectedLokasiName,
                                  readOnly: true,
                                  decoration: InputDecoration(
                                    labelText: 'Lokasi (Otomatis)',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(Icons.location_on),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                  ),
                                )
                              : Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.red.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.error_outline, color: Colors.red.shade600),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Akun Anda belum memiliki lokasi. Hubungi admin.',
                                          style: TextStyle(color: Colors.red.shade600),
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
                            if (_selectedPhoto == null && _webImage == null) ...[
                              Icon(
                                Icons.camera_alt_outlined,
                                size: isWeb ? 56 : 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Foto Nota *',
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
                                children: [
                                  if (!kIsWeb)
                                    ElevatedButton.icon(
                                      onPressed: () => _pickImage(ImageSource.camera),
                                      icon: Icon(Icons.camera_alt, size: 20),
                                      label: Text('Kamera'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ElevatedButton.icon(
                                    onPressed: () => _pickImage(ImageSource.gallery),
                                    icon: Icon(Icons.photo, size: 20),
                                    label: Text(kIsWeb ? 'Pilih File' : 'Galeri'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                height: isWeb ? 150 : 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: _webImage != null
                                      ? Image.memory(_webImage!, fit: BoxFit.cover)
                                      : Image.file(_selectedPhoto!, fit: BoxFit.cover),
                                ),
                              ),
                              SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() {
                                      _selectedPhoto = null;
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
                                    onPressed: () => _pickImage(ImageSource.gallery),
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
                      onPressed: _isUploading || 
                                 (_selectedPhoto == null && _webImage == null) ||
                                 _selectedLokasiId.isEmpty
                          ? null 
                          : _submitNota,
                      child: _isUploading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
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

  void _selectDate() async {
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
        SnackBar(content: Text('Akun Anda belum memiliki lokasi. Hubungi admin.')),
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