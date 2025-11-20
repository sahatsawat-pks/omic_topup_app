import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/admin_provider.dart';
import '../config/app_theme.dart';
import '../repositories/user_repository.dart';
// import '../widgets/app_drawer.dart'; // <-- Remove Drawer import for sub-pages

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _filterType = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProvider>(context, listen: false).loadAllUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final adminProvider = Provider.of<AdminProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          // FIX 1: explicit Back Button
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        // FIX 2: Add Leading Back Button explicitly
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // This pops the current route and goes back to AdminDashboard
            Navigator.pop(context); 
          },
        ),
        title: const Text('Manage Users'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, ID or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterType,
            onSelected: (value) {
              setState(() {
                _filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Users')),
              const PopupMenuItem(value: 'Customer', child: Text('Customers')),
              const PopupMenuItem(value: 'Admin', child: Text('Admins')),
            ],
          ),
        ],
      ),
      // FIX 3: Remove the 'drawer' property here. 
      // If you keep the drawer, the back button logic above is required to override the menu icon.
      // drawer: const AppDrawer(), 
      
      body: adminProvider.isLoadingUsers
          ? const Center(child: CircularProgressIndicator())
          : _buildUsersList(adminProvider),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUserDialog(),
        child: const Icon(Icons.person_add),
      ),
    );
  }

  // ... [Keep the rest of your methods (_buildUsersList, _showEditUserDialog, etc.) exactly the same] ...
  
  Widget _buildUsersList(AdminProvider adminProvider) {
    final allUsers = adminProvider.allUsers;

    final processedUsers = allUsers.map((user) {
      // DEBUG: Print keys to console to see what the database is actually sending
      // Check your "Run" tab in VS Code/Android Studio to see the real column names
      // print('DB Keys received: ${user.keys}'); 

      final id = user['User_ID']?.toString() ?? '';
      final fname = user['Fname']?.toString() ?? '';
      final lname = user['Lname']?.toString() ?? '';
      
      // FIX: Try multiple casing variations to find the phone number
      final rawPhone = user['Phone_Num'] ?? user['phone_num'] ?? user['Phone'] ?? user['phone'];
      final phoneStr = (rawPhone == null || rawPhone.toString().isEmpty) 
          ? 'N/A' 
          : rawPhone.toString();

      final type = id.toUpperCase().startsWith('ADM') ? 'Admin' : 'Customer';

      return {
        'userId': id,
        'fname': fname, 
        'lname': lname, 
        'name': '$fname $lname'.trim(),
        'email': user['username']?.toString() ?? 'No Username',
        'phone': phoneStr, // Use the fixed phone string
        'type': type, 
        'joinDate': user['create_date']?.toString() ?? 'Unknown',
        'raw': user,
      };
    }).toList();

    var filteredUsers = processedUsers;

    if (_filterType != 'All') {
      filteredUsers = filteredUsers.where((user) => user['type'] == _filterType).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filteredUsers = filteredUsers.where((user) {
        final name = (user['name'] as String).toLowerCase();
        final email = (user['email'] as String).toLowerCase();
        final id = (user['userId'] as String).toLowerCase();
        return name.contains(_searchQuery) || 
               email.contains(_searchQuery) || 
               id.contains(_searchQuery);
      }).toList();
    }

    return RefreshIndicator(
      onRefresh: () async {
        await adminProvider.loadAllUsers();
      },
      child: filteredUsers.isEmpty
          ? const Center(child: Text('No users found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                final isAdm = user['type'] == 'Admin';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: FutureBuilder<File?>(
                      future: _loadExistingUserAvatar(user['userId'].toString()),
                      builder: (context, snapshot) {
                        final isAdm = user['type'] == 'Admin';
                        
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return CircleAvatar(
                            backgroundColor: isAdm ? Colors.red : AppTheme.accentColor,
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          return CircleAvatar(
                            backgroundColor: isAdm ? Colors.red : AppTheme.accentColor,
                            backgroundImage: FileImage(snapshot.data!),
                            child: null,
                          );
                        }

                        // Fallback to initials if no avatar
                        return CircleAvatar(
                          backgroundColor: isAdm ? Colors.red : AppTheme.accentColor,
                          child: Text(
                            (user['name'] as String).isNotEmpty 
                                ? (user['name'] as String).substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      },
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['name'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isAdm)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'ADMIN',
                              style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text('ID: ${user['userId']}', style: const TextStyle(fontSize: 12)),
                        Text('${user['email']}', style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 4),
                        // FIX: Display the phone row nicely
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              user['phone'] as String, 
                              style: TextStyle(
                                fontSize: 13, 
                                color: (user['phone'] == 'N/A') ? Colors.grey : Colors.black87
                              )
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [Icon(Icons.edit, color: Colors.blue), SizedBox(width: 8), Text('Edit Info')],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [Icon(Icons.delete, color: Colors.red), SizedBox(width: 8), Text('Delete User', style: TextStyle(color: Colors.red))],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditUserDialog(user);
                        } else if (value == 'delete') {
                          _confirmDelete(user['userId'] as String, user['name'] as String);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditUserDialog(Map<String, dynamic> user) {
    final fnameController = TextEditingController(text: user['fname']);
    final lnameController = TextEditingController(text: user['lname']);
    final phoneController = TextEditingController(text: user['phone']);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    File? selectedAvatarFile;
    File? existingAvatarFile;

    // Load existing avatar
    _loadExistingUserAvatar(user['userId']).then((file) {
      if (file != null) {
        existingAvatarFile = file;
      }
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('Edit ${user['name']}'),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar Section
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          // Avatar Preview
                          if (selectedAvatarFile != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: FileImage(selectedAvatarFile!),
                            )
                          else if (existingAvatarFile != null)
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: FileImage(existingAvatarFile!),
                            )
                          else
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: AppTheme.accentColor,
                              child: const Icon(Icons.person, size: 40, color: Colors.white),
                            ),
                          const SizedBox(height: 12),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isLoading ? null : () async {
                                  final ImagePicker picker = ImagePicker();
                                  final XFile? image = await picker.pickImage(
                                    source: ImageSource.gallery,
                                    maxWidth: 512,
                                    maxHeight: 512,
                                    imageQuality: 85,
                                  );
                                  if (image != null) {
                                    setState(() {
                                      selectedAvatarFile = File(image.path);
                                    });
                                  }
                                },
                                icon: const Icon(Icons.upload, size: 16),
                                label: const Text('Upload'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: (isLoading || (selectedAvatarFile == null && existingAvatarFile == null)) ? null : () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Remove Avatar"),
                                      content: const Text("Are you sure you want to remove this user's profile image?"),
                                      actions: [
                                        TextButton(onPressed: ()=>Navigator.pop(ctx, false), child: const Text("Cancel")),
                                        TextButton(onPressed: ()=>Navigator.pop(ctx, true), child: const Text("Remove")),
                                      ],
                                    )
                                  );

                                  if (confirm == true) {
                                    setState(() => isLoading = true);
                                    final success = await Provider.of<AdminProvider>(context, listen: false)
                                        .removeAvatar(user['userId']);
                                    setState(() {
                                      isLoading = false;
                                      selectedAvatarFile = null;
                                      existingAvatarFile = null;
                                    });
                                    
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Avatar removed")),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.delete, size: 16),
                                label: const Text('Remove'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: fnameController,
                      decoration: const InputDecoration(labelText: 'First Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: lnameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  if (formKey.currentState!.validate()) {
                    setState(() => isLoading = true);
                    
                    // Upload avatar if a new one was selected
                    if (selectedAvatarFile != null) {
                      await _uploadUserAvatar(selectedAvatarFile!, user['userId']);
                    }
                    
                    final success = await Provider.of<AdminProvider>(context, listen: false).editUser(
                      user['userId'],
                      fnameController.text.trim(),
                      lnameController.text.trim(),
                      phoneController.text.trim(),
                    );

                    if (mounted) {
                      Navigator.pop(context);
                      if (success) {
                        _showSuccess('User updated successfully');
                        // Reload users to show updated avatar
                        Provider.of<AdminProvider>(context, listen: false).loadAllUsers();
                      } else {
                        _showError('Failed to update user');
                      }
                    }
                  }
                },
                child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : const Text('Save Changes'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New User'),
        content: const Text('To add a user, please use the Sign Up screen in the main app flow.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _confirmDelete(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Permanently delete $userName (ID: $userId)?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<AdminProvider>(context, listen: false)
                  .deleteUser(userId);
                  
              if (success && mounted) {
                _showSuccess('User deleted');
              } else if (mounted) {
                _showError('Failed to delete user');
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Load existing avatar file for user
  Future<File?> _loadExistingUserAvatar(String userId) async {
    try {
      final userRepo = UserRepository();
      // Get user from database to get photo_path
      final user = await userRepo.getUserById(userId);
      if (user != null && user['photo_path'] != null) {
        final photoPath = user['photo_path'].toString();
        if (photoPath.isNotEmpty) {
          final file = File(photoPath);
          if (await file.exists()) {
            return file;
          }
        }
      }
      return null;
    } catch (e) {
      print('Error loading avatar: $e');
      return null;
    }
  }

  /// Upload avatar for user from admin panel
  Future<bool> _uploadUserAvatar(File avatarFile, String userId) async {
    try {
      final userRepo = UserRepository();
      final result = await userRepo.uploadUserAvatar(avatarFile, userId);
      return result != null;
    } catch (e) {
      print('Error uploading avatar: $e');
      return false;
    }
  }
}