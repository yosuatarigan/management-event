import 'package:flutter/material.dart';
import 'project_model.dart';
import 'project_service.dart';

class AddEditProjectDialog extends StatefulWidget {
  final ProjectModel? project;

  const AddEditProjectDialog({Key? key, this.project}) : super(key: key);

  @override
  _AddEditProjectDialogState createState() => _AddEditProjectDialogState();
}

class _AddEditProjectDialogState extends State<AddEditProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _venueNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  
  String _selectedVenueType = 'indoor_hall';
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;

  bool get isEdit => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameController.text = widget.project!.name;
      _descriptionController.text = widget.project!.description;
      _venueNameController.text = widget.project!.venueName;
      _addressController.text = widget.project!.address;
      _cityController.text = widget.project!.city;
      _selectedVenueType = widget.project!.venueType;
      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Row(
                children: [
                  Icon(Icons.folder_special, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Proyek Event' : 'Tambah Proyek Event',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info Proyek Section
                      _buildSectionTitle('Informasi Proyek'),
                      _buildTextField(
                        controller: _nameController,
                        label: 'Nama Proyek Event',
                        icon: Icons.event,
                        validator: (value) => value?.isEmpty ?? true 
                            ? 'Nama proyek tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Deskripsi Event',
                        icon: Icons.description,
                        maxLines: 3,
                        validator: (value) => value?.isEmpty ?? true 
                            ? 'Deskripsi tidak boleh kosong' : null,
                      ),

                      SizedBox(height: 24),

                      // Lokasi & Venue Section
                      _buildSectionTitle('Lokasi & Venue'),
                      _buildDropdown(
                        value: _selectedVenueType,
                        label: 'Jenis Venue',
                        icon: Icons.location_city,
                        items: ProjectModel.venueTypeOptions,
                        onChanged: (value) => setState(() => _selectedVenueType = value!),
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _venueNameController,
                        label: 'Nama Gedung/Tempat',
                        icon: Icons.business,
                        validator: (value) => value?.isEmpty ?? true 
                            ? 'Nama venue tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _addressController,
                        label: 'Alamat Lengkap',
                        icon: Icons.location_on,
                        maxLines: 2,
                        validator: (value) => value?.isEmpty ?? true 
                            ? 'Alamat tidak boleh kosong' : null,
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _cityController,
                        label: 'Kota',
                        icon: Icons.location_city,
                        validator: (value) => value?.isEmpty ?? true 
                            ? 'Kota tidak boleh kosong' : null,
                      ),

                      SizedBox(height: 24),

                      // Jadwal Section
                      _buildSectionTitle('Jadwal Event'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDateField(
                              label: 'Tanggal Mulai',
                              date: _startDate,
                              onTap: () => _selectDate(true),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildDateField(
                              label: 'Tanggal Selesai',
                              date: _endDate,
                              onTap: () => _selectDate(false),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Action Buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Batal'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveProject,
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEdit ? 'Update' : 'Simpan'),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
      ),
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdown({
    required String value,
    required String label,
    required IconData icon,
    required List<Map<String, String>> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: Icon(icon),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item['value'],
          child: Text(item['label']!),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Text(
          date != null 
              ? '${date.day}/${date.month}/${date.year}' 
              : 'Pilih tanggal',
          style: TextStyle(
            color: date != null ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate 
          ? (_startDate ?? DateTime.now()) 
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 365 * 2)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Reset end date if it's before start date
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      ProjectModel project = ProjectModel(
        id: widget.project?.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        venueType: _selectedVenueType,
        venueName: _venueNameController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        createdAt: widget.project?.createdAt ?? DateTime.now(),
        createdBy: widget.project?.createdBy ?? '',
      );

      if (isEdit) {
        await ProjectService.updateProject(widget.project!.id!, project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proyek berhasil diupdate')),
        );
      } else {
        await ProjectService.createProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proyek berhasil dibuat')),
        );
      }

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _venueNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}