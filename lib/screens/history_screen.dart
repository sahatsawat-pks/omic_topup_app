import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.user != null) {
        Provider.of<OrderProvider>(context, listen: false).loadUserOrders(authProvider.user!.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            if (authProvider.user != null) {
              await orderProvider.loadUserOrders(authProvider.user!.userId);
            }
          },
          child: Builder(
            builder: (context) {
              if (orderProvider.isLoading) return const Center(child: CircularProgressIndicator());
              if (orderProvider.userOrders.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'No orders yet',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Start shopping to see your order history',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/user/games');
                        },
                        child: const Text('Browse Games'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: orderProvider.userOrders.length,
                itemBuilder: (context, index) {
                  final orderData = orderProvider.userOrders[index];
                  final order = _OrderDisplay(
                    orderId: orderData['Order_ID']?.toString() ?? '',
                    orderStatus: orderData['order_status']?.toString() ?? 'Unknown',
                    purchaseDate: DateTime.tryParse(orderData['Purchase_Date']?.toString() ?? '') ?? DateTime.now(),
                    finalAmount: double.tryParse(orderData['Final_Amount']?.toString() ?? '0') ?? 0.0,
                    gameUid: orderData['Game_UID']?.toString(),
                    gameUsername: orderData['Game_Username']?.toString(),
                    gameServer: orderData['Game_server']?.toString(),
                    totalAmount: double.tryParse(orderData['Total_Amount']?.toString() ?? '0') ?? 0.0,
                    discountAmount: double.tryParse(orderData['Discount_Amount']?.toString() ?? '0') ?? 0.0,
                  );

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(order.orderStatus).withOpacity(0.2),
                        child: Icon(
                          _getStatusIcon(order.orderStatus),
                          color: _getStatusColor(order.orderStatus),
                        ),
                      ),
                      title: Text(
                        'Order #${order.orderId}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('MMM dd, yyyy - HH:mm').format(order.purchaseDate),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.orderStatus).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              order.orderStatus,
                              style: TextStyle(
                                color: _getStatusColor(order.orderStatus),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        '฿${order.finalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Game UID:', order.gameUid ?? '-'),
                              _buildDetailRow('Username:', order.gameUsername ?? '-'),
                              _buildDetailRow('Server:', order.gameServer ?? '-'),
                              _buildDetailRow('Total Amount:', '฿${order.totalAmount.toStringAsFixed(2)}'),
                              if (order.discountAmount > 0)
                                _buildDetailRow(
                                  'Discount:',
                                  '-฿${order.discountAmount.toStringAsFixed(2)}',
                                  valueColor: Colors.green,
                                ),
                              _buildDetailRow(
                                'Final Amount:',
                                '฿${order.finalAmount.toStringAsFixed(2)}',
                                valueStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AppTheme.accentColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt),
                                      label: const Text('View Details'),
                                      onPressed: () {
                                        _showOrderDetails(context, order);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (order.orderStatus == 'Success')
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Reorder'),
                                        onPressed: () async {
                                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                          if (authProvider.user == null) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Please login to reorder')),
                                            );
                                            return;
                                          }

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Reordering...')),
                                          );

                                          final result = await Provider.of<OrderProvider>(context, listen: false)
                                              .reorder(order.orderId, authProvider.user!.userId);

                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(result['message'] ?? 'Reorder finished')),
                                          );
                                        },
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {TextStyle? valueStyle, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: valueStyle ?? TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
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

  void _showOrderDetails(BuildContext context, order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order #${order.orderId}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Status: ${order.orderStatus}'),
              Text('Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(order.purchaseDate)}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text('Game UID: ${order.gameUid ?? '-'}'),
              Text('Username: ${order.gameUsername ?? '-'}'),
              Text('Server: ${order.gameServer ?? '-'}'),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
              Text('Total: ฿${order.totalAmount.toStringAsFixed(2)}'),
              if (order.discountAmount > 0)
                Text('Discount: -฿${order.discountAmount.toStringAsFixed(2)}'),
              Text(
                'Final: ฿${order.finalAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _OrderDisplay {
  final String orderId;
  final String orderStatus;
  final DateTime purchaseDate;
  final double finalAmount;
  final String? gameUid;
  final String? gameUsername;
  final String? gameServer;
  final double totalAmount;
  final double discountAmount;

  _OrderDisplay({
    required this.orderId,
    required this.orderStatus,
    required this.purchaseDate,
    required this.finalAmount,
    this.gameUid,
    this.gameUsername,
    this.gameServer,
    required this.totalAmount,
    required this.discountAmount,
  });
}
