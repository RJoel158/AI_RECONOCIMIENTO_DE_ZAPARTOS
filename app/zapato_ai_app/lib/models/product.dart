class Product {
  final int id;
  final String sku;
  final String brand;
  final String modelName;
  final String type;
  final String colorPrimary;
  final String? colorSecondary;
  final String? material;
  final String? gender;
  final String? aisle;
  final String? shelf;
  final String? shelfLevel;

  Product({
    required this.id,
    required this.sku,
    required this.brand,
    required this.modelName,
    required this.type,
    required this.colorPrimary,
    this.colorSecondary,
    this.material,
    this.gender,
    this.aisle,
    this.shelf,
    this.shelfLevel,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int,
      sku: json['sku'] as String,
      brand: json['brand'] as String,
      modelName: json['model_name'] as String,
      type: json['type'] as String,
      colorPrimary: json['color_primary'] as String,
      colorSecondary: json['color_secondary'] as String?,
      material: json['material'] as String?,
      gender: json['gender'] as String?,
      aisle: json['aisle'] as String?,
      shelf: json['shelf'] as String?,
      shelfLevel: json['shelf_level'] as String?,
    );
  }
}
