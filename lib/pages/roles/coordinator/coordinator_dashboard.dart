import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import 'forms/ba_form_page.dart';
import 'forms/evidence_upload_page.dart';
import 'forms/reimburse_form_page.dart';

class CoordinatorDashboard extends StatelessWidget {
  const CoordinatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile('Buat Berita Acara', Icons.description, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const BAFormPage()));
      }),
      _Tile('Upload Evidence', Icons.photo_camera, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const EvidenceUploadPage()));
      }),
      _Tile('Input Reimburse', Icons.receipt_long, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReimburseFormPage()));
      }),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Koordinator'),
        actions: [
          IconButton(onPressed: () => AuthService.signOut(), icon: const Icon(Icons.logout)),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: tiles.map((t) => Card(
          child: InkWell(
            onTap: t.onTap,
            child: Center(child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(t.icon, size: 40),
                const SizedBox(height: 8),
                Text(t.title),
              ],
            )),
          ),
        )).toList(),
      ),
    );
  }
}

class _Tile {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  _Tile(this.title, this.icon, this.onTap);
}
