import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../repositories/user_repository.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _accessToken;
  bool _isAuthenticated = false;
  bool _isLoading = true;
  
  final AuthService _authService = AuthService();
  final UserRepository _userRepo = UserRepository();
  
  User? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get isAdmin => _user?.isAdmin ?? false;
  
  AuthProvider() {
    _loadAuthState();
  }
  
  Future<void> _loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');
      final userJson = prefs.getString('authUser');
      
      if (token != null && userJson != null) {
        _accessToken = token;
        _user = User.fromJson(jsonDecode(userJson));
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error loading auth state: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      if (username.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Please enter username and password',
        };
      }
      
      // Verify login credentials from database
      final userData = await _userRepo.verifyLogin(username, password);
      
      if (userData == null) {
        // Log failed login attempt
        return {
          'success': false,
          'message': 'Invalid username or password',
        };
      }
      
      // Create User object from database
      final user = User(
        userId: userData['User_ID']?.toString() ?? '',
        userName: userData['username']?.toString() ?? '',
        userType: userData['user_type']?.toString() ?? 'User',
        firstName: userData['Fname']?.toString() ?? '',
        lastName: userData['Lname']?.toString(),
        email: userData['email']?.toString() ?? '',
        avatar: userData['photo_path']?.toString(),
        dob: userData['DoB']?.toString(),
        phoneNum: userData['phone_num']?.toString(),
      );
      
      _user = user;
      _accessToken = 'token_${DateTime.now().millisecondsSinceEpoch}';
      _isAuthenticated = true;
      
      // Log successful login
      await _userRepo.logLogin(user.userId, true, null);
      
      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', _accessToken!);
      await prefs.setString('authUser', jsonEncode(_user!.toJson()));
      
      notifyListeners();
      
      return {
        'success': true,
        'message': 'Login successful',
      };
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'Login error: ${e.toString()}',
      };
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      if (userData['username'] == null || userData['username'].toString().isEmpty) {
        return {
          'success': false,
          'message': 'Username is required',
        };
      }
      
      if (userData['email'] == null || userData['email'].toString().isEmpty) {
        return {
          'success': false,
          'message': 'Email is required',
        };
      }
      
      if (userData['password'] == null || userData['password'].toString().isEmpty) {
        return {
          'success': false,
          'message': 'Password is required',
        };
      }
      
      // Check if username already exists
      final existingUser = await _userRepo.getUserByUsername(userData['username']);
      if (existingUser != null) {
        return {
          'success': false,
          'message': 'Username already taken',
        };
      }
      
      // Check if email already exists
      final existingEmail = await _userRepo.getUserByEmail(userData['email']);
      if (existingEmail != null) {
        return {
          'success': false,
          'message': 'Email already registered',
        };
      }
      
      // Generate user ID using repository helper (ensures correct format/length)
      final userId = await _userRepo.getNextUserId();

      // Create user in database
      final userCreated = await _userRepo.createUser(
        userId: userId,
        userType: 'Customer',
        fname: userData['firstName'] ?? '',
        lname: userData['lastName'] ?? '',
        phoneNum: userData['phoneNum'] ?? '',
        email: userData['email'],
        dob: userData['dob'],
      );
      
      if (!userCreated) {
        return {
          'success': false,
          'message': 'Failed to create user account',
        };
      }
      
      // Create login credentials
      // Hash password before storing
      final hashed = BCrypt.hashpw(userData['password'], BCrypt.gensalt());

      final loginCreated = await _userRepo.createLoginData(
        userId: userId,
        username: userData['username'],
        hashedPassword: hashed,
      );
      
      if (!loginCreated) {
        // Rollback user creation
        await _userRepo.deleteUser(userId);
        return {
          'success': false,
          'message': 'Failed to create login credentials',
        };
      }
      
      return {
        'success': true,
        'message': 'Registration successful! You can now login.',
      };
    } catch (e) {
      debugPrint('Registration error: $e');
      return {
        'success': false,
        'message': 'Registration error: ${e.toString()}',
      };
    }
  }
  
  Future<void> logout() async {
    try {
      await _authService.logout();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('accessToken');
      await prefs.remove('authUser');
      
      _user = null;
      _accessToken = null;
      _isAuthenticated = false;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }
  }
  
  void updateUser(User updatedUser) {
    _user = updatedUser;
    
    // Update SharedPreferences
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('authUser', jsonEncode(updatedUser.toJson()));
    });
    
    notifyListeners();
  }
}
