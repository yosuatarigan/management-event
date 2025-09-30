import 'package:flutter/material.dart';
import 'package:management_event/badismantle/list_ba_dismantle.dart';

class BASelectionPage extends StatelessWidget {
  const BASelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Template BA'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBACard(
            context,
            icon: Icons.build_outlined,
            title: 'BA Dismantle',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BADismantleListPage()),
              );
            },
          ),
          _buildBACard(
            context,
            icon: Icons.calendar_today,
            title: 'BA Harian',
            onTap: () {
              // Navigate ke BA Harian
            },
          ),
          _buildBACard(
            context,
            icon: Icons.swap_horiz,
            title: 'BA Perubahan Volume',
            onTap: () {
              // Navigate ke BA Perubahan Volume
            },
          ),
          _buildBACard(
            context,
            icon: Icons.description_outlined,
            title: 'BA Perubahan Volume di luar Kontrak',
            onTap: () {
              // Navigate ke BA Perubahan Volume di luar Kontrak
            },
          ),
          _buildBACard(
            context,
            icon: Icons.check_circle_outline,
            title: 'BA Uji Fungsi',
            onTap: () {
              // Navigate ke BA Uji Fungsi
            },
          ),
          _buildBACard(
            context,
            icon: Icons.photo_library_outlined,
            title: 'Template Laporan Visual Kegiatan',
            onTap: () {
              // Navigate ke Template Laporan Visual
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBACard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue[700]),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}