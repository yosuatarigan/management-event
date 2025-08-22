import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/firestore_refs.dart';

class ApprovalDashboard extends StatefulWidget {
  const ApprovalDashboard({super.key});

  @override
  State<ApprovalDashboard> createState() => _ApprovalDashboardState();
}

class _ApprovalDashboardState extends State<ApprovalDashboard> with TickerProviderStateMixin {
  late TabController tab;

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval'),
        actions: [IconButton(onPressed: () => AuthService.signOut(), icon: const Icon(Icons.logout))],
        bottom: TabBar(controller: tab, tabs: const [
          Tab(text: 'BA'), Tab(text: 'Evidence'), Tab(text: 'Reimburse'),
        ]),
      ),
      body: TabBarView(
        controller: tab,
        children: const [
          _BAList(),
          _EvidenceList(),
          _ReimburseList(),
        ],
      ),
    );
  }
}

class _BAList extends StatelessWidget {
  const _BAList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: baCol().where('status', isEqualTo: 'submitted').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Tidak ada BA menunggu'));
        return ListView(
          children: docs.map((d) => _ApprovalTile(
            title: d['title'] ?? '-',
            subtitle: (d['type'] ?? '-') + ' • ' + (d['content'] ?? ''),
            onApprove: (note) => d.reference.update({'status': 'approved', 'approvalNote': note}),
            onReject: (note) => d.reference.update({'status': 'rejected', 'approvalNote': note}),
          )).toList(),
        );
      },
    );
  }
}

class _EvidenceList extends StatelessWidget {
  const _EvidenceList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: evidenceCol().where('status', isEqualTo: 'submitted').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Tidak ada Evidence menunggu'));
        return ListView(
          children: docs.map((d) => _ApprovalTile(
            title: d['type'] ?? '-',
            subtitle: d['url'] ?? '',
            onApprove: (note) => d.reference.update({'status': 'approved', 'approvalNote': note}),
            onReject: (note) => d.reference.update({'status': 'rejected', 'approvalNote': note}),
          )).toList(),
        );
      },
    );
  }
}

class _ReimburseList extends StatelessWidget {
  const _ReimburseList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: reimburseCol().where('status', isEqualTo: 'submitted').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Tidak ada Reimburse menunggu'));
        return ListView(
          children: docs.map((d) => _ApprovalTile(
            title: (d['purpose'] ?? '-') + ' • Rp${d['amount'] ?? 0}',
            subtitle: (d['receiptUrl'] ?? ''),
            onApprove: (note) => d.reference.update({'status': 'approved', 'approvalNote': note}),
            onReject: (note) => d.reference.update({'status': 'rejected', 'approvalNote': note}),
          )).toList(),
        );
      },
    );
  }
}

class _ApprovalTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(String note) onApprove;
  final Future<void> Function(String note) onReject;
  const _ApprovalTile({required this.title, required this.subtitle, required this.onApprove, required this.onReject, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle, maxLines: 3, overflow: TextOverflow.ellipsis),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _openNote(context, true)),
          IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _openNote(context, false)),
        ]),
      ),
    );
  }

  Future<void> _openNote(BuildContext context, bool approve) async {
    final noteC = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(approve ? 'Catatan Approval' : 'Alasan Penolakan'),
        content: TextField(controller: noteC, decoration: const InputDecoration(hintText: 'Tulis catatan (opsional)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kirim')),
        ],
      ),
    );
    if (ok == true) {
      if (approve) {
        await onApprove(noteC.text.trim());
      } else {
        await onReject(noteC.text.trim());
      }
    }
  }
}
