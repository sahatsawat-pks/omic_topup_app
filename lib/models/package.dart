class Package {
  final String packageId;
  final String productId;
  final String name;
  final double price;
  final String? bonusDescription;

  Package({
    required this.packageId,
    required this.productId,
    required this.name,
    required this.price,
    this.bonusDescription,
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      packageId: json['Package_ID']?.toString() ?? json['packageId']?.toString() ?? '',
      productId: json['Product_ID']?.toString() ?? json['productId']?.toString() ?? '',
      name: json['Package_Name']?.toString() ?? json['name']?.toString() ?? '',
      price: double.tryParse(json['Package_Price']?.toString() ?? json['price']?.toString() ?? '0') ?? 0.0,
      bonusDescription: json['Bonus_Description']?.toString() ?? json['bonusDescription']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Package_ID': packageId,
      'Product_ID': productId,
      'Package_Name': name,
      'Package_Price': price,
      'Bonus_Description': bonusDescription,
    };
  }
}
