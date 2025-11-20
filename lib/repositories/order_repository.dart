// ignore_for_file: avoid_print

import 'package:omic_topup_app/services/database_service.dart';

class OrderRepository {
  final _dbService = DatabaseService.instance;
  
  // Get next order ID (auto-increment format: ORD001, ORD002, etc.)
  Future<String> getNextOrderId() async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT Order_ID FROM Order_Record 
           ORDER BY Order_ID DESC 
           LIMIT 1'''
      );
      
      if (results.isEmpty) {
        return 'ORD001'; // First order
      }
      
      final lastOrderId = results.first['Order_ID'] as String;
      final numberPart = lastOrderId.substring(3); // Remove 'ORD' prefix
      final nextNumber = int.parse(numberPart) + 1;
      
      return 'ORD${nextNumber.toString().padLeft(3, '0')}'; // Format: ORD001, ORD002, etc.
    } catch (e) {
      print('❌ Error getting next order ID: $e');
      // Fallback to timestamp-based if query fails
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'ORD${timestamp.toString().substring(6)}';
    }
  }
  
  // Create new order
  Future<String?> createOrder({
    required String orderId,
    required String userId,
    required String gameUid,
    String? gameUsername,
    String? gameServer,
    required double totalAmount,
    double discountAmount = 0.0,
    required double finalAmount,
    String? selectedServerId,
    String? discountId,
  }) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Order_Record 
           (Order_ID, User_ID, Game_UID, Game_Username, order_status, Game_server, 
            Purchase_Date, Total_Amount, Discount_Amount, Final_Amount, 
            Selected_Server_ID, Discount_ID)
           VALUES (?, ?, ?, ?, 'In progress', ?, NOW(), ?, ?, ?, ?, ?)''',
        [
          orderId, userId, gameUid, gameUsername, gameServer,
          totalAmount, discountAmount, finalAmount, selectedServerId, discountId
        ],
      );
      return orderId;
    } catch (e) {
      print('❌ Error creating order: $e');
      return null;
    }
  }
  
  // Add order item
  Future<bool> addOrderItem({
    required String orderId,
    required String productId,
    required String packageId,
    required int quantity,
    required double pricePerItem,
    required double subtotal,
  }) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Order_Item 
           (Order_ID, Product_ID, Package_ID, Quantity, Price_Per_Item, Subtotal)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [orderId, productId, packageId, quantity, pricePerItem, subtotal],
      );
      return true;
    } catch (e) {
      print('❌ Error adding order item: $e');
      return false;
    }
  }
  
  // Get order by ID
  Future<Map<String, dynamic>?> getOrderById(String orderId) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM Order_Record WHERE Order_ID = ?',
        [orderId],
      );
      
      if (results.isEmpty) return null;
      return results.first.fields;
    } catch (e) {
      print('❌ Error getting order: $e');
      rethrow;
    }
  }
  
  // Get user orders
  Future<List<Map<String, dynamic>>> getUserOrders(String userId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT * FROM Order_Record 
           WHERE User_ID = ? 
           ORDER BY Purchase_Date DESC''',
        [userId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting user orders: $e');
      rethrow;
    }
  }
  
  // Get order items
  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT oi.*, p.product_name, pp.Package_Name
           FROM Order_Item oi
           LEFT JOIN Product p ON oi.Product_ID = p.Product_ID
           LEFT JOIN Product_Package pp ON oi.Package_ID = pp.Package_ID
           WHERE oi.Order_ID = ?''',
        [orderId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting order items: $e');
      rethrow;
    }
  }
  
  // Update order status
  Future<bool> updateOrderStatus(String orderId, String status) async {
    try {
      await _dbService.mysql.query(
        'UPDATE Order_Record SET order_status = ? WHERE Order_ID = ?',
        [status, orderId],
      );
      return true;
    } catch (e) {
      print('❌ Error updating order status: $e');
      return false;
    }
  }
  
  // Create payment record
  Future<bool> createPayment({
    required String paymentId,
    required String orderId,
    required double paymentAmount,
    required String paymentMethod,
    String? customerBankAccount,
    String? customerTrueWalletNumber,
    String? customerPromptpayNumber,
    String? customerCardNumber,
    String? transactionId,
    String? paymentProofPath,
  }) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Payment_Record 
           (Payment_ID, Order_ID, customer_bank_account, customer_true_wallet_number,
            customer_promptpay_number, customer_card_number, Payment_amount, 
            Payment_status, Payment_date, Payment_method, Transaction_ID, Payment_Proof_Path)
           VALUES (?, ?, ?, ?, ?, ?, ?, 'In progress', NOW(), ?, ?, ?)''',
        [
          paymentId, orderId, customerBankAccount, customerTrueWalletNumber,
          customerPromptpayNumber, customerCardNumber, paymentAmount,
          paymentMethod, transactionId, paymentProofPath
        ],
      );
      return true;
    } catch (e) {
      print('❌ Error creating payment: $e');
      return false;
    }
  }
  
  // Get order payments
  Future<List<Map<String, dynamic>>> getOrderPayments(String orderId) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM Payment_Record WHERE Order_ID = ?',
        [orderId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting order payments: $e');
      rethrow;
    }
  }
  
  // Update payment status
  Future<bool> updatePaymentStatus(String paymentId, String status) async {
    try {
      await _dbService.mysql.query(
        'UPDATE Payment_Record SET Payment_status = ? WHERE Payment_ID = ?',
        [status, paymentId],
      );
      return true;
    } catch (e) {
      print('❌ Error updating payment status: $e');
      return false;
    }
  }

  // 1. Get Total Order Count
  Future<int> getOrderCount() async {
    try {
      final result = await _dbService.mysql.query(
        'SELECT COUNT(*) as count FROM Order_Record',
      );
      return result.isNotEmpty ? result.first.fields['count'] as int? ?? 0 : 0;
    } catch (e) {
      print('❌ Error getting order count: $e');
      return 0;
    }
  }

  // 2. Get Total Revenue (Success orders only)
  Future<double> getTotalRevenue() async {
    try {
      final result = await _dbService.mysql.query(
        "SELECT SUM(Final_Amount) as total FROM Order_Record WHERE order_status = 'Success'",
      );
      if (result.isNotEmpty) {
        final total = result.first.fields['total'];
        return total != null ? (total as num).toDouble() : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('❌ Error getting revenue: $e');
      return 0.0;
    }
  }

  // 3. Get Recent Orders for Dashboard
  Future<List<Map<String, dynamic>>> getRecentOrders({int limit = 5}) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT Order_ID, User_ID, order_status, Purchase_Date, Final_Amount 
           FROM Order_Record 
           ORDER BY Purchase_Date DESC 
           LIMIT ?''',
        [limit],
      );
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting recent orders: $e');
      return [];
    }
  }

  // 4. Get All Orders with User Details (For Order Management)
  Future<List<Map<String, dynamic>>> getAllOrdersWithUserDetails() async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT o.*, u.Fname, u.Lname 
           FROM Order_Record o 
           LEFT JOIN User u ON o.User_ID = u.User_ID 
           ORDER BY o.Purchase_Date DESC''',
      );
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting all orders: $e');
      return [];
    }
  }
}
