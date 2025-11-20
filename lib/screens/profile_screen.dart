import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../repositories/user_repository.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  
  DateTime? _selectedDate;
  File? _avatarFile;
  File? _currentAvatarFile; // For displaying existing avatar
  bool _isUpdating = false;
  bool _isLoadingAvatar = true;
  
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdatingPassword = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phoneNum ?? '');
    
    if (user?.dob != null && user!.dob!.isNotEmpty) {
      try {
        _selectedDate = DateTime.parse(user.dob!);
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }
    
    // Load existing avatar
    _loadExistingAvatar();
  }

  Future<void> _loadExistingAvatar() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user?.avatar != null && user!.avatar!.isNotEmpty) {
      try {
        // Check if avatar file exists
        final avatarFile = File(user.avatar!);
        if (await avatarFile.exists()) {
          if (mounted) {
            setState(() {
              _currentAvatarFile = avatarFile;
              _isLoadingAvatar = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoadingAvatar = false;
            });
          }
        }
      } catch (e) {
        debugPrint('Error loading avatar: $e');
        if (mounted) {
          setState(() {
            _isLoadingAvatar = false;
          });
        }
      }
    } else {
      setState(() {
        _isLoadingAvatar = false;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    
    if (image != null) {
      setState(() {
        _avatarFile = File(image.path);
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUpdating = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.user;
      
      if (currentUser == null) {
        throw Exception('User not logged in');
      }
      
      final userRepo = UserRepository();
      String? photoPath = currentUser.avatar; // Keep existing path by default
      
      // Only upload new avatar if user selected a new image
      if (_avatarFile != null) {
        final uploadedPath = await userRepo.uploadUserAvatar(_avatarFile!, currentUser.userId);
        if (uploadedPath != null) {
          photoPath = uploadedPath;
          print('✅ Avatar uploaded: $uploadedPath');
        } else {
          print('⚠️ Avatar upload failed, keeping existing avatar');
        }
      }

      // Update user in database
      final success = await userRepo.updateUser(
        userId: currentUser.userId,
        fname: _firstNameController.text.trim(),
        lname: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNum: _phoneController.text.trim(),
        dob: _selectedDate?.toIso8601String().split('T')[0],
        photoPath: photoPath,
      );
      
      if (!success) {
        throw Exception('Failed to update profile');
      }
      
      // Update local user object (including avatar/photo path)
      final updatedUser = currentUser.copyWith(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNum: _phoneController.text.trim(),
        dob: _selectedDate?.toIso8601String().split('T')[0],
        avatar: photoPath,
      );
      
      authProvider.updateUser(updatedUser);

      // Update current avatar display
      if (_avatarFile != null) {
        setState(() {
          _currentAvatarFile = _avatarFile;
          _avatarFile = null; // Clear the new selection
        });
      }

      setState(() {
        _isUpdating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
    });

    // Demo mode: Simulate password update
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _isUpdatingPassword = false;
    });

    if (!mounted) return;

    Navigator.of(context).pop();
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password updated successfully (Demo Mode)'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildAvatarWidget() {
    // Show loading indicator while loading existing avatar
    if (_isLoadingAvatar) {
      return const CircleAvatar(
        radius: 60,
        backgroundColor: AppTheme.accentColor,
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    ImageProvider? imageProvider;
    
    // Priority: newly selected image > existing avatar file > placeholder
    if (_avatarFile != null) {
      // User just picked a new image from gallery
      imageProvider = FileImage(_avatarFile!);
    } else if (_currentAvatarFile != null) {
      // Display existing avatar from filesystem
      imageProvider = FileImage(_currentAvatarFile!);
    }

    return CircleAvatar(
      radius: 60,
      backgroundColor: AppTheme.accentColor,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? const Icon(Icons.person, size: 60, color: Colors.white)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: Text('Please login to view profile')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      drawer: const AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar Section
              Center(
                child: Stack(
                  children: [
                    _buildAvatarWidget(),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor,
                        radius: 20,
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                          onPressed: _pickImage,
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // First Name
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Last Name
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              
              // Date of Birth
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _selectedDate == null
                        ? 'Select date'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Update Profile Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isUpdating ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isUpdating
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Update Profile'),
                ),
              ),
              const SizedBox(height: 16),
              
              // Change Password Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _buildPasswordDialog(),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Change Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordDialog() {
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            _currentPasswordController.clear();
            _newPasswordController.clear();
            _confirmPasswordController.clear();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isUpdatingPassword ? null : _updatePassword,
          child: _isUpdatingPassword
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}