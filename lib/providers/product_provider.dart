import 'package:flutter/material.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';

class ProductProvider extends ChangeNotifier {
  final _productRepo = ProductRepository();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  final Map<String, List<Map<String, dynamic>>> _productPackages = {};
  final Map<String, List<Map<String, dynamic>>> _productServers = {};
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<Product> get products => _filteredProducts.isEmpty && _searchQuery.isEmpty 
      ? _products 
      : _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  // Load all products from MySQL
  Future<void> loadProducts() async {
    print('🔄 ProductProvider: Starting to load products...');
    _isLoading = true;
    _error = null;
    // notifyListeners();

    try {
      print('🔍 ProductProvider: Fetching products from repository...');
      final mysqlData = await _productRepo.getAllProducts();
      print('📦 ProductProvider: Received ${mysqlData.length} products from MySQL');
      
      if (mysqlData.isNotEmpty) {
        _products = mysqlData.map((json) {
          print('  - Parsing product: ${json['product_name'] ?? json['Product_name'] ?? 'unknown'}');
          return Product.fromJson(json);
        }).toList();
        _filteredProducts = _products;
        print('✅ Loaded ${_products.length} products from MySQL');
      } else {
        print('⚠️ No products found in database');
        _products = [];
        _filteredProducts = [];
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('❌ Error loading products: $e');
      _error = 'Failed to load products: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
    }
  }
  // Search products
  void searchProducts(String query) {
    _searchQuery = query.toLowerCase();
    if (_searchQuery.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) {
        return product.productName.toLowerCase().contains(_searchQuery) ||
               (product.productDetail?.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    notifyListeners();
  }

  // Filter by category
  void filterByCategory(String? categoryId) {
    if (categoryId == null || categoryId.isEmpty) {
      _filteredProducts = _products;
    } else {
      _filteredProducts = _products.where((product) {
        return product.productCategoryId == categoryId;
      }).toList();
    }
    notifyListeners();
  }

  // Get product by ID
  Product? getProductById(String productId) {
    try {
      return _products.firstWhere((p) => p.productId == productId);
    } catch (e) {
      return null;
    }
  }

  // Load product packages
  Future<List<Map<String, dynamic>>> getProductPackages(String productId) async {
    if (_productPackages.containsKey(productId)) {
      return _productPackages[productId]!;
    }

    try {
      final packages = await _productRepo.getProductPackages(productId);
      _productPackages[productId] = packages;
      return packages;
    } catch (e) {
      debugPrint('Error loading packages: $e');
      return [];
    }
  }

  // Load product servers
  Future<List<Map<String, dynamic>>> getProductServers(String productId) async {
    if (_productServers.containsKey(productId)) {
      return _productServers[productId]!;
    }

    try {
      final servers = await _productRepo.getProductServers(productId);
      _productServers[productId] = servers;
      return servers;
    } catch (e) {
      debugPrint('Error loading servers: $e');
      return [];
    }
  }

  // Get product reviews
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      return await _productRepo.getProductReviews(productId);
    } catch (e) {
      debugPrint('Error loading reviews: $e');
      return [];
    }
  }

  // Clear cache
  void clearCache() {
    _productPackages.clear();
    _productServers.clear();
    notifyListeners();
  }
  
}
