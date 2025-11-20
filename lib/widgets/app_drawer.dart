import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final user = authProvider.user;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar - display from assets if available
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipOval(
                    child: _buildAvatarImage(user?.avatar),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isAuthenticated && user != null
                      ? 'Hello, ${user.firstName}'
                      : 'OMiC Games',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isAuthenticated && user != null)
                  Text(
                    user.email,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),

          // Public Navigation Items
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),

          if (isAuthenticated) ...[
            // Authenticated User Items
            ListTile(
              leading: const Icon(Icons.games),
              title: const Text('Games'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/user/games');
              },
            ),
            ListTile(
              leading: const Icon(Icons.card_membership),
              title: const Text('Membership'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/user/membership');
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/user/history');
              },
            ),
            const Divider(),
          ],

          // Common Items
          ListTile(
            leading: const Icon(Icons.policy),
            title: const Text('Policy'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/policy');
            },
          ),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text('Support'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/support');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About Us'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushNamed('/about');
            },
          ),

          const Divider(),

          // Admin Section (if admin)
          if (isAuthenticated && authProvider.isAdmin) ...[
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/admin/dashboard');
              },
            ),
            const Divider(),
          ],

          // Auth Actions
          if (isAuthenticated)
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/user/profile');
              },
            ),

          if (!isAuthenticated)
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Login'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/login');
              },
            )
          else
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                Navigator.of(context).pop();
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
        ],
      ),
    );
  }

  // Helper method to build avatar image widget
  Widget _buildAvatarImage(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      // No avatar - show placeholder
      return Image.asset(
        'assets/images/placeholder.png',
        fit: BoxFit.cover,
        width: 60,
        height: 60,
      );
    }

    // Avatar path should be a file path (e.g., "assets/images/avatars/avatar_ADM001_3e27fe07.webp")
    // We need to check if file exists
    final avatarFile = File(avatarPath);
    
    return FutureBuilder<bool>(
      future: avatarFile.exists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          // File exists - display it
          return Image.file(
            avatarFile,
            fit: BoxFit.cover,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset(
                'assets/images/placeholder.png',
                fit: BoxFit.cover,
                width: 60,
                height: 60,
              );
            },
          );
        }

        // File doesn't exist - show placeholder
        return Image.asset(
          'assets/images/placeholder.png',
          fit: BoxFit.cover,
          width: 60,
          height: 60,
        );
      },
    );
  }
}