import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/admin_user_service.dart';
import '../../../services/firestore_refs.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final nameC = TextEditingController();
  final emailC = TextEditingController();
  final passC = TextEditingController();
  String role = 'coordinator';
  bool creating = false;

  Future<void> _createUser() async {
    if (emailC.text.trim().isEmpty || passC.text.isEmpty) return;
    setState(() => creating = true);
    try {
      final uid = await AdminUserService.createUserWithPassword(
        email: emailC.text.trim(),
        password: passC.text,
        displayName: nameC.text.trim(),
        role: role,
      );
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Akun dibuat'),
          content: SelectableText(
            'User berhasil dibuat.\nUID: $uid\n\nSilakan informasikan email & password ke user, atau kirim email reset password dari daftar akun.',
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
        ),
      );
      nameC.clear();
      emailC.clear();
      passC.clear();
      setState(() => role = 'coordinator');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal buat akun: $e')));
    } finally {
      if (mounted) setState(() => creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Akun'),
        actions: [IconButton(onPressed: () => AuthService.signOut(), icon: const Icon(Icons.logout))],
      ),
      body: Column(
        children: [
          // Form buat akun baru
          Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Buat Akun Baru', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nameC,
                          decoration: const InputDecoration(labelText: 'Nama (opsional)', prefixIcon: Icon(Icons.badge)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: emailC,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: passC,
                          decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                          obscureText: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: role,
                          decoration: const InputDecoration(labelText: 'Role'),
                          items: const [
                            DropdownMenuItem(value: 'coordinator', child: Text('coordinator')),
                            DropdownMenuItem(value: 'approver', child: Text('approver')),
                            DropdownMenuItem(value: 'staff', child: Text('staff')),
                            DropdownMenuItem(value: 'admin', child: Text('admin')),
                          ],
                          onChanged: (v) => setState(() => role = v ?? 'coordinator'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: creating ? null : _createUser,
                      icon: creating
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.person_add_alt_1),
                      label: Text(creating ? 'Membuat...' : 'Buat Akun'),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          // Daftar akun
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: usersCol().orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('Belum ada akun'));

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final d = docs[i];
                    final uid = d.id;
                    final email = d['email'] ?? '';
                    final displayName = d['displayName'] ?? '';
                    final role = d['role'] ?? 'coordinator';
                    final disabled = d['disabled'] == true;

                    return Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            (displayName.isNotEmpty ? displayName[0] : (email.isNotEmpty ? email[0] : '?')).toUpperCase(),
                          ),
                        ),
                        title: Text(displayName.isNotEmpty ? displayName : email),
                        subtitle: Wrap(
                          spacing: 8,
                          runSpacing: -8,
                          children: [
                            _Badge(text: email, icon: Icons.email_outlined),
                            _RoleBadge(role: role),
                            _StatusBadge(disabled: disabled),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          onSelected: (val) async {
                            try {
                              if (val.startsWith('role:')) {
                                final newRole = val.split(':')[1];
                                await AdminUserService.updateUserRole(uid: uid, role: newRole);
                              } else if (val == 'disable') {
                                await AdminUserService.setUserDisabled(uid: uid, disabled: true);
                              } else if (val == 'enable') {
                                await AdminUserService.setUserDisabled(uid: uid, disabled: false);
                              } else if (val == 'reset') {
                                await AdminUserService.sendPasswordResetEmail(email);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Link reset password telah dikirim ke $email')),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e')));
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'role:coordinator', child: Text('Ubah Role → coordinator')),
                            const PopupMenuItem(value: 'role:approver', child: Text('Ubah Role → approver')),
                            const PopupMenuItem(value: 'role:staff', child: Text('Ubah Role → staff')),
                            const PopupMenuItem(value: 'role:admin', child: Text('Ubah Role → admin')),
                            const PopupMenuDivider(),
                            if (!disabled) const PopupMenuItem(value: 'disable', child: Text('Nonaktifkan Akun')),
                            if (disabled) const PopupMenuItem(value: 'enable', child: Text('Aktifkan Akun')),
                            const PopupMenuItem(value: 'reset', child: Text('Kirim Email Reset Password')),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Badge({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(text, overflow: TextOverflow.ellipsis),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    ColorScheme cs = Theme.of(context).colorScheme;
    final map = {
      'admin': cs.primary,
      'approver': cs.tertiary,
      'coordinator': cs.secondary,
      'staff': cs.outline,
    };
    return Chip(
      label: Text(role),
      backgroundColor: map[role]?.withOpacity(0.15),
      side: BorderSide(color: map[role] ?? cs.outline),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool disabled;
  const _StatusBadge({required this.disabled});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(disabled ? 'Nonaktif' : 'Aktif'),
      avatar: Icon(disabled ? Icons.block : Icons.check_circle, size: 16),
      backgroundColor: (disabled ? Colors.red : Colors.green).withOpacity(0.15),
      side: BorderSide(color: disabled ? Colors.red : Colors.green),
    );
  }
}
