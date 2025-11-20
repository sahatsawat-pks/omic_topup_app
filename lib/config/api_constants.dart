class ApiConstants {
  // Base URL - Update this to your backend server
  static const String baseUrl = 'http://localhost:3300/api';
  
  // API Endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String products = '/products';
  static const String productById = '/products/';
  static const String packages = '/packages';
  static const String packagesByProductId = '/packages/product/';
  static const String orders = '/orders';
  static const String latestOrderId = '/orders/latest';
  static const String updateProfile = '/profile/update';
  static const String updatePassword = '/profile/password';
  
  // Timeouts
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  
  // Storage Keys
  static const String accessTokenKey = 'accessToken';
  static const String userKey = 'authUser';
}
