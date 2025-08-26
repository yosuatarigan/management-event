import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_model.dart';

class HomePage extends StatelessWidget {
  final UserRole? userRole;

  const HomePage({Key? key, this.userRole}) : super(key: key);

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out')),
      );
    }
  }

  String _getRoleDisplayName(UserRole? role) {
    if (role == null) return 'User';
    
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.koordinator:
        return 'Koordinator';
      case UserRole.approver:
        return 'Approver';
      case UserRole.bawahan:
        return 'Bawahan';
    }
  }

  Color _getRoleColor(UserRole? role) {
    if (role == null) return Colors.grey.shade600;
    
    switch (role) {
      case UserRole.admin:
        return Colors.red.shade600;
      case UserRole.koordinator:
        return Colors.blue.shade600;
      case UserRole.approver:
        return Colors.green.shade600;
      case UserRole.bawahan:
        return Colors.grey.shade600;
    }
  }

  List<Widget> _buildRoleSpecificFeatures(UserRole? role) {
    if (role == null) return [];

    switch (role) {
      case UserRole.admin:
        return [
          _buildFeatureCard(
            icon: Icons.admin_panel_settings,
            title: 'Admin Panel',
            subtitle: 'Full system access',
            color: Colors.red,
          ),
        ];
      
      case UserRole.koordinator:
        return [
          _buildFeatureCard(
            icon: Icons.people_alt,
            title: 'Team Coordination',
            subtitle: 'Manage team activities',
            color: Colors.blue,
          ),
          _buildFeatureCard(
            icon: Icons.assignment,
            title: 'Task Management',
            subtitle: 'Coordinate team tasks',
            color: Colors.orange,
          ),
        ];
      
      case UserRole.approver:
        return [
          _buildFeatureCard(
            icon: Icons.approval,
            title: 'Approval Requests',
            subtitle: 'Review and approve',
            color: Colors.green,
          ),
          _buildFeatureCard(
            icon: Icons.verified,
            title: 'Verification',
            subtitle: 'Verify documents',
            color: Colors.teal,
          ),
        ];
      
      case UserRole.bawahan:
        return [
          _buildFeatureCard(
            icon: Icons.task_alt,
            title: 'My Tasks',
            subtitle: 'View assigned tasks',
            color: Colors.purple,
          ),
          _buildFeatureCard(
            icon: Icons.schedule,
            title: 'Schedule',
            subtitle: 'Check your schedule',
            color: Colors.indigo,
          ),
        ];
    }
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _signOut(context),
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.waving_hand,
                            size: 32,
                            color: Colors.orange.shade400,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  'Welcome back',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      if (user?.email != null) ...[
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user!.email!,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],

                      if (userRole != null) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(userRole).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.badge,
                                size: 14,
                                color: _getRoleColor(userRole),
                              ),
                              SizedBox(width: 4),
                              Text(
                                _getRoleDisplayName(userRole),
                                style: TextStyle(
                                  color: _getRoleColor(userRole),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Role-specific features
                if (userRole != null) ...[
                  Text(
                    'Available Features',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 16),
                  ..._buildRoleSpecificFeatures(userRole),
                ] else ...[
                  // Default content for users without role
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your account is being set up',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please contact your administrator for account activation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}