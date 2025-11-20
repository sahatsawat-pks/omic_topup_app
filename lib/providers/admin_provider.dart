import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/product_repository.dart';

class AdminProvider extends ChangeNotifier {
  final _userRepo = UserRepository();
  final _orderRepo = OrderRepository();
  final _productRepo = ProductRepository();

  // Statistics
  int _totalUsers = 0;
  int _totalOrders = 0;
  int _totalProducts = 0;
  double _totalRevenue = 0.0;
  
  // Users management
  List<Map<String, dynamic>> _allUsers = [];
  bool _isLoadingUsers = false;
  
  // Orders management
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoadingOrders = false;
  
  // Recent activity
  List<Map<String, dynamic>> _recentActivity = [];
  
  String? _error;

  // Getters
  int get totalUsers => _totalUsers;
  int get totalOrders => _totalOrders;
  int get totalProducts => _totalProducts;
  double get totalRevenue => _totalRevenue;
  List<Map<String, dynamic>> get allUsers => _allUsers;
  List<Map<String, dynamic>> get allOrders => _allOrders;
  List<Map<String, dynamic>> get recentActivity => _recentActivity;
  bool get isLoadingUsers => _isLoadingUsers;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get error => _error;

  /// Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      _error = null;
      
      // Use Future.wait to load these in parallel for better performance
      await Future.wait([
        _loadUsersCount(),
        _loadOrdersStats(),
        _loadProductsCount(),
      ]);

      // Load activity last as it depends on processed data lists
      await _loadRecentActivity();
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load dashboard stats: $e';
      debugPrint('❌ Error loading dashboard stats: $e');
      notifyListeners();
    }
  }

  Future<void> _loadUsersCount() async {
    // FIX: Calling repository method instead of raw query
    _totalUsers = await _userRepo.getUserCount();
  }

  Future<void> _loadOrdersStats() async {
    // FIX: Calling repository methods
    _totalOrders = await _orderRepo.getOrderCount();
    _totalRevenue = await _orderRepo.getTotalRevenue();
  }

  Future<void> _loadProductsCount() async {
    // FIX: Calling repository method
    _totalProducts = await _productRepo.getProductCount();
  }

  Future<void> _loadRecentActivity() async {
    try {
      _recentActivity = [];
      
      // FIX: Get recent orders via Repository
      final orders = await _orderRepo.getRecentOrders(limit: 5);
      
      for (var fields in orders) {
        _recentActivity.add({
          'type': 'order',
          'icon': Icons.shopping_bag,
          'title': 'Order ${fields['Order_ID']}',
          'subtitle': 'Status: ${fields['order_status']}',
          'time': fields['Purchase_Date']?.toString() ?? '',
          'color': _getStatusColor(fields['order_status']?.toString() ?? ''),
        });
      }
      
      // FIX: Get recent users via Repository
      final users = await _userRepo.getRecentUsers(limit: 3);
      
      for (var fields in users) {
        _recentActivity.add({
          'type': 'user',
          'icon': Icons.person_add,
          'title': 'New user: ${fields['Fname']} ${fields['Lname']}',
          'subtitle': 'User ID: ${fields['User_ID']}',
          'time': fields['create_date']?.toString() ?? '',
          'color': Colors.blue,
        });
      }
      
      // Sort by time (most recent first)
      _recentActivity.sort((a, b) {
        return b['time'].toString().compareTo(a['time'].toString());
      });
      
      // Keep only top 10
      if (_recentActivity.length > 10) {
        _recentActivity = _recentActivity.sublist(0, 10);
      }
      
    } catch (e) {
      debugPrint('Error loading recent activity: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Success': return Colors.green;
      case 'Cancel': return Colors.red;
      case 'In progress': return Colors.orange;
      default: return Colors.grey;
    }
  }

  /// Load all users for user management
  Future<void> loadAllUsers() async {
    _isLoadingUsers = true;
    _error = null;
    notifyListeners();

    try {
      // FIX: Use repository method
      _allUsers = await _userRepo.getAllUsersWithLoginData();
      
      _isLoadingUsers = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load users: $e';
      _isLoadingUsers = false;
      debugPrint('❌ Error loading users: $e');
      notifyListeners();
    }
  }

  /// Load all orders for order management
  Future<void> loadAllOrders() async {
    _isLoadingOrders = true;
    _error = null;
    notifyListeners();

    try {
      // FIX: Use repository method
      _allOrders = await _orderRepo.getAllOrdersWithUserDetails();

      _isLoadingOrders = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load orders: $e';
      _isLoadingOrders = false;
      debugPrint('❌ Error loading orders: $e');
      notifyListeners();
    }
  }

  /// Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _orderRepo.updateOrderStatus(orderId, newStatus);
      
      // Reload orders and stats
      await loadAllOrders();
      await loadDashboardStats();
      
      return true;
    } catch (e) {
      _error = 'Failed to update order status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete user (admin action)
  Future<bool> deleteUser(String userId) async {
    try {
      final success = await _userRepo.deleteUser(userId);
      
      if (success) {
        await loadAllUsers();
        await loadDashboardStats();
      }
      
      return success;
    } catch (e) {
      _error = 'Failed to delete user: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get order details with items
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    // This method was already fine as it used public repo methods
    try {
      final order = await _orderRepo.getOrderById(orderId);
      if (order == null) return null;

      final items = await _orderRepo.getOrderItems(orderId);
      final payments = await _orderRepo.getOrderPayments(orderId);

      return {
        'order': order,
        'items': items,
        'payments': payments,
      };
    } catch (e) {
      debugPrint('❌ Error getting order details: $e');
      return null;
    }
  }

  Future<bool> editUser(String userId, String fname, String lname, String phone) async {
  try {
    final success = await _userRepo.updateUserDetails(userId, fname, lname, phone);
    if (success) {
      await loadAllUsers(); // Refresh list to show changes
    }
    return success;
  } catch (e) {
    return false;
  }
}

Future<bool> removeAvatar(String userId) async {
  try {
    final success = await _userRepo.removeUserAvatar(userId);
    if (success) {
      await loadAllUsers(); // Refresh list
    }
    return success;
  } catch (e) {
    return false;
  }
}

  void clearData() {
    _totalUsers = 0;
    _totalOrders = 0;
    _totalProducts = 0;
    _totalRevenue = 0.0;
    _allUsers = [];
    _allOrders = [];
    _recentActivity = [];
    _error = null;
    notifyListeners();
  }
}