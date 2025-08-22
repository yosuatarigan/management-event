import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../services/firestore_refs.dart';

class ReimburseFormPage extends StatefulWidget {
  const ReimburseFormPage({super.key});

  @override
  State<ReimburseFormPage> createState() => _ReimburseFormPageState();
}

class _ReimburseFormPageState extends State<ReimburseFormPage> {
  final purposeC = TextEditingController();
  final amountC = TextEditingController();
  DateTime date = DateTime.now();
  XFile? receipt;
  String? eventId;
  String? locationId;
  bool uploading = false;

  Future<void> _pickReceipt() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (file != null) setState(() => receipt = file);
  }

  Future<void> _submit() async {
    if (eventId == null || locationId == null || purposeC.text.trim().isEmpty || amountC.text.trim().isEmpty || receipt == null) return;
    setState(() => uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref().child('reimburse/${eventId!}/${locationId!}/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final task = await ref.putFile(File(receipt!.path));
      final url = await task.ref.getDownloadURL();

      await reimburseCol().add({
        'eventId': eventId,
        'locationId': locationId,
        'date': Timestamp.fromDate(date),
        'purpose': purposeC.text.trim(),
        'amount': int.tryParse(amountC.text.replaceAll('.', '').replaceAll(',', '')) ?? 0,
        'receiptUrl': url,
        'status': 'submitted', // submitted -> approved/rejected -> paid
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reimburse diajukan')));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('Input Reimburse')),
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
          TextField(controller: purposeC, decoration: const InputDecoration(labelText: 'Keperluan')),
          const SizedBox(height: 8),
          TextField(
            controller: amountC,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nominal (angka)'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('Tanggal: ${fmt.format(date)}')),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2100));
                  if (picked != null) setState(() => date = picked);
                },
                child: const Text('Pilih Tanggal'),
              )
            ],
          ),
          const SizedBox(height: 8),
          receipt == null ? const Placeholder(fallbackHeight: 120) : Image.file(File(receipt!.path), height: 160),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: _pickReceipt, icon: const Icon(Icons.receipt), label: const Text('Foto Nota')),
          const SizedBox(height: 16),
          FilledButton(onPressed: uploading ? null : _submit, child: Text(uploading ? 'Mengirim...' : 'Ajukan Reimburse')),
        ],
      ),
    );
  }
}
