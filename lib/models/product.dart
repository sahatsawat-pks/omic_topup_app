class Product {
  final String productId;
  final String productName;
  final String productCategoryId;
  final String? productDetail;
  final int productInstockQuantity;
  final int productSoldQuantity;
  final double productPrice;
  final double productRating;
  final DateTime? productExpireDate;
  final String? productPhotoPath;
  final String? categoryName;
  final List<Map<String, dynamic>> servers;

  Product({
    required this.productId,
    required this.productName,
    required this.productCategoryId,
    this.productDetail,
    required this.productInstockQuantity,
    required this.productSoldQuantity,
    required this.productPrice,
    required this.productRating,
    this.productExpireDate,
    this.productPhotoPath,
    this.categoryName,
    this.servers = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> serversList = [];
    if (json['servers'] != null) {
      if (json['servers'] is List) {
        serversList = (json['servers'] as List).map((s) => s as Map<String, dynamic>).toList();
      }
    }
    
    return Product(
      productId: json['Product_ID']?.toString() ?? json['productId']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? json['name']?.toString() ?? '',
      productCategoryId: json['product_category_ID']?.toString() ?? json['categoryId']?.toString() ?? '',
      productDetail: json['product_detail']?.toString() ?? json['description']?.toString(),
      productInstockQuantity: int.tryParse(json['product_instock_quantity']?.toString() ?? '0') ?? 0,
      productSoldQuantity: int.tryParse(json['product_sold_quantity']?.toString() ?? '0') ?? 0,
      productPrice: double.tryParse(json['product_price']?.toString() ?? '0') ?? 0.0,
      productRating: double.tryParse(json['product_rating']?.toString() ?? '0') ?? 0.0,
      productExpireDate: json['product_expire_date'] != null 
          ? DateTime.tryParse(json['product_expire_date'].toString())
          : null,
      productPhotoPath: json['product_photo_path']?.toString() ?? json['photoPath']?.toString(),
      categoryName: json['Category_name']?.toString(),
      servers: serversList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Product_ID': productId,
      'product_name': productName,
      'product_category_ID': productCategoryId,
      'product_detail': productDetail,
      'product_instock_quantity': productInstockQuantity,
      'product_sold_quantity': productSoldQuantity,
      'product_price': productPrice,
      'product_rating': productRating,
      'product_expire_date': productExpireDate?.toIso8601String(),
      'product_photo_path': productPhotoPath,
      'Category_name': categoryName,
    };
  }

  // Helper getters for compatibility
  String get name => productName;
  String get photoPath => productPhotoPath ?? '';
  String? get description => productDetail;
}
