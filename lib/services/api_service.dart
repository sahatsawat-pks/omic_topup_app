import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_constants.dart';

class ApiService {
  static const storage = FlutterSecureStorage();
  
  static Future<String?> getToken() async {
    return await storage.read(key: ApiConstants.accessTokenKey);
  }
  
  static Future<void> saveToken(String token) async {
    await storage.write(key: ApiConstants.accessTokenKey, value: token);
  }
  
  static Future<void> deleteToken() async {
    await storage.delete(key: ApiConstants.accessTokenKey);
  }
  
  static Map<String, String> _getHeaders({bool includeAuth = false, String? token}) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (includeAuth && token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  static Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    return await http.get(
      url,
      headers: _getHeaders(includeAuth: requiresAuth, token: token),
    ).timeout(
      const Duration(seconds: ApiConstants.connectionTimeout),
    );
  }
  
  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    return await http.post(
      url,
      headers: _getHeaders(includeAuth: requiresAuth, token: token),
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: ApiConstants.connectionTimeout),
    );
  }
  
  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    return await http.put(
      url,
      headers: _getHeaders(includeAuth: requiresAuth, token: token),
      body: jsonEncode(body),
    ).timeout(
      const Duration(seconds: ApiConstants.connectionTimeout),
    );
  }
  
  static Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    return await http.delete(
      url,
      headers: _getHeaders(includeAuth: requiresAuth, token: token),
    ).timeout(
      const Duration(seconds: ApiConstants.connectionTimeout),
    );
  }
  
  // Multipart request for file uploads (e.g., avatar)
  static Future<http.StreamedResponse> uploadFile(
    String endpoint,
    String fieldName,
    String filePath, {
    Map<String, String>? additionalFields,
    bool requiresAuth = true,
  }) async {
    final token = requiresAuth ? await getToken() : null;
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    
    final request = http.MultipartRequest('POST', url);
    
    if (requiresAuth && token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    
    request.files.add(await http.MultipartFile.fromPath(fieldName, filePath));
    
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    return await request.send();
  }
}
