import 'package:flutter/material.dart';
import 'package:management_event/badismantle/list_ba_dismantle.dart';
import 'package:management_event/baharian/ba_harian_list_page.dart';
import 'package:management_event/baperubahanvolume/list_ba_perubahan_volume.dart';
import 'package:management_event/baperubahanvolumediluarkontrak/ba_perubahan_volume_luar_kontrak_list_page.dart';

class BASelectionPage extends StatelessWidget {
  const BASelectionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[700]!, Colors.blue[900]!],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.description_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Berita Acara',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih template BA yang ingin dibuat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildBACard(
                        context,
                        icon: Icons.build_circle_outlined,
                        title: 'BA Dismantle',
                        subtitle: 'Pembongkaran sarana prasarana',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BADismantleListPage()),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.calendar_today_rounded,
                        title: 'BA Harian',
                        subtitle: 'Berita acara harian',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BAHarianListPage()),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        title: 'BA Perubahan Volume',
                        subtitle: 'Perubahan volume pekerjaan',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BAPerubahanVolumeListPage()),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.add_box_outlined,
                        title: 'BA Penambahan Volume di Luar Kontrak',
                        subtitle: 'Penambahan volume di luar kontrak',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const BAPerubahanVolumeLuarKontrakListPage()),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.verified_outlined,
                        title: 'BA Uji Fungsi',
                        subtitle: 'Pengujian fungsi peralatan',
                        color: Colors.teal,
                        onTap: () {},
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.photo_library_outlined,
                        title: 'Template Laporan Visual Kegiatan',
                        subtitle: 'Dokumentasi visual kegiatan',
                        color: Colors.pink,
                        onTap: () {},
                      ),
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

  Widget _buildBACard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}