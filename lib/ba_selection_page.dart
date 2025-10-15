import 'package:flutter/material.dart';
import 'package:management_event/badismantle/list_ba_dismantle.dart';
import 'package:management_event/baharian/ba_harian_list_page.dart';
import 'package:management_event/baperubahanvolume/list_ba_perubahan_volume.dart';
import 'package:management_event/baperubahanvolumediluarkontrak/ba_perubahan_volume_luar_kontrak_list_page.dart';
import 'package:management_event/baujifungsi/list_ba_uji_fungsi.dart';

class BASelectionPage extends StatelessWidget {
  final String role; // 'coordinator' atau 'approver'

  const BASelectionPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Warna berbeda untuk coordinator dan approver
    final primaryColor = role == 'coordinator' ? Colors.blue : Colors.green;
    final title =
        role == 'coordinator' ? 'Berita Acara' : 'Approval Berita Acara';
    final subtitle =
        role == 'coordinator'
            ? 'Pilih template BA yang ingin dibuat'
            : 'Pilih template BA yang ingin di-approve';

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor[700]!, primaryColor[900]!],
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
                      child: Icon(
                        role == 'coordinator'
                            ? Icons.description_rounded
                            : Icons.assignment_turned_in_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
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
                        subtitle:
                            role == 'coordinator'
                                ? 'Pembongkaran sarana prasarana'
                                : 'Approve pembongkaran sarana prasarana',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BADismantleListPage(role: role),
                            ),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.calendar_today_rounded,
                        title: 'BA Harian',
                        subtitle:
                            role == 'coordinator'
                                ? 'Berita acara harian'
                                : 'Approve berita acara harian',
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BAHarianListPage(),
                            ),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.swap_horiz_rounded,
                        title: 'BA Perubahan Volume',
                        subtitle:
                            role == 'coordinator'
                                ? 'Perubahan volume pekerjaan'
                                : 'Approve perubahan volume pekerjaan',
                        color: Colors.orange,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      BAPerubahanVolumeListPage(role: role),
                            ),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.add_box_outlined,
                        title: 'BA Penambahan Volume di Luar Kontrak',
                        subtitle:
                            role == 'coordinator'
                                ? 'Penambahan volume di luar kontrak'
                                : 'Approve penambahan volume di luar kontrak',
                        color: Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      BAPerubahanVolumeLuarKontrakListPage(
                                        role: role,
                                      ),
                            ),
                          );
                        },
                      ),
                      _buildBACard(
                        context,
                        icon: Icons.verified_outlined,
                        title: 'BA Uji Fungsi',
                        subtitle:
                            role == 'coordinator'
                                ? 'Pengujian fungsi peralatan'
                                : 'Approve pengujian fungsi peralatan',
                        color: Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => BAUjiFungsiListPage(role: role),
                            ),
                          );
                        },
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
              border: Border.all(color: color.withOpacity(0.3), width: 1),
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
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
