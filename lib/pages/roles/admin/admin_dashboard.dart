import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:management_event/services/sample_users.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_refs.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final eventNameC = TextEditingController();
  final locNameC = TextEditingController();
  final locAddressC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => AuthService.signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Master Data', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              await SampleUsers.generateAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Akun sample berhasil dibuat (lihat console log)',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Generate Akun Sample'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tambah Acara'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: eventNameC,
                    decoration: const InputDecoration(labelText: 'Nama Acara'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      if (eventNameC.text.trim().isEmpty) return;
                      await eventsCol().add({
                        'name': eventNameC.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                        'status': 'active',
                      });
                      eventNameC.clear();
                    },
                    child: const Text('Simpan Acara'),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream:
                        eventsCol()
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final docs = snapshot.data!.docs;
                      return Column(
                        children:
                            docs
                                .map(
                                  (d) => ListTile(
                                    title: Text(d['name'] ?? ''),
                                    subtitle: Text(
                                      'status: ${d['status'] ?? '-'}',
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tambah Lokasi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locNameC,
                    decoration: const InputDecoration(labelText: 'Nama Lokasi'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: locAddressC,
                    decoration: const InputDecoration(
                      labelText: 'Alamat (opsional)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      if (locNameC.text.trim().isEmpty) return;
                      await locationsCol().add({
                        'name': locNameC.text.trim(),
                        'address': locAddressC.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      locNameC.clear();
                      locAddressC.clear();
                    },
                    child: const Text('Simpan Lokasi'),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder(
                    stream:
                        locationsCol()
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final docs = snapshot.data!.docs;
                      return Column(
                        children:
                            docs
                                .map(
                                  (d) => ListTile(
                                    title: Text(d['name'] ?? ''),
                                    subtitle: Text(d['address'] ?? ''),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manajemen User & Role',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Card(
            child: StreamBuilder(
              stream:
                  usersCol().orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: LinearProgressIndicator(),
                  );
                }
                final docs = snapshot.data!.docs;
                return Column(
                  children:
                      docs.map((d) {
                        final role = d['role'] ?? 'coordinator';
                        return ListTile(
                          title: Text(d['email'] ?? ''),
                          subtitle: Text('role: $role'),
                          trailing: DropdownButton<String>(
                            value: role,
                            items: const [
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('admin'),
                              ),
                              DropdownMenuItem(
                                value: 'coordinator',
                                child: Text('coordinator'),
                              ),
                              DropdownMenuItem(
                                value: 'approver',
                                child: Text('approver'),
                              ),
                              DropdownMenuItem(
                                value: 'staff',
                                child: Text('staff'),
                              ),
                            ],
                            onChanged: (val) async {
                              if (val != null)
                                await AuthService.updateRole(d.id, val);
                            },
                          ),
                        );
                      }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
