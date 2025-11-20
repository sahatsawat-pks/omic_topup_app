import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_drawer.dart';
import '../repositories/order_repository.dart';
import 'package:intl/intl.dart';

class ManageOrdersScreen extends StatefulWidget {
  const ManageOrdersScreen({super.key});

  @override
  State<ManageOrdersScreen> createState() => _ManageOrdersScreenState();
}

class _ManageOrdersScreenState extends State<ManageOrdersScreen> {
  String _filterStatus = 'All';
  final _orderRepo = OrderRepository();
  List<Map<String, dynamic>> _allOrders = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _orderRepo.getAllOrdersWithUserDetails();
      setState(() {
        _allOrders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading orders: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Orders')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Orders'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _filterStatus,
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'All', child: Text('All Orders')),
              const PopupMenuItem(value: 'In progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'Success', child: Text('Success')),
              const PopupMenuItem(value: 'Cancel', child: Text('Cancelled')),
            ],
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _buildOrdersList(),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredOrders = _filterStatus == 'All'
        ? _allOrders
        : _allOrders.where((order) => order['order_status'].toString() == _filterStatus).toList();

    return RefreshIndicator(
      onRefresh: () async => _loadOrders(),
      child: filteredOrders.isEmpty
          ? const Center(child: Text('No orders found'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final order = filteredOrders[index];
                final status = order['order_status']?.toString() ?? 'Unknown';
                final orderID = order['Order_ID']?.toString() ?? 'N/A';
                final userName = '${order['Fname']} ${order['Lname']}'.trim();
                final amount = order['Final_Amount'] ?? 0.0;
                final purchaseDate = order['Purchase_Date'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      child: Icon(
                        _getStatusIcon(status),
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Text(
                      'Order #$orderID',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Customer: $userName'),
                        Text('Amount: ฿${(amount as dynamic).toStringAsFixed(2)}'),
                        if (purchaseDate != null)
                          Text(
                            DateFormat('MMM dd, yyyy HH:mm').format(purchaseDate is DateTime ? purchaseDate : DateTime.parse(purchaseDate.toString())),
                            style: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    onTap: () => _showOrderDetails(order),
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'cancel':
        return Colors.red;
      case 'in progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      case 'in progress':
        return Icons.hourglass_empty;
      default:
        return Icons.info;
    }
  }

  void _showOrderDetails(Map<String, dynamic> order) {
    final status = order['order_status']?.toString() ?? 'Unknown';
    final orderID = order['Order_ID']?.toString() ?? 'N/A';
    final userName = '${order['Fname']} ${order['Lname']}'.trim();
    final amount = order['Final_Amount'] ?? 0.0;
    final totalAmount = order['Total_Amount'] ?? 0.0;
    final purchaseDate = order['Purchase_Date'];
    final gameUsername = order['Game_Username']?.toString() ?? 'N/A';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #$orderID'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Customer:', userName),
              _buildDetailRow('Game Username:', gameUsername),
              _buildDetailRow('Status:', status),
              _buildDetailRow('Total Amount:', '฿${(totalAmount as dynamic).toStringAsFixed(2)}'),
              _buildDetailRow('Final Amount:', '฿${(amount as dynamic).toStringAsFixed(2)}'),
              _buildDetailRow(
                'Date:',
                purchaseDate != null 
                  ? DateFormat('MMM dd, yyyy HH:mm').format(purchaseDate is DateTime ? purchaseDate : DateTime.parse(purchaseDate.toString()))
                  : 'N/A',
              ),
              const SizedBox(height: 16),
              const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (status == 'In progress') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Mark as Complete'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(orderID, 'Success');
                    },
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Order'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      Navigator.pop(context);
                      _updateOrderStatus(orderID, 'Cancel');
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) async {
    try {
      final orderRepo = OrderRepository();
      
      // Update order status
      final orderUpdated = await orderRepo.updateOrderStatus(orderId, newStatus);
      
      if (orderUpdated) {
        // Also update payment status if order status is Success or Cancel
        if (newStatus == 'Success' || newStatus == 'Cancel') {
          await orderRepo.updatePaymentStatus('PAY${orderId.substring(3)}', newStatus);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $orderId updated to $newStatus'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _loadOrders();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update order status'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating order: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
