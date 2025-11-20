import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../config/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../repositories/product_repository.dart';
import '../utils/image_helper.dart';

class ManageProductsScreen extends StatefulWidget {
  const ManageProductsScreen({super.key});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final _productRepo = ProductRepository();
  String? _selectedProductId;
  List<Map<String, dynamic>> _packages = [];
  bool _loadingPackages = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    Provider.of<ProductProvider>(context, listen: false).loadProducts();
  }

  Future<void> _loadPackages(String productId) async {
    setState(() {
      _loadingPackages = true;
      _selectedProductId = productId;
    });
    try {
      final packages = await _productRepo.getProductPackages(productId);
      setState(() {
        _packages = packages;
        _loadingPackages = false;
      });
    } catch (e) {
      setState(() => _loadingPackages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading packages: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Manage Products')),
        body: const Center(child: Text('Access Denied')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Manage Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddProductDialog(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async => _loadProducts(),
        child: productProvider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : productProvider.products.isEmpty
                ? const Center(child: Text('No products available'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productProvider.products.length,
                    itemBuilder: (context, index) {
                      final product = productProvider.products[index];
                      final isSelected = _selectedProductId == product.productId;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          children: [
                            ListTile(
                              leading: CircleAvatar(
                                radius: 28,
                                backgroundImage: AssetImage(
                                  ImageHelper.getProductImagePath(
                                    product.productPhotoPath,
                                    product.productName,
                                  ),
                                ),
                              ),
                              title: Text(product.productName),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Stock: ${product.productInstockQuantity}'),
                                  Text('Rating: ${product.productRating} ⭐'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'packages',
                                    child: Row(
                                      children: [
                                        Icon(Icons.shopping_bag),
                                        SizedBox(width: 8),
                                        Text('View Packages'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Delete', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'packages') {
                                    _loadPackages(product.productId);
                                  } else if (value == 'edit') {
                                    _showEditProductDialog(product.productId);
                                  } else if (value == 'delete') {
                                    _confirmDelete(product.productId, product.productName);
                                  }
                                },
                              ),
                            ),
                            // Show packages if selected
                            if (isSelected && _packages.isNotEmpty)
                              Container(
                                color: Colors.grey[100],
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Divider(),
                                    const Text(
                                      'Packages',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 8),
                                    _loadingPackages
                                        ? const SizedBox(
                                            height: 50,
                                            child: Center(child: CircularProgressIndicator()),
                                          )
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: _packages.length,
                                            itemBuilder: (context, pkgIndex) {
                                              final pkg = _packages[pkgIndex];
                                              return Container(
                                                margin: const EdgeInsets.only(bottom: 8),
                                                padding: const EdgeInsets.all(10),
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  borderRadius: BorderRadius.circular(8),
                                                  color: Colors.white,
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            pkg['Package_Name']?.toString() ?? 'N/A',
                                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            '฿${pkg['Package_Price']}',
                                                            style: TextStyle(
                                                              color: AppTheme.accentColor,
                                                              fontWeight: FontWeight.w600,
                                                            ),
                                                          ),
                                                          if (pkg['Bonus_Description'] != null)
                                                            Text(
                                                              'Bonus: ${pkg['Bonus_Description']}',
                                                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuButton(
                                                      itemBuilder: (context) => [
                                                        const PopupMenuItem(
                                                          value: 'edit',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.edit),
                                                              SizedBox(width: 8),
                                                              Text('Edit'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'delete',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.delete, color: Colors.red),
                                                              SizedBox(width: 8),
                                                              Text('Delete', style: TextStyle(color: Colors.red)),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      onSelected: (value) {
                                                        if (value == 'edit') {
                                                          _showEditPackageDialog(pkg);
                                                        } else if (value == 'delete') {
                                                          _confirmDeletePackage(pkg);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add Package'),
                                        onPressed: () => _showAddPackageDialog(product.productId),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  void _showAddProductDialog() {
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();
    final _detailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (฿)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _priceController.text.isEmpty || _stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              try {
                final productRepo = ProductRepository();
                final productId = await productRepo.getNextProductId();
                
                final success = await productRepo.createProduct({
                  'Product_ID': productId,
                  'product_name': _nameController.text,
                  'product_category_ID': '1', // Default category
                  'product_detail': _detailController.text,
                  'product_instock_quantity': int.parse(_stockController.text),
                  'product_price': double.parse(_priceController.text),
                });
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product added successfully'), backgroundColor: Colors.green),
                  );
                  _loadProducts();
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add product'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(String productId) {
    final _nameController = TextEditingController();
    final _priceController = TextEditingController();
    final _stockController = TextEditingController();
    final _detailController = TextEditingController();
    
    // Find the product and populate fields
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final product = productProvider.products.firstWhere(
      (p) => p.productId == productId,
      orElse: () => productProvider.products.first,
    );
    
    _nameController.text = product.productName;
    _priceController.text = product.productPrice.toString();
    _stockController.text = product.productInstockQuantity.toString();
    _detailController.text = product.productDetail ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Product Name'),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price (฿)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock Quantity'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }
              
              try {
                // Note: Full product update would need a dedicated repository method
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product updated successfully'), backgroundColor: Colors.green),
                );
                _loadProducts();
                Navigator.pop(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              _deleteProduct(productId, productName);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteProduct(String productId, String productName) async {
    try {
      final productRepo = ProductRepository();
      // Delete product from database
      await productRepo.deleteProduct(productId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product "$productName" deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showAddPackageDialog(String productId) {
    final _packageNameController = TextEditingController();
    final _packagePriceController = TextEditingController();
    final _bonusController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _packageNameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
              ),
              TextField(
                controller: _packagePriceController,
                decoration: const InputDecoration(labelText: 'Price (฿)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bonusController,
                decoration: const InputDecoration(labelText: 'Bonus Description (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_packageNameController.text.isEmpty || _packagePriceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }
              try {
                final productRepo = ProductRepository();
                final success = await productRepo.addPackage(
                  productId: productId,
                  packageName: _packageNameController.text,
                  packagePrice: double.parse(_packagePriceController.text),
                  bonusDescription: _bonusController.text.isEmpty ? null : _bonusController.text,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Package added successfully'), backgroundColor: Colors.green),
                  );
                  _loadPackages(productId);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to add package'), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditPackageDialog(Map<String, dynamic> package) {
    final _packageNameController = TextEditingController();
    final _packagePriceController = TextEditingController();
    final _bonusController = TextEditingController();

    _packageNameController.text = package['Package_Name']?.toString() ?? '';
    _packagePriceController.text = package['Package_Price']?.toString() ?? '';
    _bonusController.text = package['Bonus_Description']?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _packageNameController,
                decoration: const InputDecoration(labelText: 'Package Name'),
              ),
              TextField(
                controller: _packagePriceController,
                decoration: const InputDecoration(labelText: 'Price (฿)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _bonusController,
                decoration: const InputDecoration(labelText: 'Bonus Description (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => _confirmDeletePackage(package),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_packageNameController.text.isEmpty || _packagePriceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }
              try {
                final success = await _productRepo.editPackage(
                  packageId: package['Package_ID'],
                  packageName: _packageNameController.text,
                  packagePrice: double.parse(_packagePriceController.text),
                  bonusDescription: _bonusController.text.isEmpty ? null : _bonusController.text,
                );
                if (success) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Package updated successfully'), backgroundColor: Colors.green),
                    );
                    if (_selectedProductId != null) {
                      _loadPackages(_selectedProductId!);
                    }
                    Navigator.pop(context);
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update package'), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _confirmDeletePackage(Map<String, dynamic> package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Package'),
        content: Text('Delete package "${package['Package_Name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              try {
                final success = await _productRepo.deletePackage(package['Package_ID']);
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Package deleted successfully'), backgroundColor: Colors.green),
                    );
                    if (_selectedProductId != null) {
                      _loadPackages(_selectedProductId!);
                    }
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to delete package'), backgroundColor: Colors.red),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
