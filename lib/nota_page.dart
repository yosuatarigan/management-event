import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'nota_service.dart';
import 'nota_model.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'user_service.dart';

class NotaPage extends StatefulWidget {
  @override
  _NotaPageState createState() => _NotaPageState();
}

class _NotaPageState extends State<NotaPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nota Pengeluaran'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showAddNotaDialog(),
            icon: Icon(Icons.add),
            tooltip: 'Tambah Nota',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Section
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nota...',
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
          ),
          
          // Total Amount Summary
          StreamBuilder<List<NotaModel>>(
            stream: NotaService.getCurrentUserNota(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final notaList = snapshot.data!;
                final totalAmount = notaList.fold<double>(0, (sum, n) => sum + n.nominal);

                return Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
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
              stream: NotaService.getCurrentUserNota(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final notaList = _filterNota(snapshot.data ?? []);

                if (notaList.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: notaList.length,
                  itemBuilder: (context, index) {
                    return _buildNotaCard(notaList[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Belum ada nota pengeluaran',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambahkan nota pengeluaran pertama Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddNotaDialog(),
            icon: Icon(Icons.add),
            label: Text('Tambah Nota'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotaCard(NotaModel nota) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetailDialog(nota),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Receipt Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.receipt,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            nota.formattedNominal,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                        Text(
                          nota.formattedTanggal,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    
                    // Purpose
                    Text(
                      nota.keperluan,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6),
                    
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            nota.lokasiName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
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
          nota.formattedNominal.toLowerCase().contains(_searchQuery);
      
      return matchesSearch;
    }).toList();
  }

  void _showAddNotaDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNotaDialog(
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

// Add Nota Dialog
class AddNotaDialog extends StatefulWidget {
  final VoidCallback onAdded;

  const AddNotaDialog({Key? key, required this.onAdded}) : super(key: key);

  @override
  _AddNotaDialogState createState() => _AddNotaDialogState();
}

class _AddNotaDialogState extends State<AddNotaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _keperluanController = TextEditingController();
  final _nominalController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedLokasiId = '';
  String _selectedLokasiName = '';
  DateTime _selectedDate = DateTime.now();
  File? _selectedPhoto;
  bool _isUploading = false;

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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tambah Nota Pengeluaran',
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
                      // Tanggal
                      InkWell(
                        onTap: () => _selectDate(),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Tanggal *',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      
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
                      
                      // Nominal
                      TextFormField(
                        controller: _nominalController,
                        decoration: InputDecoration(
                          labelText: 'Nominal *',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Nominal wajib diisi';
                          if (double.tryParse(value!) == null) return 'Nominal tidak valid';
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Keperluan
                      TextFormField(
                        controller: _keperluanController,
                        decoration: InputDecoration(
                          labelText: 'Keperluan *',
                          border: OutlineInputBorder(),
                          hintText: 'Jelaskan keperluan pengeluaran...',
                        ),
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true ? 'Keperluan wajib diisi' : null,
                      ),
                      SizedBox(height: 16),
                      
                      // Photo Upload Section
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            if (_selectedPhoto == null) ...[
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 48,
                                color: Colors.grey.shade400,
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Foto Nota *',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _capturePhoto(ImageSource.camera),
                                    icon: Icon(Icons.camera_alt, size: 20),
                                    label: Text('Kamera'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _capturePhoto(ImageSource.gallery),
                                    icon: Icon(Icons.photo, size: 20),
                                    label: Text('Galeri'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedPhoto!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => setState(() => _selectedPhoto = null),
                                    icon: Icon(Icons.delete, size: 20),
                                    label: Text('Hapus'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: () => _capturePhoto(ImageSource.camera),
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
                      onPressed: _isUploading || _selectedPhoto == null ? null : _submitNota,
                      child: _isUploading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Simpan'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
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

  void _capturePhoto(ImageSource source) async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 80,
      );
      
      if (photo != null) {
        setState(() => _selectedPhoto = File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error mengambil foto: $e')),
      );
    }
  }

  void _submitNota() async {
    if (!_formKey.currentState!.validate() || _selectedPhoto == null) return;

    // Validate photo
    if (!NotaService.isValidPhoto(_selectedPhoto!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Format foto tidak didukung')),
      );
      return;
    }

    if (!NotaService.isValidFileSize(_selectedPhoto!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ukuran foto terlalu besar (max 10MB)')),
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

      // Create temporary nota ID for photo upload
      final tempNotaId = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Upload photo
      final photoUrl = await NotaService.uploadPhoto(_selectedPhoto!, tempNotaId);

      final nota = NotaModel(
        notaId: '',
        koordinatorId: currentUser.uid,
        koordinatorName: currentUserData.name,
        lokasiId: _selectedLokasiId,
        lokasiName: _selectedLokasiName,
        tanggal: _selectedDate,
        nominal: double.parse(_nominalController.text),
        keperluan: _keperluanController.text.trim(),
        fotoNotaUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await NotaService.createNota(nota);
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
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(Icons.receipt_long, color: Colors.orange),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Detail Nota Pengeluaran',
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
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          nota.fotoNotaUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.image_not_supported, size: 48),
                                  SizedBox(height: 8),
                                  Text('Gagal memuat foto'),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Amount (prominent)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
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
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            nota.formattedNominal,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Info Details
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem('Tanggal', nota.formattedTanggal),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildInfoItem('Lokasi', nota.lokasiName),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Purpose
                    _buildInfoItem('Keperluan', nota.keperluan),
                    SizedBox(height: 16),
                    _buildInfoItem('Dibuat', nota.formattedDate),
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