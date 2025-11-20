import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/package.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/order_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../utils/image_helper.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Product? _product;
  List<Package> _packages = [];
  bool _isLoading = true;
  String? _error;
  Package? _selectedPackage;
  
  // Form controllers
  final _gameUidController = TextEditingController();
  final _gameUsernameController = TextEditingController();
  final _promptpayNumberController = TextEditingController();
  final _userBankAccountController = TextEditingController();
  final _creditCardNumberController = TextEditingController();
  final _creditCardExpiryController = TextEditingController();
  final _creditCardCVVController = TextEditingController();
  
  // Form state
  String? _selectedServer;
  String? _selectedServerName;
  String _selectedPaymentMethod = '';
  String _creditCardType = '';
  bool _isVerifyingCard = false;
  String _cardVerificationStatus = 'idle'; // idle, verifying, success, error
  String? _submissionError;

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }
  
  @override
  void dispose() {
    _gameUidController.dispose();
    _gameUsernameController.dispose();
    _promptpayNumberController.dispose();
    _userBankAccountController.dispose();
    _creditCardNumberController.dispose();
    _creditCardExpiryController.dispose();
    _creditCardCVVController.dispose();
    super.dispose();
  }

  Future<void> _loadProductDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final productProvider = Provider.of<ProductProvider>(context, listen: false);
      
      // Get product from provider
      var product = productProvider.getProductById(widget.productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      // Load packages from database
      final packagesData = await productProvider.getProductPackages(widget.productId);
      
      // Load servers for this product
      final serversData = await productProvider.getProductServers(widget.productId);
      
      // Convert package data to Package objects
      final packages = packagesData.map((data) => Package.fromJson(data)).toList();
      
      // Update product with servers
      product = Product(
        productId: product.productId,
        productName: product.productName,
        productCategoryId: product.productCategoryId,
        productDetail: product.productDetail,
        productInstockQuantity: product.productInstockQuantity,
        productSoldQuantity: product.productSoldQuantity,
        productPrice: product.productPrice,
        productRating: product.productRating,
        productExpireDate: product.productExpireDate,
        productPhotoPath: product.productPhotoPath,
        categoryName: product.categoryName,
        servers: serversData,
      );
      
      setState(() {
        _product = product;
        _packages = packages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _selectPackage(Package package) {
    setState(() {
      _selectedPackage = package;
    });
  }

  Widget _buildProductImage() {
    final imagePath = ImageHelper.getProductImagePath(
      _product!.productPhotoPath,
      _product!.productName,
    );
    
    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.secondaryColor,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.games, size: 80, color: AppTheme.accentColor),
              SizedBox(height: 8),
              Text('Product Image'),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPaymentMethodSelector(String selectedMethod, Function(String) onSelect) {
    final paymentMethods = [
      {'name': 'Credit/Debit Card', 'image': 'assets/images/payments/credit-card.png'},
      {'name': 'True Wallet', 'image': 'assets/images/payments/true-wallet-qr.png'},
      {'name': 'Promptpay', 'image': 'assets/images/payments/promptpay.png'},
      {'name': 'QR Payment', 'image': 'assets/images/payments/qr.png'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: paymentMethods.map((method) {
        final isSelected = selectedMethod == method['name'];
        return GestureDetector(
          onTap: () => onSelect(method['name']!),
          child: Container(
            width: 140,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? AppTheme.accentColor : AppTheme.borderColor,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? AppTheme.accentColor.withOpacity(0.1) : Colors.white,
            ),
            child: Column(
              children: [
                Image.asset(
                  method['image']!,
                  height: 40,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.payment, size: 40);
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  method['name']!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.accentColor : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _processPurchase({
    required String gameUid,
    String? gameUsername,
    String? selectedServerId,
    String? gameServer,
    required String paymentMethod,
  }) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Processing your order...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      
      if (authProvider.user == null) {
        throw Exception('User not logged in');
      }
      
      // Create order in database with user-provided details
      final result = await orderProvider.createOrder(
        userId: authProvider.user!.userId,
        productId: _product!.productId,
        package: _selectedPackage!,
        gameUid: gameUid,
        gameUsername: gameUsername,
        gameServer: gameServer,
        selectedServerId: selectedServerId,
        paymentMethod: paymentMethod,
      );
      
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result['success'] == true) {
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 8),
                const Text('Success!'),
              ],
            ),
            content: Text(
              'Your order has been placed successfully!\n\n'
              'Order ID: ${result['orderId']}\n'
              'Package: ${_selectedPackage!.name}\n'
              'Amount: ฿${_selectedPackage!.price.toStringAsFixed(2)}\n'
              'Payment Method: $paymentMethod\n'
              'Payment ID: ${result['paymentId']}',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Order failed'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      Navigator.of(context).pop(); // Close loading dialog
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  // Check if review button should be disabled
  bool _isReviewButtonDisabled() {
    // Check UID requirement
    if (_requiresUID() && _gameUidController.text.trim().isEmpty) return true;
    
    // Check server requirement
    if (_hasServers() && _selectedServer == null) return true;
    
    // Check package selection
    if (_selectedPackage == null) return true;
    
    // Check payment method selection
    if (_selectedPaymentMethod.isEmpty) return true;
    
    // Payment method specific validation
    if (_selectedPaymentMethod == 'Bank Transfer' && 
        _userBankAccountController.text.trim().isEmpty) return true;
        
    if (_selectedPaymentMethod == 'Credit/Debit Card' && 
        _cardVerificationStatus != 'success') return true;
        
    if ((_selectedPaymentMethod == 'Promptpay' || _selectedPaymentMethod == 'True Wallet') && 
        _promptpayNumberController.text.trim().isEmpty) return true;
    
    return false;
  }
  
  bool _requiresUID() {
    return _product?.categoryName == 'Game Top-up';
  }
  
  bool _hasServers() {
    return _product?.servers.isNotEmpty ?? false;
  }
  
  // Show order summary dialog
  void _showOrderSummary() {
    if (_isReviewButtonDisabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }
    
    setState(() {
      _submissionError = null;
    });
    
    showDialog(
      context: context,
      builder: (context) => _buildOrderSummaryDialog(),
    );
  }
  
  // Simulate credit card verification
  void _verifyCreditCard() {
    if (_creditCardNumberController.text.isEmpty ||
        _creditCardExpiryController.text.isEmpty ||
        _creditCardCVVController.text.isEmpty ||
        _creditCardType.isEmpty) {
      setState(() {
        _submissionError = 'Please fill in all credit card details';
        _cardVerificationStatus = 'error';
      });
      return;
    }
    
    setState(() {
      _submissionError = null;
      _isVerifyingCard = true;
      _cardVerificationStatus = 'verifying';
    });
    
    // Simulate verification delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isVerifyingCard = false;
          // 90% success rate for simulation
          _cardVerificationStatus = (DateTime.now().millisecond % 10) != 0 ? 'success' : 'error';
          if (_cardVerificationStatus == 'error') {
            _submissionError = 'Card verification failed. Please check details.';
          }
        });
      }
    });
  }

  // Build Game Info Section (Section 1)
  Widget _buildGameInfoSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          
          return Column(
            children: [
              if (isMobile)
                _buildMobileGameInfo()
              else
                _buildDesktopGameInfo(),
            ],
          );
        },
      ),
    );
  }
  
  Widget _buildMobileGameInfo() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildProductImage(),
              ),
            ),
            const SizedBox(width: 12),
            // Top Up Details
            Expanded(
              child: _buildTopUpDetails(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Rating Box
        _buildRatingBox(),
      ],
    );
  }
  
  Widget _buildDesktopGameInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Product Image
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildProductImage(),
          ),
        ),
        const SizedBox(width: 16),
        // Top Up Details
        Expanded(
          flex: 3,
          child: _buildTopUpDetails(),
        ),
        const SizedBox(width: 16),
        // Rating Box
        Expanded(
          flex: 1,
          child: _buildRatingBox(),
        ),
      ],
    );
  }
  
  Widget _buildTopUpDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF475569), // slate-700
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Column(
            children: [
              Text(
                'Top up ${_product!.productName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _requiresUID() && !_hasServers()
                      ? 'Step 1: Enter your User ID'
                      : !_requiresUID() && _hasServers()
                          ? 'Step 1: Select your Server'
                          : _requiresUID() && _hasServers()
                              ? 'Step 1: Enter User ID & Select Server'
                              : 'Step 1: Proceed to select package & payment',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // User ID Input (Conditional)
          if (_requiresUID()) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Game User ID / Name *',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextField(
              controller: _gameUidController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Enter your ID or Username here',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF1E293B), // slate-800
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Server Selection (Conditional)
          if (_hasServers()) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Game Server *',
                style: TextStyle(
                  color: Colors.grey[200],
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedServer,
              dropdownColor: const Color(0xFF1E293B),
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF1E293B),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.accentColor, width: 2),
                ),
              ),
              hint: Text('Select Server', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
              items: _product!.servers.map<DropdownMenuItem<String>>((server) {
                return DropdownMenuItem<String>(
                  value: server['Server_ID']?.toString() ?? '',
                  child: Text(server['Server_Name']?.toString() ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedServer = value;
                  _selectedServerName = _product!.servers
                      .firstWhere((s) => s['Server_ID'].toString() == value)['Server_Name'];
                });
              },
            ),
          ],
          // Message if no UID/Server needed
          if (!_requiresUID() && !_hasServers())
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No User ID or Server required for this product.',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildRatingBox() {
    final rating = _product!.productRating;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E), // teal-800
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Average Rating',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          if (rating > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _buildStars(rating),
            ),
            const SizedBox(height: 12),
            Text(
              '${rating.toStringAsFixed(1)} / 5.0',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No rating available',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reviews feature coming soon')),
              );
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'View Reviews',
              style: TextStyle(
                color: Colors.teal[200],
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildStars(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    bool hasHalfStar = (rating % 1) >= 0.5;
    
    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, color: Colors.amber, size: 24));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(const Icon(Icons.star_half, color: Colors.amber, size: 24));
      } else {
        stars.add(const Icon(Icons.star_border, color: Colors.grey, size: 24));
      }
    }
    return stars;
  }

  // Build Payment Method Section (Section 2)
  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF475569), // slate-600
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Step 2: Select Payment Method *',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          _buildPaymentMethodSelector(_selectedPaymentMethod, (method) {
            setState(() {
              _selectedPaymentMethod = method;
              // Reset payment-specific fields
              _userBankAccountController.clear();
              _creditCardNumberController.clear();
              _creditCardExpiryController.clear();
              _creditCardCVVController.clear();
              _creditCardType = '';
              _isVerifyingCard = false;
              _cardVerificationStatus = 'idle';
              _promptpayNumberController.clear();
              _submissionError = null;
            });
          }),
          const SizedBox(height: 24),
          const Divider(color: Colors.grey),
          const SizedBox(height: 24),
          _buildPaymentDetails(),
        ],
      ),
    );
  }
  
  Widget _buildPaymentDetails() {
    if (_selectedPaymentMethod.isEmpty) {
      return Text(
        'Please select a payment method above to see details.',
        style: TextStyle(
          color: Colors.grey[400],
          fontSize: 14,
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      );
    }
    
    if (_selectedPaymentMethod == 'Bank Transfer') {
      return _buildBankTransferDetails();
    } else if (_selectedPaymentMethod == 'Credit/Debit Card') {
      return _buildCreditCardDetails();
    } else if (_selectedPaymentMethod == 'Promptpay' || _selectedPaymentMethod == 'True Wallet') {
      return _buildQRPaymentDetails();
    }
    
    return const SizedBox.shrink();
  }
  
  Widget _buildBankTransferDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Bank Transfer Confirmation',
          style: TextStyle(
            color: Color(0xFF5EEAD4), // teal-300
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF334155), // slate-700
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please transfer the exact amount for your selected package to the account below:',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Bank Name:', 'Example Bank'),
              const SizedBox(height: 8),
              _buildInfoRow('Account No:', '123-456789-0'),
              const SizedBox(height: 8),
              _buildInfoRow('Account Name:', 'Example Merchant Co.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'After transferring, enter the bank account number you used for the payment below to help us verify your transaction.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Text(
          'Your Transferring Bank Account Number *',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _userBankAccountController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter the account number you paid from',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.accentColor),
            ),
          ),
        ),
        if (_userBankAccountController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Entering your account number is required for bank transfer confirmation.',
              style: TextStyle(
                color: Colors.yellow[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
  
  Widget _buildCreditCardDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Credit/Debit Card Details',
          style: TextStyle(
            color: Color(0xFF5EEAD4),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // Card Number
        Text(
          'Card Number *',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _creditCardNumberController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(19),
          ],
          decoration: InputDecoration(
            hintText: '•••• •••• •••• ••••',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.accentColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            // Card Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Card Type *',
                  style: TextStyle(
                    color: Colors.grey[300],
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _creditCardType.isEmpty ? null : _creditCardType,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: Colors.grey[600]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: const BorderSide(color: AppTheme.accentColor),
                    ),
                  ),
                  hint: const Text('Select Type', style: TextStyle(color: Colors.grey)),
                  items: ['Visa', 'Mastercard', 'JCB'].map((type) {
                    return DropdownMenuItem<String>(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _creditCardType = value ?? '';
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Expiry and CVV Row
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Expiry (MM/YY) *',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _creditCardExpiryController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          hintText: 'MM/YY',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppTheme.accentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CVV *',
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _creditCardCVVController,
                        keyboardType: TextInputType.number,
                        obscureText: true,
                        style: const TextStyle(color: Colors.white),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          hintText: '•••',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: const Color(0xFF1E293B),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey[600]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: AppTheme.accentColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Verify Button
        Center(
          child: ElevatedButton(
            onPressed: _isVerifyingCard || _cardVerificationStatus == 'success'
                ? null
                : _verifyCreditCard,
            style: ElevatedButton.styleFrom(
              backgroundColor: _cardVerificationStatus == 'success'
                  ? Colors.green
                  : _cardVerificationStatus == 'error'
                      ? Colors.red
                      : Colors.blue,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isVerifyingCard)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                if (_isVerifyingCard) const SizedBox(width: 8),
                if (_cardVerificationStatus == 'success')
                  const Icon(Icons.check_circle, size: 16),
                if (_cardVerificationStatus == 'success') const SizedBox(width: 8),
                if (_cardVerificationStatus == 'error')
                  const Icon(Icons.error, size: 16),
                if (_cardVerificationStatus == 'error') const SizedBox(width: 8),
                Text(
                  _cardVerificationStatus == 'idle'
                      ? 'Verify Card'
                      : _cardVerificationStatus == 'verifying'
                          ? 'Verifying...'
                          : _cardVerificationStatus == 'success'
                              ? 'Card Verified'
                              : 'Verification Failed (Retry)',
                ),
              ],
            ),
          ),
        ),
        if (_submissionError != null && _cardVerificationStatus == 'error')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _submissionError!,
              style: TextStyle(
                color: Colors.red[300],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (_cardVerificationStatus == 'success')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Card verified successfully. You can now proceed to review your order.',
              style: TextStyle(
                color: Colors.green[300],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        if (_cardVerificationStatus == 'idle' || 
            (_cardVerificationStatus == 'error' && !_isVerifyingCard))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Card verification is required before placing the order.',
              style: TextStyle(
                color: Colors.yellow[400],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
  
  Widget _buildQRPaymentDetails() {
    return Column(
      children: [
        Text(
          'Scan QR Code & Enter Number',
          style: TextStyle(
            color: const Color(0xFF5EEAD4),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              return Column(
                children: [
                  _buildQRCode(),
                  const SizedBox(height: 24),
                  _buildNumberInput(),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildQRCode()),
                  const SizedBox(width: 24),
                  Expanded(child: _buildNumberInput()),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 16),
        Text(
          'Your order will be processed after payment confirmation.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildQRCode() {
    return Column(
      children: [
        Text(
          '1. Scan to Pay',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 180,
          height: 180,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/payments/qr.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.qr_code, size: 80, color: Colors.grey);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildNumberInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '2. Enter Your Number',
          style: TextStyle(
            color: Color(0xFF5EEAD4),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${_selectedPaymentMethod == "Promptpay" ? "PromptPay" : "TrueMoney"} No. *',
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _promptpayNumberController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your registered number',
            hintStyle: TextStyle(color: Colors.grey[500]),
            filled: true,
            fillColor: const Color(0xFF1E293B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Colors.grey[600]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: AppTheme.accentColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the number associated with the account you used to scan the QR code.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (_promptpayNumberController.text.trim().isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Entering your number is required for ${_selectedPaymentMethod == "Promptpay" ? "PromptPay" : "TrueMoney"} confirmation.',
              style: TextStyle(
                color: Colors.yellow[400],
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey[300],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  // Build Package Selection Section (Section 3)
  Widget _buildPackageSelectionSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E), // teal-700
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Step 3: Select Package *',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 28),
          if (_packages.isEmpty)
            const Center(
              child: Text(
                'No packages available',
                style: TextStyle(color: Colors.white70),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _packages.length,
              itemBuilder: (context, index) {
                final package = _packages[index];
                final isSelected = _selectedPackage?.packageId == package.packageId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentColor : Colors.white.withOpacity(0.3),
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                    onTap: () => _selectPackage(package),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          // Checkmark
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? AppTheme.accentColor : Colors.white.withOpacity(0.5),
                                width: 2,
                              ),
                              color: isSelected ? AppTheme.accentColor : Colors.transparent,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          // Package info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  package.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                ),
                                if (package.bonusDescription != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    package.bonusDescription!,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Price
                          Text(
                            '฿${package.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
  
  // Build Action Buttons (Section 4)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Go Back Button
          OutlinedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              side: BorderSide(color: Colors.grey[400]!, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const Text(
              'Go back',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          // Review Order Button
          ElevatedButton.icon(
            onPressed: _isReviewButtonDisabled() ? null : _showOrderSummary,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              backgroundColor: const Color(0xFFF97316), // orange-500
              disabledBackgroundColor: Colors.grey[400],
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            icon: const Icon(Icons.shopping_cart_checkout, size: 20),
            label: const Text(
              'Review Order',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build Order Summary Dialog
  Widget _buildOrderSummaryDialog() {
    return AlertDialog(
      title: Column(
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your order details carefully before confirming.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_submissionError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _submissionError!,
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    ),
                  ],
                ),
              ),
            _buildSummaryRow('Game:', _product!.productName, bold: true),
            if (_requiresUID() && _gameUidController.text.isNotEmpty)
              _buildSummaryRow('User ID:', _gameUidController.text, mono: true),
            if (_hasServers() && _selectedServerName != null)
              _buildSummaryRow('Server:', _selectedServerName!),
            const Divider(height: 24),
            _buildSummaryRow('Package:', _selectedPackage?.name ?? 'N/A', bold: true),
            _buildSummaryRow(
              'Price:',
              '฿${_selectedPackage?.price.toStringAsFixed(2) ?? "0.00"}',
              color: const Color(0xFF0F766E),
              large: true,
            ),
            if (_selectedPackage?.bonusDescription != null)
              _buildSummaryRow(
                'Bonus:',
                _selectedPackage!.bonusDescription!,
                color: Colors.green,
              ),
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.payment, size: 16),
                const SizedBox(width: 8),
                Text(
                  _selectedPaymentMethod,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (_selectedPaymentMethod == 'Bank Transfer' &&
                _userBankAccountController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Your Acct: ${_userBankAccountController.text}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            if (_selectedPaymentMethod == 'Credit/Debit Card')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$_creditCardType ending ${_creditCardNumberController.text.length >= 4 ? _creditCardNumberController.text.substring(_creditCardNumberController.text.length - 4) : "****"}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if ((_selectedPaymentMethod == 'Promptpay' ||
                    _selectedPaymentMethod == 'True Wallet') &&
                _promptpayNumberController.text.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Your Number: ${_promptpayNumberController.text}',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Edit Selection'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            _processPurchase(
              gameUid: _gameUidController.text,
              gameUsername: _gameUsernameController.text.isNotEmpty
                  ? _gameUsernameController.text
                  : null,
              selectedServerId: _selectedServer,
              gameServer: _selectedServerName,
              paymentMethod: _selectedPaymentMethod,
            );
          },
          icon: const Icon(Icons.check_circle),
          label: const Text('Confirm & Place Order'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSummaryRow(String label, String value,
      {bool bold = false, bool mono = false, Color? color, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                fontFamily: mono ? 'monospace' : null,
                color: color,
                fontSize: large ? 18 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_product?.productName ?? 'Product Details'),
        backgroundColor: AppTheme.primaryColor,
      ),
      drawer: const AppDrawer(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: AppTheme.errorColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load product',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadProductDetails,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _product == null
                  ? const Center(child: Text('Product not found'))
                  : Container(
                      color: AppTheme.backgroundColor,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              _buildGameInfoSection(),
                              const SizedBox(height: 16),
                              _buildPaymentMethodSection(),
                              const SizedBox(height: 16),
                              _buildPackageSelectionSection(),
                              const SizedBox(height: 24),
                              _buildActionButtons(),
                            ],
                          ),
                        ),
                      ),
                    ),
    );
  }
}
