import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/firestore_refs.dart';

class EvidenceUploadPage extends StatefulWidget {
  const EvidenceUploadPage({super.key});

  @override
  State<EvidenceUploadPage> createState() => _EvidenceUploadPageState();
}

class _EvidenceUploadPageState extends State<EvidenceUploadPage> {
  String? eventId;
  String? locationId;
  String? baId;
  XFile? picked;
  bool isVideo = false;
  bool uploading = false;

  Future<void> _pick(bool video) async {
    final picker = ImagePicker();
    final XFile? file = video
        ? await picker.pickVideo(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) {
      setState(() { picked = file; isVideo = video; });
    }
  }

  Future<void> _upload() async {
    if (eventId == null || locationId == null || picked == null) return;
    setState(() => uploading = true);
    try {
      final storage = FirebaseStorage.instance;
      final ext = isVideo ? 'mp4' : 'jpg';
      final ref = storage.ref().child('evidence/${eventId!}/${locationId!}/${DateTime.now().millisecondsSinceEpoch}.$ext');
      final task = await ref.putFile(File(picked!.path));
      final url = await task.ref.getDownloadURL();

      await evidenceCol().add({
        'eventId': eventId,
        'locationId': locationId,
        'baId': baId,
        'type': isVideo ? 'video' : 'photo',
        'url': url,
        'fromCamera': true,
        'status': 'submitted', // submitted -> approved/rejected
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Evidence diupload')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = picked == null
        ? const Placeholder(fallbackHeight: 160)
        : isVideo ? const Icon(Icons.videocam, size: 80) : Image.file(File(picked!.path), height: 160);

    return Scaffold(
      appBar: AppBar(title: const Text('Upload Evidence')),
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
          TextField(
            decoration: const InputDecoration(
              labelText: 'Nomor/ID BA (opsional, biarkan kosong jika tidak terkait)',
            ),
            onChanged: (v) => baId = v.trim().isEmpty ? null : v.trim(),
          ),
          const SizedBox(height: 12),
          preview,
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              OutlinedButton.icon(onPressed: () => _pick(false), icon: const Icon(Icons.photo_camera), label: const Text('Foto (Kamera)')),
              OutlinedButton.icon(onPressed: () => _pick(true), icon: const Icon(Icons.videocam), label: const Text('Video (Kamera)')),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: uploading ? null : _upload, child: Text(uploading ? 'Mengunggah...' : 'Upload Evidence')),
        ],
      ),
    );
  }
}
