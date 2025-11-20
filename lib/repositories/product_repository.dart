import 'package:omic_topup_app/services/database_service.dart';

class ProductRepository {
  final _dbService = DatabaseService.instance;
  
  // Get all products
  Future<List<Map<String, dynamic>>> getAllProducts() async {
    try {
      print('🔍 ProductRepository: Querying database for products...');
      final results = await _dbService.mysql.query(
        '''SELECT p.*, c.Category_name 
           FROM Product p 
           LEFT JOIN Product_Category c ON p.product_category_ID = c.Category_ID
           ORDER BY p.product_name''',
      );
      
      print('📊 ProductRepository: Query returned ${results.length} rows');
      final productList = results.map((row) => row.fields).toList();
      
      if (productList.isNotEmpty) {
        print('   First product: ${productList.first}');
      }
      
      return productList;
    } catch (e) {
      print('❌ Error getting products: $e');
      rethrow;
    }
  }
  
  // Get product by ID
  Future<Map<String, dynamic>?> getProductById(String productId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT p.*, c.Category_name 
           FROM Product p 
           LEFT JOIN Product_Category c ON p.product_category_ID = c.Category_ID
           WHERE p.Product_ID = ?''',
        [productId],
      );
      
      if (results.isEmpty) return null;
      return results.first.fields;
    } catch (e) {
      print('❌ Error getting product: $e');
      rethrow;
    }
  }
  
  // Get products by category
  Future<List<Map<String, dynamic>>> getProductsByCategory(String categoryId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT p.*, c.Category_name 
           FROM Product p 
           LEFT JOIN Product_Category c ON p.product_category_ID = c.Category_ID
           WHERE p.product_category_ID = ?
           ORDER BY p.product_name''',
        [categoryId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting products by category: $e');
      rethrow;
    }
  }
  
  // Get product packages
  Future<List<Map<String, dynamic>>> getProductPackages(String productId) async {
    try {
      final results = await _dbService.mysql.query(
        'SELECT * FROM Product_Package WHERE Product_ID = ? ORDER BY Package_Price',
        [productId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting product packages: $e');
      rethrow;
    }
  }
  
  // Get product servers
  Future<List<Map<String, dynamic>>> getProductServers(String productId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT s.* 
           FROM Server s
           INNER JOIN Product_Server ps ON s.Server_ID = ps.Server_ID
           WHERE ps.Product_ID = ?
           ORDER BY s.Server_Name''',
        [productId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting product servers: $e');
      rethrow;
    }
  }
  
  // Get product reviews
  Future<List<Map<String, dynamic>>> getProductReviews(String productId) async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT r.*, u.Fname, u.Lname 
           FROM Review r
           LEFT JOIN User u ON r.User_ID = u.User_ID
           WHERE r.Product_ID = ?
           ORDER BY r.review_date DESC''',
        [productId],
      );
      
      return results.map((row) => row.fields).toList();
    } catch (e) {
      print('❌ Error getting product reviews: $e');
      rethrow;
    }
  }
  
  // Update product stock
  Future<bool> updateProductStock(String productId, int quantity) async {
    try {
      await _dbService.mysql.query(
        'UPDATE Product SET product_instock_quantity = product_instock_quantity - ? WHERE Product_ID = ?',
        [quantity, productId],
      );
      return true;
    } catch (e) {
      print('❌ Error updating product stock: $e');
      return false;
    }
  }

  Future<String> getNextProductId() async {
    try {
      final results = await _dbService.mysql.query(
        '''SELECT Product_ID FROM Product 
           ORDER BY Product_ID DESC 
           LIMIT 1'''
      );
      
      if (results.isEmpty) {
        return 'PRD001'; // First product
      }
      
      final lastProductId = results.first['Product_ID'] as String;
      final numberPart = lastProductId.substring(3); // Remove 'PRD' prefix
      final nextNumber = int.parse(numberPart) + 1;
      
      return 'PRD${nextNumber.toString().padLeft(3, '0')}'; // Format: PRD001, PRD002, etc.
    } catch (e) {
      print('❌ Error getting next order ID: $e');
      // Fallback to timestamp-based if query fails
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return 'PRD${timestamp.toString().substring(6)}';
    }
  }
  
  Future<int> getProductCount() async {
    try {
      final result = await _dbService.mysql.query('SELECT COUNT(*) as count FROM Product');
      return result.isNotEmpty ? result.first.fields['count'] as int? ?? 0 : 0;
    } catch (e) { return 0; }
  }

  // Create new product
  Future<bool> createProduct(Map<String, dynamic> productData) async {
    try {
      await _dbService.mysql.query(
        '''INSERT INTO Product 
           (Product_ID, product_name, product_category_ID, product_detail, 
            product_instock_quantity, product_sold_quantity, product_price, product_rating)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)''',
        [
          productData['Product_ID'],
          productData['product_name'],
          productData['product_category_ID'],
          productData['product_detail'] ?? '',
          productData['product_instock_quantity'] ?? 0,
          0,
          productData['product_price'] ?? 0,
          0
        ],
      );
      return true;
    } catch (e) {
      print('❌ Error creating product: $e');
      return false;
    }
  }
  
  // Update product
  Future<bool> updateProduct(String productId, Map<String, dynamic> productData) async {
    try {
      await _dbService.mysql.query(
        '''UPDATE Product SET
           product_name = ?, 
           product_category_ID = ?,
           product_detail = ?,
           product_instock_quantity = ?,
           product_price = ?
           WHERE Product_ID = ?''',
        [
          productData['product_name'],
          productData['product_category_ID'],
          productData['product_detail'] ?? '',
          productData['product_instock_quantity'] ?? 0,
          productData['product_price'] ?? 0,
          productId
        ],
      );
      return true;
    } catch (e) {
      print('❌ Error updating product: $e');
      return false;
    }
  }
  
  // Delete product
  Future<bool> deleteProduct(String productId) async {
    try {
      await _dbService.mysql.query(
        'DELETE FROM Product WHERE Product_ID = ?',
        [productId],
      );
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  // Generate next package ID
  Future<String> getNextPackageId() async {
    try {
      // Generate random 5-digit number
      final random = (10000 + DateTime.now().microsecond % 90000).toString();
      return 'PKG$random';
    } catch (e) {
      print('❌ Error getting next package ID: $e');
      // Fallback: generate random 5-digit number
      final random = (10000 + DateTime.now().microsecond % 90000).toString();
      return 'PKG$random';
    }
  }

  // Add package
  Future<bool> addPackage({
    required String productId,
    required String packageName,
    required double packagePrice,
    String? bonusDescription,
  }) async {
    try {
      final packageId = await getNextPackageId();
      
      await _dbService.mysql.query(
        '''INSERT INTO Product_Package 
           (Package_ID, Product_ID, Package_Name, Package_Price, Bonus_Description)
           VALUES (?, ?, ?, ?, ?)''',
        [
          packageId,
          productId,
          packageName,
          packagePrice,
          bonusDescription ?? '',
        ],
      );
      return true;
    } catch (e) {
      print('❌ Error adding package: $e');
      return false;
    }
  }

  // Edit package
  Future<bool> editPackage({
    required String packageId,
    required String packageName,
    required double packagePrice,
    String? bonusDescription,
  }) async {
    try {
      await _dbService.mysql.query(
        '''UPDATE Product_Package 
           SET Package_Name = ?, Package_Price = ?, Bonus_Description = ?
           WHERE Package_ID = ?''',
        [
          packageName,
          packagePrice,
          bonusDescription ?? '',
          packageId,
        ],
      );
      return true;
    } catch (e) {
      print('❌ Error editing package: $e');
      return false;
    }
  }

  // Delete package
  Future<bool> deletePackage(String packageId) async {
    try {
      await _dbService.mysql.query(
        'DELETE FROM Product_Package WHERE Package_ID = ?',
        [packageId],
      );
      return true;
    } catch (e) {
      print('❌ Error deleting package: $e');
      return false;
    }
  }
}
