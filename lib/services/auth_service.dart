import 'dart:convert';
import '../models/user.dart';
import '../models/product.dart';
import '../config/api_constants.dart';
import 'api_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await ApiService.post(
        ApiConstants.login,
        {
          'username': username,
          'password': password,
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['accessToken'] != null && data['user'] != null) {
          // Save token
          await ApiService.saveToken(data['accessToken']);
          
          // Return user and token
          return {
            'success': true,
            'user': User.fromJson(data['user']),
            'accessToken': data['accessToken'],
          };
        } else {
          return {
            'success': false,
            'message': 'Invalid response from server',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final response = await ApiService.post(
        ApiConstants.register,
        userData,
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  Future<void> logout() async {
    await ApiService.deleteToken();
  }
}

class ProductService {
  Future<List<Product>> getProducts() async {
    try {
      final response = await ApiService.get(ApiConstants.products);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Error fetching products: ${e.toString()}');
    }
  }
  
  Future<Product> getProductById(String productId) async {
    try {
      final response = await ApiService.get('${ApiConstants.productById}$productId');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Product.fromJson(data);
      } else {
        throw Exception('Failed to load product');
      }
    } catch (e) {
      throw Exception('Error fetching product: ${e.toString()}');
    }
  }
}

class ProfileService {
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await ApiService.put(
        ApiConstants.updateProfile,
        profileData,
        requiresAuth: true,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'user': User.fromJson(data['user']),
          'message': data['message'] ?? 'Profile updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
  
  Future<Map<String, dynamic>> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response = await ApiService.put(
        ApiConstants.updatePassword,
        {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        },
        requiresAuth: true,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Password updated successfully',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Password update failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connection error: ${e.toString()}',
      };
    }
  }
}
