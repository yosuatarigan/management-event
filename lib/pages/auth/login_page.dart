import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();
  bool loading = false;
  String? error;

  Future<void> _submit() async {
    setState(() { loading = true; error = null; });
    try {
      await AuthService.signIn(emailC.text.trim(), passC.text);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.event_note, size: 48, color: theme.colorScheme.primary),
                const SizedBox(height: 12),
                Text('Manajemen Acara', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: emailC, decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
                const SizedBox(height: 8),
                TextField(controller: passC, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)), obscureText: true),
                const SizedBox(height: 12),
                if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: loading ? null : _submit,
                    icon: loading ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login),
                    label: Text(loading ? 'Masuk...' : 'Masuk'),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
