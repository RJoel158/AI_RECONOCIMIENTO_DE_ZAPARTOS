class Product {
  final int id;
  final String sku;
  final String brand;
  final String modelName;
  final String type;
  final String colorPrimary;
  final String? colorSecondary;
  final String? material;
  final String? aisle;
  final String? shelf;
  final String? shelfLevel;
  final String? imagePath;

  Product({
    required this.id,
    required this.sku,
    required this.brand,
    required this.modelName,
    required this.type,
    required this.colorPrimary,
    this.colorSecondary,
    this.material,
    this.aisle,
    this.shelf,
    this.shelfLevel,
    this.imagePath,
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
      aisle: json['aisle'] as String?,
      shelf: json['shelf'] as String?,
      shelfLevel: json['shelf_level'] as String?,
      imagePath: json['image_path'] as String?,
    );
  }

  /// Returns the thumbnail URL (backend generates a cached low-quality version).
  String? get thumbnailUrl {
    if (imagePath == null) return null;
    // imagePath is like https://host/media/SKU.jpg
    // thumbnailUrl is    https://host/products/SKU/thumbnail
    final uri = Uri.tryParse(imagePath!);
    if (uri == null) return null;
    final baseUrl = '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}';
    return '$baseUrl/products/$sku/thumbnail';
  }
}
