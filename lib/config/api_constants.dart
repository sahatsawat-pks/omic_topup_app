import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:3300/api';
  
  static String get login => dotenv.env['API_LOGIN'] ?? '/auth/login';
  static String get register => dotenv.env['API_REGISTER'] ?? '/auth/register';
  static String get products => dotenv.env['API_PRODUCTS'] ?? '/products';
  static String get productById => dotenv.env['API_PRODUCT_BY_ID'] ?? '/products/';
  static String get packages => dotenv.env['API_PACKAGES'] ?? '/packages';
  static String get packagesByProductId => dotenv.env['API_PACKAGES_BY_PRODUCT_ID'] ?? '/packages/product/';
  static String get orders => dotenv.env['API_ORDERS'] ?? '/orders';
  static String get latestOrderId => dotenv.env['API_LATEST_ORDER_ID'] ?? '/orders/latest';
  static String get updateProfile => dotenv.env['API_UPDATE_PROFILE'] ?? '/profile/update';
  static String get updatePassword => dotenv.env['API_UPDATE_PASSWORD'] ?? '/profile/password';
  
  static int get connectionTimeout => int.parse(dotenv.env['API_CONNECTION_TIMEOUT'] ?? '30');
  static int get receiveTimeout => int.parse(dotenv.env['API_RECEIVE_TIMEOUT'] ?? '30');
  
  static String get accessTokenKey => dotenv.env['STORAGE_ACCESS_TOKEN_KEY'] ?? 'accessToken';
  static String get userKey => dotenv.env['STORAGE_USER_KEY'] ?? 'authUser';
}