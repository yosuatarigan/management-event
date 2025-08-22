import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../../services/firestore_refs.dart';

class BAFormPage extends StatefulWidget {
  const BAFormPage({super.key});

  @override
  State<BAFormPage> createState() => _BAFormPageState();
}

class _BAFormPageState extends State<BAFormPage> {
  final titleC = TextEditingController();
  final contentC = TextEditingController();
  String? eventId;
  String? locationId;
  String baType = 'Umum';
  bool saving = false;

  Future<void> _save() async {
    if (eventId == null || locationId == null || titleC.text.trim().isEmpty) return;
    setState(() => saving = true);
    try {
      await baCol().add({
        'eventId': eventId,
        'locationId': locationId,
        'type': baType, // sementara: jenis BA sederhana (template menyusul)
        'title': titleC.text.trim(),
        'content': contentC.text.trim(),
        'status': 'submitted', // submitted -> approved/rejected
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('BA dikirim')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat Berita Acara')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StreamBuilder(
            stream: eventsCol().orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: eventId,
                decoration: const InputDecoration(labelText: 'Pilih Acara'),
                items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'] ?? '-'))).toList(),
                onChanged: (v) => setState(() => eventId = v),
              );
            },
          ),
          const SizedBox(height: 8),
          StreamBuilder(
            stream: locationsCol().orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              return DropdownButtonFormField<String>(
                value: locationId,
                decoration: const InputDecoration(labelText: 'Pilih Lokasi'),
                items: docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d['name'] ?? '-'))).toList(),
                onChanged: (v) => setState(() => locationId = v),
              );
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField(
            value: baType,
            decoration: const InputDecoration(labelText: 'Jenis BA'),
            items: const [
              DropdownMenuItem(value: 'Umum', child: Text('Umum')),
              DropdownMenuItem(value: 'Teknis', child: Text('Teknis')),
              DropdownMenuItem(value: 'Insiden', child: Text('Insiden')),
            ],
            onChanged: (v) => setState(() => baType = v as String),
          ),
          const SizedBox(height: 8),
          TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Judul')),
          const SizedBox(height: 8),
          TextField(
            controller: contentC,
            decoration: const InputDecoration(labelText: 'Isi Ringkas'),
            minLines: 3, maxLines: 5,
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: saving ? null : _save, child: Text(saving ? 'Menyimpan...' : 'Kirim BA')),
        ],
      ),
    );
  }
}
