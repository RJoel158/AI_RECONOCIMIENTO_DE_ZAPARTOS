import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class DetailsScreen extends StatelessWidget {
  final Map<String, dynamic> productData;

  const DetailsScreen({super.key, required this.productData});

  @override
  Widget build(BuildContext context) {
    final product = productData['product'];
    final stockItems = productData['stock'] as List;
    final totalStock = productData['total_stock'];
    final aisle = productData['aisle'];
    final shelf = productData['shelf'];
    final shelfLevel = productData['shelf_level'];
    final similarProducts = productData['similar_products'] as List?;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del Calzado"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: 300,
              width: double.infinity,
              child: product['image_path'] != null
                  ? Image.network(
                      product['image_path'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Text(
                            "Imagen: ${product['sku']}",
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          "Imagen: ${product['sku']}",
                          style: const TextStyle(fontSize: 20),
                        ),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['model_name'],
                    style: AppTheme.lightTheme.textTheme.displayLarge?.copyWith(
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    product['brand'],
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  const Divider(height: 30),

                  // WAREHOUSE LOCATION (Crucial part for store staff)
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[50],
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "📍 UBICACIÓN EN ALMACÉN",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Pasillo: ${aisle ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Estante: ${shelf ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                        Text(
                          "Nivel: ${shelfLevel ?? 'N/A'}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // STOCK SECTION
                  Text(
                    "Stock disponible",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: stockItems.map((item) {
                      return Chip(
                        label: Text("${item['size']} (${item['quantity']})"),
                        backgroundColor: item['quantity'] > 0
                            ? Colors.green[100]
                            : Colors.red[100],
                      );
                    }).toList(),
                  ),

                  if (totalStock == 0) ...[
                    const SizedBox(height: 20),
                    const Text(
                      "⚠️ Este modelo está agotado.",
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text("Te recomendamos estos modelos similares:"),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: similarProducts?.length ?? 0,
                        itemBuilder: (context, index) {
                          final sim = similarProducts![index];
                          return Card(
                            child: Container(
                              width: 120,
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Container(
                                    height: 80,
                                    width: 80,
                                    color: Colors.grey,
                                  ),
                                  Text(
                                    sim['model_name'],
                                    style: const TextStyle(fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
