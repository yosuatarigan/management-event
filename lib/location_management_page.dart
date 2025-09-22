import 'package:flutter/material.dart';
import 'location_service.dart';
import 'location_model.dart';
import 'project_service.dart';
import 'project_model.dart';

class LocationManagementPage extends StatefulWidget {
  @override
  _LocationManagementPageState createState() => _LocationManagementPageState();
}

class _LocationManagementPageState extends State<LocationManagementPage> {
  final _searchController = TextEditingController();
  String? _selectedProvinceFilter;
  String _searchQuery = '';
  String? _selectedProjectId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Lokasi'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed:
                _selectedProjectId != null ? () => _showLocationDialog() : null,
            icon: Icon(Icons.add_location),
            tooltip: 'Tambah Lokasi',
          ),
        ],
      ),
      body: Column(
        children: [
          // Project Selector
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Proyek',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed:
                          _selectedProjectId != null
                              ? () => _showCopyLocationsDialog()
                              : null,
                      icon: Icon(Icons.copy, size: 16),
                      label: Text('Copy Lokasi'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                StreamBuilder<List<ProjectModel>>(
                  stream: ProjectService.getProjects(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return Container(
                        height: 50,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final projects = snapshot.data!;

                    return DropdownButtonFormField<String>(
                      value: _selectedProjectId,
                      decoration: InputDecoration(
                        labelText: 'Proyek',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.folder_special),
                      ),
                      items:
                          projects.map((project) {
                            return DropdownMenuItem<String>(
                              value: project.id,
                              child: Text(project.name),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedProjectId = value;
                          _searchQuery = '';
                          _selectedProvinceFilter = null;
                        });
                        _searchController.clear();
                      },
                      hint: Text('Pilih proyek untuk mengelola lokasi'),
                    );
                  },
                ),
              ],
            ),
          ),

          // Search and Filter Section (only show when project selected)
          if (_selectedProjectId != null)
            Container(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
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

                        // Reset Filter Button
                        if (_selectedProvinceFilter != null)
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedProvinceFilter = null;
                              });
                            },
                            icon: Icon(Icons.clear, size: 16),
                            label: Text('Reset Filter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.grey.shade700,
                              elevation: 0,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Locations List or Project Selection Message
          Expanded(
            child:
                _selectedProjectId == null
                    ? _buildSelectProjectMessage()
                    : StreamBuilder<List<LocationModel>>(
                      stream: LocationService.getLocationsByProject(
                        _selectedProjectId!,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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

  Widget _buildSelectProjectMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_special, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Pilih Proyek Terlebih Dahulu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Silakan pilih proyek untuk mengelola lokasi',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
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
          color:
              _selectedProvinceFilter != null
                  ? Colors.blue.shade100
                  : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.map,
              size: 16,
              color:
                  _selectedProvinceFilter != null
                      ? Colors.blue.shade600
                      : Colors.grey.shade600,
            ),
            SizedBox(width: 4),
            Text(
              _selectedProvinceFilter ?? 'Provinsi',
              style: TextStyle(
                color:
                    _selectedProvinceFilter != null
                        ? Colors.blue.shade600
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
            PopupMenuItem(value: null, child: Text('Semua Provinsi')),
            ...LocationService.getAllIndonesianProvinces().map(
              (province) =>
                  PopupMenuItem(value: province, child: Text(province)),
            ),
          ],
      onSelected: (value) {
        setState(() {
          _selectedProvinceFilter = value;
        });
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey.shade400),
          SizedBox(height: 16),
          Text(
            'Belum ada lokasi di proyek ini',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tambah lokasi baru atau copy dari proyek lain',
            style: TextStyle(color: Colors.grey.shade500),
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showLocationDialog(),
                icon: Icon(Icons.add),
                label: Text('Tambah Lokasi'),
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showCopyLocationsDialog(),
                icon: Icon(Icons.copy),
                label: Text('Copy Lokasi'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(LocationModel location) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
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
                  itemBuilder:
                      (context) => [
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
                          value: 'copy',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Copy ke Proyek Lain'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Hapus',
                                style: TextStyle(color: Colors.red),
                              ),
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
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),

            // Description
            if (location.description != null &&
                location.description!.isNotEmpty) ...[
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
      final matchesSearch =
          location.name.toLowerCase().contains(_searchQuery) ||
          location.city.toLowerCase().contains(_searchQuery) ||
          location.address.toLowerCase().contains(_searchQuery) ||
          location.province.toLowerCase().contains(_searchQuery);

      final matchesProvince =
          _selectedProvinceFilter == null ||
          location.province == _selectedProvinceFilter;

      return matchesSearch && matchesProvince;
    }).toList();
  }

  void _handleLocationAction(String action, LocationModel location) {
    switch (action) {
      case 'edit':
        _showLocationDialog(location: location);
        break;
      case 'copy':
        _showCopyLocationDialog(location);
        break;
      case 'delete':
        _showDeleteConfirmation(location);
        break;
    }
  }

  void _showLocationDialog({LocationModel? location}) {
    showDialog(
      context: context,
      builder:
          (context) => LocationFormDialog(
            location: location,
            projectId: _selectedProjectId!,
            onSaved: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    location == null
                        ? 'Lokasi berhasil ditambahkan'
                        : 'Lokasi berhasil diperbarui',
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showCopyLocationDialog(LocationModel location) {
    String? targetProjectId;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Copy Lokasi ke Proyek Lain'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Copy "${location.name}" ke proyek:'),
                      SizedBox(height: 16),
                      StreamBuilder<List<ProjectModel>>(
                        stream: ProjectService.getProjects(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData)
                            return CircularProgressIndicator();

                          final projects =
                              snapshot.data!
                                  .where((p) => p.id != _selectedProjectId)
                                  .toList();

                          return DropdownButtonFormField<String>(
                            value: targetProjectId,
                            decoration: InputDecoration(
                              labelText: 'Target Proyek',
                              border: OutlineInputBorder(),
                            ),
                            items:
                                projects.map((project) {
                                  return DropdownMenuItem(
                                    value: project.id,
                                    child: Text(project.name),
                                  );
                                }).toList(),
                            onChanged: (value) {
                              setDialogState(() => targetProjectId = value);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed:
                          targetProjectId != null
                              ? () => _copyLocationToProject(
                                location,
                                targetProjectId!,
                              )
                              : null,
                      child: Text('Copy'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _showCopyLocationsDialog() {
    if (_selectedProjectId == null) return;

    String? sourceProjectId;
    List<String> selectedLocationIds = [];

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setDialogState) => AlertDialog(
                  title: Text('Copy Lokasi ke Proyek Ini'),
                  content: Container(
                    width: double.maxFinite,
                    height: 400,
                    child: Column(
                      children: [
                        // Source Project Selector
                        StreamBuilder<List<ProjectModel>>(
                          stream: ProjectService.getProjects(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return CircularProgressIndicator();

                            final projects =
                                snapshot.data!
                                    .where((p) => p.id != _selectedProjectId)
                                    .toList();

                            return DropdownButtonFormField<String>(
                              value: sourceProjectId,
                              decoration: InputDecoration(
                                labelText: 'Copy dari Proyek',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  projects.map((project) {
                                    return DropdownMenuItem(
                                      value: project.id,
                                      child: Text(project.name),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setDialogState(() {
                                  sourceProjectId = value;
                                  selectedLocationIds.clear();
                                });
                              },
                            );
                          },
                        ),
                        SizedBox(height: 16),

                        // Locations List
                        if (sourceProjectId != null)
                          Expanded(
                            child: StreamBuilder<List<LocationModel>>(
                              stream: LocationService.getLocationsByProject(
                                sourceProjectId!,
                              ),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData)
                                  return CircularProgressIndicator();

                                final locations = snapshot.data!;

                                if (locations.isEmpty) {
                                  return Center(
                                    child: Text(
                                      'Tidak ada lokasi di proyek ini',
                                    ),
                                  );
                                }

                                return ListView(
                                  children:
                                      locations.map((location) {
                                        bool isSelected = selectedLocationIds
                                            .contains(location.id);

                                        return CheckboxListTile(
                                          title: Text(location.name),
                                          subtitle: Text(
                                            location.shortLocation,
                                          ),
                                          value: isSelected,
                                          onChanged: (value) {
                                            setDialogState(() {
                                              if (value == true) {
                                                selectedLocationIds.add(
                                                  location.id,
                                                );
                                              } else {
                                                selectedLocationIds.remove(
                                                  location.id,
                                                );
                                              }
                                            });
                                          },
                                        );
                                      }).toList(),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedLocationIds.isNotEmpty
                              ? () =>
                                  _copyLocationsToProject(selectedLocationIds)
                              : null,
                      child: Text('Copy ${selectedLocationIds.length} Lokasi'),
                    ),
                  ],
                ),
          ),
    );
  }

  void _copyLocationToProject(
    LocationModel location,
    String targetProjectId,
  ) async {
    Navigator.pop(context);

    try {
      await LocationService.copyLocationToProject(location.id, targetProjectId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lokasi berhasil di-copy ke proyek lain')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _copyLocationsToProject(List<String> locationIds) async {
    Navigator.pop(context);

    try {
      await LocationService.bulkCopyLocationsToProject(
        locationIds,
        _selectedProjectId!,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${locationIds.length} lokasi berhasil di-copy'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDeleteConfirmation(LocationModel location) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Hapus Lokasi'),
            content: Text(
              'Apakah Anda yakin ingin menghapus lokasi "${location.name}"?',
            ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lokasi berhasil dihapus')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Updated Form Dialog Widget
class LocationFormDialog extends StatefulWidget {
  final LocationModel? location;
  final String projectId;
  final VoidCallback onSaved;

  const LocationFormDialog({
    Key? key,
    this.location,
    required this.projectId,
    required this.onSaved,
  }) : super(key: key);

  @override
  _LocationFormDialogState createState() => _LocationFormDialogState();
}

class _LocationFormDialogState extends State<LocationFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController(); // Changed to controller
  final _descriptionController = TextEditingController();

  String _selectedProvince = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.location != null) {
      _loadLocationData(widget.location!);
    } else {
      _selectedProvince = LocationService.getAllIndonesianProvinces().first;
    }
  }

  void _loadLocationData(LocationModel location) {
    _nameController.text = location.name;
    _addressController.text = location.address;
    _cityController.text = location.city; // Load to text controller
    _selectedProvince = location.province;
    _descriptionController.text = location.description ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
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
                  Icon(
                    Icons.location_on,
                    color: Theme.of(context).primaryColor,
                  ),
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
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Nama lokasi wajib diisi'
                                    : null,
                      ),
                      SizedBox(height: 16),

                      // Province and City
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value:
                                  _selectedProvince.isEmpty
                                      ? null
                                      : _selectedProvince,
                              decoration: InputDecoration(
                                labelText: 'Provinsi *',
                                border: OutlineInputBorder(),
                              ),
                              items:
                                  LocationService.getAllIndonesianProvinces()
                                      .map((province) {
                                        return DropdownMenuItem(
                                          value: province,
                                          child: Text(province),
                                        );
                                      })
                                      .toList(),
                              onChanged:
                                  (value) => setState(
                                    () => _selectedProvince = value ?? '',
                                  ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Provinsi wajib dipilih'
                                          : null,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cityController,
                              decoration: InputDecoration(
                                labelText: 'Kota *',
                                border: OutlineInputBorder(),
                                hintText: 'Masukkan nama kota',
                              ),
                              validator:
                                  (value) =>
                                      value?.isEmpty ?? true
                                          ? 'Kota wajib diisi'
                                          : null,
                              textCapitalization: TextCapitalization.words,
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
                        validator:
                            (value) =>
                                value?.isEmpty ?? true
                                    ? 'Alamat wajib diisi'
                                    : null,
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
                      child:
                          _isLoading
                              ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : Text(
                                widget.location == null ? 'Tambah' : 'Update',
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

  void _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final location = LocationModel(
        id: widget.location?.id ?? '',
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(), // Use text controller
        province: _selectedProvince,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        projectId: widget.projectId, // Assign to current project
        createdAt: widget.location?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.location == null) {
        await LocationService.createLocationForProject(
          widget.projectId,
          location,
        );
      } else {
        await LocationService.updateLocation(widget.location!.id, location);
      }

      widget.onSaved();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose(); // Dispose city controller
    _descriptionController.dispose();
    super.dispose();
  }
}
