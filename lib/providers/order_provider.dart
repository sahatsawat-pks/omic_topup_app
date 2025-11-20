import 'package:flutter/material.dart';
import '../repositories/order_repository.dart';
import '../models/package.dart';

class OrderProvider extends ChangeNotifier {
  final _orderRepo = OrderRepository();
  
  List<Map<String, dynamic>> _userOrders = [];
  bool _isLoading = false;
  String? _error;
  
  List<Map<String, dynamic>> get userOrders => _userOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Load user orders from MySQL
  Future<void> loadUserOrders(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _userOrders = await _orderRepo.getUserOrders(userId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load orders: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reorder an existing order (recreate the order and its items)
  Future<Map<String, dynamic>> reorder(String existingOrderId, String userId) async {
    try {
      final details = await getOrderDetails(existingOrderId);
      if (details == null) {
        return {'success': false, 'message': 'Original order not found'};
      }

      final order = details['order'] as Map<String, dynamic>;
      final items = details['items'] as List<dynamic>;

      if (items.isEmpty) {
        return {'success': false, 'message': 'No items to reorder'};
      }

      // Calculate totals
      double totalAmount = 0.0;
      for (final it in items) {
        final qty = (it['Quantity'] is int) ? it['Quantity'] as int : int.tryParse(it['Quantity']?.toString() ?? '1') ?? 1;
        final price = double.tryParse(it['Price_Per_Item']?.toString() ?? it['Price']?.toString() ?? '0') ?? 0.0;
        totalAmount += price * qty;
      }

      final newOrderId = await _orderRepo.getNextOrderId();

      final gameUid = order['Game_UID']?.toString() ?? '-';
      final gameUsername = order['Game_Username']?.toString();
      final gameServer = order['Game_server']?.toString();

      final finalAmount = totalAmount; // no discounts applied for reorder

      // Create new order
      final created = await _orderRepo.createOrder(
        orderId: newOrderId,
        userId: userId,
        gameUid: gameUid,
        gameUsername: gameUsername,
        gameServer: gameServer,
        totalAmount: totalAmount,
        discountAmount: 0.0,
        finalAmount: finalAmount,
        selectedServerId: null,
      );

      if (created == null) {
        return {'success': false, 'message': 'Failed to create new order'};
      }

      // Add items
      for (final it in items) {
        final productId = it['Product_ID']?.toString() ?? '';
        final packageId = it['Package_ID']?.toString() ?? '';
        final qty = (it['Quantity'] is int) ? it['Quantity'] as int : int.tryParse(it['Quantity']?.toString() ?? '1') ?? 1;
        final price = double.tryParse(it['Price_Per_Item']?.toString() ?? '0') ?? 0.0;
        final subtotal = price * qty;

        final added = await _orderRepo.addOrderItem(
          orderId: newOrderId,
          productId: productId,
          packageId: packageId,
          quantity: qty,
          pricePerItem: price,
          subtotal: subtotal,
        );

        if (!added) {
          return {'success': false, 'message': 'Failed to add order items'};
        }
      }

      // Create payment and finalize
      final paymentId = 'PAY${newOrderId.substring(3)}';
      final paymentCreated = await _orderRepo.createPayment(
        paymentId: paymentId,
        orderId: newOrderId,
        paymentAmount: finalAmount,
        paymentMethod: 'True Wallet',
      );

      if (!paymentCreated) {
        return {'success': false, 'message': 'Payment creation failed'};
      }

      await _orderRepo.updatePaymentStatus(paymentId, 'Success');
      await _orderRepo.updateOrderStatus(newOrderId, 'Success');

      // Reload orders for the user
      await loadUserOrders(userId);

      return {'success': true, 'message': 'Reorder completed', 'orderId': newOrderId};
    } catch (e) {
      debugPrint('Reorder error: $e');
      return {'success': false, 'message': 'Reorder error: ${e.toString()}'};
    }
  }
  
  // Create order with package purchase
  Future<Map<String, dynamic>> createOrder({
    required String userId,
    required String productId,
    required Package package,
    required String gameUid,
    String? gameUsername,
    String? gameServer,
    String? selectedServerId,
    required String paymentMethod,
  }) async {
    try {
      // Generate auto-increment order ID (ORD001, ORD002, etc.)
      final orderId = await _orderRepo.getNextOrderId();
      print('Creating order: $orderId');
      
      final totalAmount = package.price;
      final discountAmount = 0.0;
      final finalAmount = totalAmount - discountAmount;
      
      // Create order
      final orderCreated = await _orderRepo.createOrder(
        orderId: orderId,
        userId: userId,
        gameUid: gameUid,
        gameUsername: gameUsername,
        gameServer: gameServer,
        totalAmount: totalAmount,
        discountAmount: discountAmount,
        finalAmount: finalAmount,
        selectedServerId: selectedServerId,
      );
      
      if (orderCreated == null) {
        return {
          'success': false,
          'message': 'Failed to create order',
        };
      }
      
      // Add order item
      final itemAdded = await _orderRepo.addOrderItem(
        orderId: orderId,
        productId: productId,
        packageId: package.packageId,
        quantity: 1,
        pricePerItem: package.price,
        subtotal: package.price,
      );
      
      if (!itemAdded) {
        return {
          'success': false,
          'message': 'Failed to add order item',
        };
      }
      
      // Process payment with selected payment method
      // Generate payment ID matching order number (PAY001, PAY002, etc.)
      final paymentId = 'PAY${orderId.substring(3)}'; // Use same number as order
      final paymentCreated = await _orderRepo.createPayment(
        paymentId: paymentId,
        orderId: orderId,
        paymentMethod: paymentMethod,
        paymentAmount: finalAmount,
      );
      
      if (!paymentCreated) {
        return {
          'success': false,
          'message': 'Payment processing failed',
        };
      }
      
      // Update payment status to Success (matches DB enum)
      await _orderRepo.updatePaymentStatus(paymentId, 'Success');
      
      // Update order status to Success (matches DB enum)
      await _orderRepo.updateOrderStatus(orderId, 'Success');
      
      // Reload user orders
      await loadUserOrders(userId);
      
      return {
        'success': true,
        'message': 'Order created successfully',
        'orderId': orderId,
        'paymentId': paymentId,
      };
    } catch (e) {
      debugPrint('Create order error: $e');
      return {
        'success': false,
        'message': 'Order creation error: ${e.toString()}',
      };
    }
  }
  
  // Get order details with items
  Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
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
      debugPrint('Get order details error: $e');
      return null;
    }
  }
  
}
