import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:omic_topup_app/services/database_service.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:crypto/crypto.dart';

class UserRepository {
  final _dbService = DatabaseService.instance;

  // Check if username or email already exists
  Future<bool> checkUserExists(String username, String email) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM Login_Data WHERE username = ? OR email = ?',
        [username, email],
      );
      return results.isNotEmpty;
    } catch (e) {
      print('Error checking user existence: $e');
      return true; // Prevent registration on error
    }
  }

  // Get user by ID
  Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM User WHERE User_ID = ?',
        [userId],
      );

      if (results.isEmpty) return null;
      return results.first.fields;
    } catch (e) {
      print('❌ Error getting user: $e');
      rethrow;
    }
  }

  // Register new user
  Future<bool> registerUser({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phoneNum,
    String? dob,
  }) async {
    try {
      // 1. Check for duplicates
      if (await checkUserExists(username, email)) {
        print('Username or Email already exists');
        return false;
      }

      // 2. Generate ID
      final userId = await getNextUserId();

      // 3. Insert into User table
      // Note: Assuming 'Profile_Picture' is nullable
      await _dbService.mysql.query(
        '''INSERT INTO User 
           (User_ID, Fname, Lname, Phone_Num, DOB, create_date) 
           VALUES (?, ?, ?, ?, ?, NOW())''',
        [userId, firstName, lastName, phoneNum, dob],
      );

      // 4. Insert into Login_Data table
      // Default role is 'Customer'
      await _dbService.mysql.query(
        '''INSERT INTO Login_Data 
           (User_ID, username, password, email, role) 
           VALUES (?, ?, ?, ?, 'Customer')''',
        [userId, username, password, email],
      );

      return true;
    } catch (e) {
      print('❌ Error registering user: $e');
      return false;
    }
  }

  Future<String> getNextUserId() async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT User_ID FROM User
           WHERE User_ID LIKE 'CUS%'
           ORDER BY User_ID DESC 
           LIMIT 1'''
      );
      
      if (results.isEmpty) {
        return 'CUS001'; // First User
      }
      
      final lastUserId = results.first['User_ID'] as String;
      final numberPart = lastUserId.substring(3); // Remove 'CUS' prefix
      final nextNumber = int.parse(numberPart) + 1;
      
      return 'CUS${nextNumber.toString().padLeft(3, '0')}'; // Format: ORD001, ORD002, etc.
    } catch (e) {
      print('❌ Error getting next User ID: $e');
      // Fallback to timestamp-based if query fails
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'CUS${timestamp.toString().substring(6)}';
    }
  }

  /// Upload user avatar to writable documents directory
  Future<String?> uploadUserAvatar(File avatarFile, String userId) async {
    try {
      // Validate that the file exists
      if (!await avatarFile.exists()) {
        print('❌ Avatar file does not exist');
        return null;
      }

      // Get file extension
      final extension = path.extension(avatarFile.path).toLowerCase();

      // Validate image format
      if (!['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(extension)) {
        print('❌ Invalid image format: $extension');
        return null;
      }

      // Generate filename using user ID and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final hash = md5
          .convert(utf8.encode('$userId$timestamp'))
          .toString()
          .substring(0, 8);
      final filename = 'avatar_${userId}_$hash$extension';

      // Get the app's writable documents directory
      final appDir = await getApplicationDocumentsDirectory();
      
      // Create avatars subdirectory
      final avatarDir = Directory(path.join(appDir.path, 'avatars'));
      
      // Ensure directory exists
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
        print('📁 Created avatars directory: ${avatarDir.path}');
      }

      // Full path for the new avatar file
      final avatarPath = path.join(avatarDir.path, filename);
      
      // Copy the file to the avatars directory
      final copiedFile = await avatarFile.copy(avatarPath);
      print('📸 Avatar file copied to: ${copiedFile.path}');

      // Store the FULL FILE PATH in database
      final fullPath = copiedFile.path;

      // Update the user's photo_path in the database
      await _dbService.mysql.query(
        'UPDATE User SET photo_path = ? WHERE User_ID = ?',
        [fullPath, userId],
      );

      print('✅ Avatar uploaded successfully for user: $userId');
      print('   File path in DB: $fullPath');

      return fullPath;
    } catch (e) {
      print('❌ Error uploading avatar: $e');
      print('   Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Helper method to get avatar asset path
  Future<String?> getAvatarAssetPath(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return null;

    try {
      // Check if file exists at the given path
      final file = File(photoPath);
      if (await file.exists()) {
        return photoPath;
      }
      
      print('⚠️ Avatar file not found at: $photoPath');
      return null;
    } catch (e) {
      print('❌ Error getting avatar asset: $e');
      return null;
    }
  }

  /// Get ImageProvider for avatar (use with CircleAvatar or Image widgets)
  Future<ImageProvider?> getAvatarImageProvider(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return null;

    try {
      final file = File(photoPath);
      if (await file.exists()) {
        return FileImage(file);
      }
      
      print('⚠️ Avatar file not found: $photoPath');
      return null;
    } catch (e) {
      print('❌ Error getting avatar image provider: $e');
      return null;
    }
  }

  /// Helper method to get avatar file from relative path (legacy support)
  @Deprecated('Use asset-based avatars instead. Call getAvatarAssetPath() to get asset paths.')
  Future<File?> getAvatarFile(String? photoPath) async {
    if (photoPath == null || photoPath.isEmpty) return null;

    try {
      // If it's an asset path, return null (assets are accessed via AssetImage)
      if (photoPath.startsWith('assets/')) {
        print('⚠️ Avatar is stored as asset: $photoPath. Use getAvatarAssetPath() instead.');
        return null;
      }
      
      print('⚠️ Avatar file path is deprecated');
      return null;
    } catch (e) {
      print('❌ Error getting avatar file: $e');
      return null;
    }
  }

  /// Helper method to delete user avatar
  Future<bool> deleteUserAvatar(String userId) async {
    try {
      final user = await getUserById(userId);
      final photoPath = user?['photo_path'];

      // Delete the file if it exists in assets directory
      if (photoPath != null && photoPath.toString().isNotEmpty) {
        try {
          final file = File(photoPath.toString());
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Deleted avatar file: ${file.path}');
          }
        } catch (e) {
          print('⚠️ Could not delete avatar file (non-critical): $e');
        }
      }

      // Clear photo_path in database
      await _dbService.mysql.query(
        'UPDATE User SET photo_path = NULL WHERE User_ID = ?',
        [userId],
      );

      print('✅ Avatar deleted for user: $userId');
      return true;
    } catch (e) {
      print('❌ Error deleting avatar: $e');
      return false;
    }
  }

  // Get user by email
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM User WHERE email = ?',
        [email],
      );

      if (results.isEmpty) return null;
      return results.first.fields;
    } catch (e) {
      print('❌ Error getting user by email: $e');
      rethrow;
    }
  }

  // Create new user
  Future<bool> createUser({
    required String userId,
    required String userType,
    required String fname,
    required String lname,
    required String phoneNum,
    required String email,
    String? dob,
    String? photoPath,
  }) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO User (User_ID, user_type, Fname, Lname, DoB, phone_num, email, photo_path, create_date)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, CURDATE())''',
        [userId, userType, fname, lname, dob, phoneNum, email, photoPath],
      );
      return true;
    } catch (e) {
      print('❌ Error creating user: $e');
      return false;
    }
  }

  // Update user
  Future<bool> updateUser({
    required String userId,
    String? fname,
    String? lname,
    String? dob,
    String? phoneNum,
    String? email,
    String? photoPath,
  }) async {
    try {
      final List<String> updates = [];
      final List<dynamic> values = [];

      if (fname != null) {
        updates.add('Fname = ?');
        values.add(fname);
      }
      if (lname != null) {
        updates.add('Lname = ?');
        values.add(lname);
      }
      if (dob != null) {
        updates.add('DoB = ?');
        values.add(dob);
      }
      if (phoneNum != null) {
        updates.add('phone_num = ?');
        values.add(phoneNum);
      }
      if (email != null) {
        updates.add('email = ?');
        values.add(email);
      }
      if (photoPath != null) {
        updates.add('photo_path = ?');
        values.add(photoPath);
      }

      if (updates.isEmpty) return false;

      values.add(userId);

      await _dbService.mysql.query(
        'UPDATE User SET ${updates.join(', ')} WHERE User_ID = ?',
        values,
      );
      return true;
    } catch (e) {
      print('❌ Error updating user: $e');
      return false;
    }
  }

  // Delete user
  Future<bool> deleteUser(String userId) async {
    try {
      await _dbService.mysql.query('DELETE FROM User WHERE User_ID = ?', [
        userId,
      ]);
      return true;
    } catch (e) {
      print('❌ Error deleting user: $e');
      return false;
    }
  }

  // Authentication methods

  // Create login credentials
  Future<bool> createLoginData({
    required String userId,
    required String username,
    required String hashedPassword,
  }) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Login_Data (User_ID, username, hashed_password)
           VALUES (?, ?, ?)''',
        [userId, username, hashedPassword],
      );
      return true;
    } catch (e) {
      print('❌ Error creating login data: $e');
      return false;
    }
  }

  // Get user by username
  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT u.*, ld.username, ld.hashed_password
           FROM User u
           INNER JOIN Login_Data ld ON u.User_ID = ld.User_ID
           WHERE ld.username = ?''',
        [username],
      );

      if (results.isEmpty) return null;
      return results.first.fields;
    } catch (e) {
      print('❌ Error getting user by username: $e');
      rethrow;
    }
  }

  // Verify login credentials
  Future<Map<String, dynamic>?> verifyLogin(
    String username,
    String password,
  ) async {
    try {
      final userData = await getUserByUsername(username);
      if (userData == null) {
        print('❌ User not found: $username');
        return null;
      }

      // Use bcrypt to verify password
      final hashedPassword = userData['hashed_password'];
      if (hashedPassword == null) {
        print('❌ No hashed password found for user');
        return null;
      }

      print('🔍 Verifying password for: $username');
      final isValid = BCrypt.checkpw(password, hashedPassword);

      if (isValid) {
        print('✅ Password verified successfully');
        return userData;
      } else {
        print('❌ Invalid password');
        return null;
      }
    } catch (e) {
      print('❌ Error verifying login: $e');
      rethrow;
    }
  }

  // Log login attempt
  Future<void> logLogin(String userId, bool success, String? ipAddress) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Login_Log (User_ID, Login_Timestamp, IP_Address, Login_status, User_Agent)
           VALUES (?, NOW(), ?, ?, ?)''',
        [
          userId,
          ipAddress ?? '127.0.0.1',
          success ? 'Success' : 'Failure',
          'Flutter App',
        ],
      );
    } catch (e) {
      print('❌ Error logging login: $e');
    }
  }

  Future<int> getUserCount() async {
  try {
    final result = await _dbService.mysql.query('SELECT COUNT(*) as count FROM User');
    return result.isNotEmpty ? result.first.fields['count'] as int? ?? 0 : 0;
  } catch (e) { return 0; }
}

Future<List<Map<String, dynamic>>> getRecentUsers({int limit = 3}) async {
  try {
    final results = await _dbService.mysql.query(
      'SELECT User_ID, Fname, Lname, create_date FROM User ORDER BY create_date DESC LIMIT ?', 
      [limit]
    );
    return results.map((row) => row.fields).toList();
  } catch (e) { return []; }
}

Future<List<Map<String, dynamic>>> getAllUsersWithLoginData() async {
  try {
    final results = await _dbService.mysql.query(
      '''SELECT u.*, ld.username 
         FROM User u 
         LEFT JOIN Login_Data ld ON u.User_ID = ld.User_ID 
         ORDER BY u.create_date DESC'''
    );
    return results.map((row) => row.fields).toList();
  } catch (e) { return []; }
}

// 1. Update Text Details
Future<bool> updateUserDetails(String userId, String fname, String lname, String phone) async {
  try {
    await _dbService.mysql.query(
      'UPDATE User SET Fname = ?, Lname = ?, Phone_Num = ? WHERE User_ID = ?',
      [fname, lname, phone, userId],
    );
    return true;
  } catch (e) {
    print('Error updating user: $e');
    return false;
  }
}

// 2. Remove Avatar (Set to NULL)
Future<bool> removeUserAvatar(String userId) async {
  try {
    // Assuming your column is named 'Profile_Picture' or similar
    await _dbService.mysql.query(
      'UPDATE User SET Profile_Picture = NULL WHERE User_ID = ?',
      [userId],
    );
    return true;
  } catch (e) {
    print('Error removing avatar: $e');
    return false;
  }
}
}