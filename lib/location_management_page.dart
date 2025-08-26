import 'package:flutter/material.dart';
import 'location_service.dart';
import 'location_model.dart';

class LocationManagementPage extends StatefulWidget {
  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  final _searchController = TextEditingController();
  String? _selectedCityFilter;
  String? _selectedProvinceFilter;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Lokasi'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showLocationDialog,
            icon: Icon(Icons.add_location),
            tooltip: 'Tambah Lokasi',
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
                    hintText: 'Cari lokasi...',
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
                      // Province Filter
                      _buildProvinceFilter(),
                      SizedBox(width: 8),
                      
                      // City Filter
                      _buildCityFilter(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Locations List
          Expanded(
            child: StreamBuilder<List<LocationModel>>(
              stream: LocationService.getAllLocations(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final locations = _filterLocations(snapshot.data ?? []);

                if (locations.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    return _buildLocationCard(locations[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProvinceFilter() {
    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedProvinceFilter != null ? Colors.blue.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map,
              size: 16,
              color: _selectedProvinceFilter != null ? Colors.blue.shade600 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedProvinceFilter ?? 'Provinsi',
              style: TextStyle(
                color: _selectedProvinceFilter != null ? Colors.blue.shade600 : Colors.grey.shade600,
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
          child: Text('Semua Provinsi'),
        ),
        ...LocationService.getCommonProvinces().map((province) => PopupMenuItem(
          value: province,
          child: Text(province),
        )),
      ],
      onSelected: (value) {
        setState(() {
          _selectedProvinceFilter = value;
          _selectedCityFilter = null; // Reset city filter when province changes
        });
      },
    );
  }

  Widget _buildCityFilter() {
    return PopupMenuButton<String?>(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedCityFilter != null ? Colors.orange.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.location_city,
              size: 16,
              color: _selectedCityFilter != null ? Colors.orange.shade600 : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedCityFilter ?? 'Kota',
              style: TextStyle(
                color: _selectedCityFilter != null ? Colors.orange.shade600 : Colors.grey.shade600,
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
          child: Text('Semua Kota'),
        ),
        ...LocationService.getCommonCities().map((city) => PopupMenuItem(
          value: city,
          child: Text(city),
        )),
      ],
      onSelected: (value) {
        setState(() => _selectedCityFilter = value);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'Tidak ada lokasi ditemukan',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambah lokasi pertama Anda',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showLocationDialog,
            icon: Icon(Icons.add),
            label: Text('Tambah Lokasi'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
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
                      Text(
                        location.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location.shortLocation,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Menu
                PopupMenuButton<String>(
                  onSelected: (value) => _handleLocationAction(value, location),
                  itemBuilder: (context) => [
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
            
            // Address
            Text(
              location.address,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
            
            // Description
            if (location.description != null && location.description!.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                location.description!,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<LocationModel> _filterLocations(List<LocationModel> locations) {
    return locations.where((location) {
      final matchesSearch = location.name.toLowerCase().contains(_searchQuery) ||
          location.city.toLowerCase().contains(_searchQuery) ||
          location.address.toLowerCase().contains(_searchQuery) ||
          location.province.toLowerCase().contains(_searchQuery);
      
      final matchesProvince = _selectedProvinceFilter == null || location.province == _selectedProvinceFilter;
      final matchesCity = _selectedCityFilter == null || location.city == _selectedCityFilter;
      
      return matchesSearch && matchesProvince && matchesCity;
    }).toList();
  }

  void _handleLocationAction(String action, LocationModel location) {
    switch (action) {
      case 'edit':
        _showLocationDialog(location: location);
        break;
      case 'delete':
        _showDeleteConfirmation(location);
        break;
    }
  }

  void _showLocationDialog({LocationModel? location}) {
    showDialog(
      context: context,
      builder: (context) => LocationFormDialog(
        location: location,
        onSaved: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(location == null ? 'Lokasi berhasil ditambahkan' : 'Lokasi berhasil diperbarui'),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(LocationModel location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Lokasi'),
        content: Text('Apakah Anda yakin ingin menghapus lokasi "${location.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => _deleteLocation(location),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _deleteLocation(LocationModel location) async {
    Navigator.pop(context);
    
    try {
      await LocationService.deleteLocation(location.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi berhasil dihapus')),
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
class LocationFormDialog extends StatefulWidget {
  final LocationModel? location;
  final VoidCallback onSaved;

  const LocationFormDialog({
    Key? key,
    this.location,
    required this.onSaved,
  }) : super(key: key);

  @override
  _LocationFormDialogState createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCity = '';
  String _selectedProvince = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _loadLocationData(widget.location!);
    } else {
      _selectedCity = LocationService.getCommonCities().first;
      _selectedProvince = LocationService.getCommonProvinces().first;
    }
  }

  void _loadLocationData(LocationModel location) {
    _nameController.text = location.name;
    _addressController.text = location.address;
    _selectedCity = location.city;
    _selectedProvince = location.province;
    _descriptionController.text = location.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
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
                  Icon(Icons.location_on, color: Theme.of(context).primaryColor),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.location == null ? 'Tambah Lokasi' : 'Edit Lokasi',
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
                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Nama Lokasi *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Nama lokasi wajib diisi' : null,
                      ),
                      SizedBox(height: 16),
                      
                      // Province and City
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedProvince.isEmpty ? null : _selectedProvince,
                              decoration: InputDecoration(
                                labelText: 'Provinsi *',
                                border: OutlineInputBorder(),
                              ),
                              items: LocationService.getCommonProvinces().map((province) {
                                return DropdownMenuItem(value: province, child: Text(province));
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedProvince = value ?? ''),
                              validator: (value) => value?.isEmpty ?? true ? 'Provinsi wajib dipilih' : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCity.isEmpty ? null : _selectedCity,
                              decoration: InputDecoration(
                                labelText: 'Kota *',
                                border: OutlineInputBorder(),
                              ),
                              items: LocationService.getCommonCities().map((city) {
                                return DropdownMenuItem(value: city, child: Text(city));
                              }).toList(),
                              onChanged: (value) => setState(() => _selectedCity = value ?? ''),
                              validator: (value) => value?.isEmpty ?? true ? 'Kota wajib dipilih' : null,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      
                      // Address
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Alamat Lengkap *',
                          border: OutlineInputBorder(),
                          hintText: 'Jl. Sudirman No. 123, RT/RW 01/02',
                        ),
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true ? 'Alamat wajib diisi' : null,
                      ),
                      SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi (Opsional)',
                          border: OutlineInputBorder(),
                          hintText: 'Deskripsi singkat tentang lokasi ini',
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
                      onPressed: _isLoading ? null : _saveLocation,
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.location == null ? 'Tambah' : 'Update'),
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

  void _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final location = LocationModel(
        id: widget.location?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _selectedCity,
        province: _selectedProvince,
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        createdAt: widget.location?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.location == null) {
        await LocationService.createLocation(location);
      } else {
        await LocationService.updateLocation(widget.location!.id, location);
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
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}