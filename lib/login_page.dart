import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_service.dart';
import 'user_model.dart';
import 'project_service.dart';
import 'project_model.dart';
import 'session_manager.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _selectedProjectId;
  List<ProjectModel> _projects = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ProjectService.getProjects().first;
      setState(() => _projects = projects);
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pilih proyek terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Login ke Firebase Auth
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 2. Get user data dari Firestore
      final userData = await UserService.getUserById(credential.user!.uid);
      
      if (userData == null) {
        throw Exception('Data user tidak ditemukan');
      }

      // 3. Check apakah user bisa akses proyek yang dipilih
      if (!userData.canAccessProject(_selectedProjectId)) {
        // Logout jika tidak bisa akses
        await FirebaseAuth.instance.signOut();
        
        String message;
        if (userData.needsMigration) {
          message = 'Akun Anda belum diassign ke proyek manapun. Hubungi admin.';
        } else {
          message = 'Anda tidak memiliki akses ke proyek ini';
        }
        
        throw Exception(message);
      }

      // 4. Simpan selected project ID untuk session menggunakan SessionManager
      await SessionManager.setCurrentProject(_selectedProjectId!);

      // 5. Success - AuthWrapper akan handle redirect
      // Tidak perlu manual navigation, AuthWrapper akan detect login state change
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWeb = screenWidth > 600;
    final cardWidth = isWeb ? 450.0 : screenWidth * 0.9;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 32 : 16,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: cardWidth),
                child: Card(
                  elevation: isWeb ? 16 : 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWeb ? 24 : 20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(isWeb ? 48 : 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo/Icon
                          Container(
                            padding: EdgeInsets.all(isWeb ? 24 : 20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue.shade100, Colors.blue.shade50],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.event_note,
                              size: isWeb ? 80 : 64,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          
                          SizedBox(height: isWeb ? 32 : 24),
                          
                          // Title
                          Text(
                            'Event Management',
                            style: TextStyle(
                              fontSize: isWeb ? 32 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: 8),
                          
                          Text(
                            'Pilih proyek dan masuk ke akun Anda',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isWeb ? 16 : 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          SizedBox(height: isWeb ? 48 : 36),
                          
                          // Project Selector
                          DropdownButtonFormField<String>(
                            value: _selectedProjectId,
                            decoration: InputDecoration(
                              labelText: 'Pilih Proyek',
                              prefixIcon: Icon(Icons.folder_special),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            items: _projects.map((project) {
                              return DropdownMenuItem<String>(
                                value: project.id,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      project.name,
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      project.description,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedProjectId = value),
                            validator: (value) => value == null ? 'Pilih proyek' : null,
                            isExpanded: true,
                          ),
                          
                          SizedBox(height: isWeb ? 24 : 20),
                          
                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Email diperlukan';
                              if (!value!.contains('@')) return 'Email tidak valid';
                              return null;
                            },
                            keyboardType: TextInputType.emailAddress,
                          ),
                          
                          SizedBox(height: isWeb ? 24 : 20),
                          
                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(Icons.lock_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Password diperlukan';
                              return null;
                            },
                            obscureText: true,
                          ),
                          
                          SizedBox(height: isWeb ? 40 : 32),
                          
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: isWeb ? 56 : 52,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 3,
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.login, size: isWeb ? 24 : 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Masuk ke Proyek',
                                          style: TextStyle(
                                            fontSize: isWeb ? 18 : 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                          
                          SizedBox(height: isWeb ? 24 : 20),
                          
                          // Help Text
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue.shade600,
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Belum punya akun? Hubungi admin untuk pembuatan akun baru',
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}