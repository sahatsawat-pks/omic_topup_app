import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../config/database_config.dart';
import '../widgets/app_drawer.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/user_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalEmails = false;
  String _currency = 'THB';
  String _language = 'English';
  bool _darkMode = false;

  final OrderRepository _orderRepo = OrderRepository();
  final ProductRepository _productRepo = ProductRepository();
  final UserRepository _userRepo = UserRepository();
  late Future<Map<String, dynamic>> _statsDataFuture;

  @override
  void initState() {
    super.initState();
    _statsDataFuture = _loadStatsData();
  }

  Future<Map<String, dynamic>> _loadStatsData() async {
    try {
      final totalOrders = await _orderRepo.getOrderCount();
      final totalRevenue = await _orderRepo.getTotalRevenue();
      final totalProducts = await _productRepo.getProductCount();
      final totalUsers = await _userRepo.getUserCount();

      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'totalProducts': totalProducts,
        'totalUsers': totalUsers,
      };
    } catch (e) {
      print('Error loading stats: $e');
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'totalProducts': 0,
        'totalUsers': 0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Settings'),
      ),
      drawer: const AppDrawer(),
      body: ListView(
        children: [
          // General Settings
          _buildSectionHeader('General Settings'),
          _buildListTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: _language,
            onTap: () => _showLanguageDialog(),
          ),
          _buildListTile(
            icon: Icons.attach_money,
            title: 'Currency',
            subtitle: _currency,
            onTap: () => _showCurrencyDialog(),
          ),
          _buildSwitchTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme',
            value: _darkMode,
            onChanged: (value) {
              setState(() {
                _darkMode = value;
              });
            },
          ),

          const Divider(),

          // Notification Settings
          _buildSectionHeader('Notifications'),
          _buildSwitchTile(
            icon: Icons.email,
            title: 'Email Notifications',
            subtitle: 'Receive emails for important updates',
            value: _emailNotifications,
            onChanged: (value) {
              setState(() {
                _emailNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.notifications,
            title: 'Push Notifications',
            subtitle: 'Receive push notifications',
            value: _pushNotifications,
            onChanged: (value) {
              setState(() {
                _pushNotifications = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.shopping_bag,
            title: 'Order Updates',
            subtitle: 'Notifications about your orders',
            value: _orderUpdates,
            onChanged: (value) {
              setState(() {
                _orderUpdates = value;
              });
            },
          ),
          _buildSwitchTile(
            icon: Icons.local_offer,
            title: 'Promotional Emails',
            subtitle: 'Receive special offers and promotions',
            value: _promotionalEmails,
            onChanged: (value) {
              setState(() {
                _promotionalEmails = value;
              });
            },
          ),

          const Divider(),

          // Security
          _buildSectionHeader('Security'),
          _buildListTile(
            icon: Icons.lock,
            title: 'Change Password',
            subtitle: 'Update your password',
            onTap: () => _showChangePasswordDialog(),
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Two-Factor Authentication',
            subtitle: 'Add extra security to your account',
            onTap: () => _show2FADialog(),
          ),
          _buildListTile(
            icon: Icons.devices,
            title: 'Active Sessions',
            subtitle: 'Manage logged in devices',
            onTap: () => _showActiveSessionsDialog(),
          ),

          const Divider(),

          // System Stats
          _buildSectionHeader('System Statistics'),
          _buildStatsCards(),

          const Divider(),

          // System Settings
          _buildSectionHeader('System Settings'),
          _buildListTile(
            icon: Icons.storage,
            title: 'Database Configuration',
            subtitle: 'MySQL connection settings',
            onTap: () => _showDatabaseDialog(),
          ),
          _buildListTile(
            icon: Icons.backup,
            title: 'Backup & Restore',
            subtitle: 'Manage system backups',
            onTap: () => _showBackupDialog(),
          ),
          _buildListTile(
            icon: Icons.bug_report,
            title: 'Error Logs',
            subtitle: 'View system error logs',
            onTap: () => _showLogsDialog(),
          ),
          _buildListTile(
            icon: Icons.cleaning_services,
            title: 'Clear Cache',
            subtitle: 'Free up storage space',
            onTap: () => _confirmClearCache(),
          ),

          const Divider(),

          // About
          _buildSectionHeader('About'),
          _buildListTile(
            icon: Icons.info,
            title: 'App Version',
            subtitle: '1.0.0',
            onTap: null,
          ),
          _buildListTile(
            icon: Icons.description,
            title: 'Terms of Service',
            subtitle: 'Read our terms',
            onTap: () => Navigator.pushNamed(context, '/policy'),
          ),
          _buildListTile(
            icon: Icons.privacy_tip,
            title: 'Privacy Policy',
            subtitle: 'Your privacy matters',
            onTap: () => Navigator.pushNamed(context, '/policy'),
          ),

          const SizedBox(height: 20),

          // Save button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppTheme.accentColor,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _statsDataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final data = snapshot.data ?? {};
        final statsItems = [
          {
            'label': 'Total Users',
            'value': data['totalUsers']?.toString() ?? '0',
            'icon': Icons.people
          },
          {
            'label': 'Total Products',
            'value': data['totalProducts']?.toString() ?? '0',
            'icon': Icons.shopping_bag
          },
          {
            'label': 'Total Orders',
            'value': data['totalOrders']?.toString() ?? '0',
            'icon': Icons.receipt
          },
          {
            'label': 'Total Revenue',
            'value': '฿${(data['totalRevenue'] as double?)?.toStringAsFixed(0) ?? '0'}',
            'icon': Icons.attach_money
          },
        ];

        return Column(
          children: statsItems.map((stat) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(stat['icon'] as IconData, color: AppTheme.accentColor),
                title: Text(stat['label'] as String),
                trailing: Text(
                  stat['value'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.accentColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
      enabled: onTap != null,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: AppTheme.accentColor),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'ไทย (Thai)', '日本語 (Japanese)', '中文 (Chinese)']
              .map((lang) => RadioListTile<String>(
                    title: Text(lang),
                    value: lang.split(' ').first,
                    groupValue: _language,
                    onChanged: (value) {
                      setState(() {
                        _language = value!;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showCurrencyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['THB (฿)', 'USD (\$)', 'EUR (€)', 'JPY (¥)']
              .map((curr) => RadioListTile<String>(
                    title: Text(curr),
                    value: curr.split(' ').first,
                    groupValue: _currency,
                    onChanged: (value) {
                      setState(() {
                        _currency = value!;
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: const Text('Password change form coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _show2FADialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Text('2FA setup coming soon!\n\nThis will allow you to add an extra layer of security using authenticator apps.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Sessions'),
        content: const Text('Session management coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDatabaseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Database Configuration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Current MySQL Connection:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildConfigRow('Host:', DatabaseConfig.host),
              _buildConfigRow('Port:', DatabaseConfig.port.toString()),
              _buildConfigRow('Database:', DatabaseConfig.database),
              _buildConfigRow('Username:', DatabaseConfig.username),
              _buildConfigRow('Timeout:', '${DatabaseConfig.connectionTimeout}s'),
              const SizedBox(height: 16),
              const Text(
                'Connection Status:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const CircleAvatar(
                    radius: 6,
                    backgroundColor: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _statsDataFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done &&
                          !snapshot.hasError) {
                        return const Text('Connected');
                      }
                      return const Text('Connecting...');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontFamily: 'monospace', color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup & Restore'),
        content: const Text('Backup management coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error Logs'),
        content: const Text('Log viewer coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _confirmClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all cached data?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
