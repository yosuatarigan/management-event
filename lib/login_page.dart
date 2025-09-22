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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _selectedProjectId;
  List<ProjectModel> _projects = [];

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProjects();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
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
      _showErrorDialog(
        'Proyek Belum Dipilih',
        'Silakan pilih proyek terlebih dahulu sebelum melanjutkan.',
        icon: Icons.folder_outlined,
        iconColor: Colors.orange,
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
        await FirebaseAuth.instance.signOut();
        _showErrorDialog(
          'Data User Tidak Ditemukan',
          'Akun Anda belum terdaftar dalam sistem. Silakan hubungi administrator untuk mendaftarkan akun Anda.',
          icon: Icons.person_off,
          iconColor: Colors.red,
        );
        return;
      }

      // 3. Check apakah user bisa akses proyek yang dipilih
      if (!userData.canAccessProject(_selectedProjectId)) {
        await FirebaseAuth.instance.signOut();
        
        if (userData.needsMigration) {
          _showErrorDialog(
            'Akun Perlu Diperbarui',
            'Akun Anda belum diassign ke proyek manapun. Silakan hubungi administrator untuk mengatur akses proyek Anda.',
            icon: Icons.sync_problem,
            iconColor: Colors.orange,
            actionText: 'Hubungi Admin',
            onActionPressed: () => _showContactAdminInfo(),
          );
        } else if (userData.isAdmin) {
          // Admin bisa akses semua proyek, ini seharusnya tidak terjadi
          _showErrorDialog(
            'Error Sistem',
            'Terjadi kesalahan dalam validasi akses admin. Silakan coba lagi.',
            icon: Icons.error_outline,
            iconColor: Colors.red,
          );
        } else {
          final selectedProject = _projects.firstWhere((p) => p.id == _selectedProjectId);
          
          _showErrorDialog(
            'Akses Proyek Ditolak',
            'Anda tidak memiliki akses ke proyek "${selectedProject.name}". Silakan pilih proyek yang sesuai dengan akses Anda atau hubungi administrator.',
            icon: Icons.block,
            iconColor: Colors.red,
            actionText: 'Pilih Proyek Lain',
            onActionPressed: () {
              setState(() {
                _selectedProjectId = null;
              });
            },
            secondaryActionText: 'Hubungi Admin',
            onSecondaryActionPressed: () => _showContactAdminInfo(),
          );
        }
        return;
      }

      // 4. Simpan selected project ID untuk session
      await SessionManager.setCurrentProject(_selectedProjectId!);

      // 5. Success - AuthWrapper akan handle redirect
      
    } on FirebaseAuthException catch (e) {
      String title = 'Login Gagal';
      String message;
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Email tidak terdaftar dalam sistem.';
          break;
        case 'wrong-password':
          message = 'Password yang Anda masukkan salah.';
          break;
        case 'invalid-email':
          message = 'Format email tidak valid.';
          break;
        case 'user-disabled':
          message = 'Akun Anda telah dinonaktifkan. Hubungi administrator.';
          break;
        case 'too-many-requests':
          message = 'Terlalu banyak percobaan login. Silakan coba lagi nanti.';
          break;
        default:
          message = 'Terjadi kesalahan: ${e.message}';
      }
      
      _showErrorDialog(
        title,
        message,
        icon: Icons.login,
        iconColor: Colors.red,
      );
    } catch (e) {
      _showErrorDialog(
        'Error Tidak Terduga',
        'Terjadi kesalahan yang tidak terduga: ${e.toString()}',
        icon: Icons.error,
        iconColor: Colors.red,
      );
    }

    setState(() => _isLoading = false);
  }

  void _showErrorDialog(
    String title,
    String message, {
    required IconData icon,
    required Color iconColor,
    String? actionText,
    VoidCallback? onActionPressed,
    String? secondaryActionText,
    VoidCallback? onSecondaryActionPressed,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: iconColor,
              ),
            ),
            SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                if (actionText != null) ...[
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onActionPressed?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: iconColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(actionText),
                    ),
                  ),
                ],
              ],
            ),
            if (secondaryActionText != null) ...[
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSecondaryActionPressed?.call();
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: Text(
                    secondaryActionText,
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showContactAdminInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.support_agent,
              size: 48,
              color: Colors.blue.shade600,
            ),
            SizedBox(height: 16),
            Text(
              'Hubungi Administrator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Untuk mendapatkan akses proyek atau mengatasi masalah akun, silakan hubungi administrator sistem melalui:',
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.email, color: Colors.blue.shade600, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'admin@company.com',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue.shade600, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '+62 812-3456-7890',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Mengerti'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 768;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.cyan.shade400,
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWeb ? 32 : 20,
                vertical: 20,
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWeb ? 480 : double.infinity,
                    ),
                    child: Card(
                      elevation: 24,
                      shadowColor: Colors.black.withOpacity(0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(isWeb ? 48 : 32),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white,
                              Colors.grey.shade50,
                            ],
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Logo Section
                              _buildLogoSection(isWeb),
                              
                              SizedBox(height: isWeb ? 48 : 36),
                              
                              // Project Selector
                              _buildProjectSelector(isWeb),
                              
                              SizedBox(height: 24),
                              
                              // Email Field
                              _buildEmailField(isWeb),
                              
                              SizedBox(height: 20),
                              
                              // Password Field
                              _buildPasswordField(isWeb),
                              
                              SizedBox(height: 32),
                              
                              // Login Button
                              _buildLoginButton(isWeb),
                              
                              SizedBox(height: 24),
                              
                              // Help Section
                              _buildHelpSection(isWeb),
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
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isWeb) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isWeb ? 28 : 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade600,
                Colors.cyan.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.event_note_rounded,
            size: isWeb ? 64 : 48,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 24),
        Text(
          'Event Management',
          style: TextStyle(
            fontSize: isWeb ? 32 : 28,
            fontWeight: FontWeight.bold,
            background: Paint()
              ..shader = LinearGradient(
                colors: [Colors.blue.shade700, Colors.cyan.shade600],
              ).createShader(Rect.fromLTWH(0.0, 0.0, 200.0, 70.0)),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Text(
          'Masuk dengan memilih proyek',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: isWeb ? 16 : 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProjectSelector(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedProjectId,
        decoration: InputDecoration(
          labelText: 'Pilih Proyek',
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.folder_special_rounded,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
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
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildEmailField(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _emailController,
        decoration: InputDecoration(
          labelText: 'Email',
          hintText: 'Masukkan email Anda',
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.email_rounded,
              color: Colors.green.shade600,
              size: 20,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Email diperlukan';
          if (!value!.contains('@')) return 'Format email tidak valid';
          return null;
        },
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  Widget _buildPasswordField(bool isWeb) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _passwordController,
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Masukkan password Anda',
          prefixIcon: Container(
            margin: EdgeInsets.all(12),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: Colors.orange.shade600,
              size: 20,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            icon: Icon(
              _obscurePassword ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.grey.shade500,
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Password diperlukan';
          return null;
        },
        obscureText: _obscurePassword,
      ),
    );
  }

  Widget _buildLoginButton(bool isWeb) {
    return Container(
      width: double.infinity,
      height: isWeb ? 56 : 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.cyan.shade500],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _login,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                  Icon(
                    Icons.login_rounded,
                    size: isWeb ? 24 : 20,
                    color: Colors.white,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Masuk ke Proyek',
                    style: TextStyle(
                      fontSize: isWeb ? 18 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection(bool isWeb) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_rounded,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bantuan Akun',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Belum punya akun? Hubungi admin untuk pembuatan akun baru',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}