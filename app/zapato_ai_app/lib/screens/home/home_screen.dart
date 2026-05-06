import 'package:flutter/material.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../../models/product.dart';
import '../capture/capture_burst_screen.dart';
import '../details/details_screen.dart';
import '../scanner/scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _error;

  List<Product> _products = [];
  final Map<String, String> _filters = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiService.listProducts(
        q: _filters['q'],
        brand: _filters['brand'],
        type: _filters['type'],
        colorPrimary: _filters['color_primary'],
        colorSecondary: _filters['color_secondary'],
        material: _filters['material'],
        aisle: _filters['aisle'],
        shelf: _filters['shelf'],
        shelfLevel: _filters['shelf_level'],
        skip: 0,
        limit: 50,
      );

      final items = (response['items'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();

      setState(() {
        _products = items;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openDetails(Product product) async {
    try {
      final response = await _apiService.getProductBySku(product.sku);
      final details = response['details'] as Map<String, dynamic>?;
      if (!mounted) return;

      if (details != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(productData: details),
          ),
        );
      } else {
        _showSnack('No se encontro detalle para ${product.sku}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openFilters() {
    final brandController = TextEditingController(text: _filters['brand']);
    final typeController = TextEditingController(text: _filters['type']);
    final colorPrimaryController = TextEditingController(
      text: _filters['color_primary'],
    );
    final colorSecondaryController = TextEditingController(
      text: _filters['color_secondary'],
    );
    final materialController = TextEditingController(
      text: _filters['material'],
    );
    final aisleController = TextEditingController(text: _filters['aisle']);
    final shelfController = TextEditingController(text: _filters['shelf']);
    final shelfLevelController = TextEditingController(
      text: _filters['shelf_level'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filtros',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _buildField('Marca', brandController),
                _buildField('Tipo', typeController),
                _buildField('Color primario', colorPrimaryController),
                _buildField('Color secundario', colorSecondaryController),
                _buildField('Material', materialController),
                _buildField('Pasillo', aisleController),
                _buildField('Estante', shelfController),
                _buildField('Nivel', shelfLevelController),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _filters['brand'] = brandController.text.trim();
                          _filters['type'] = typeController.text.trim();
                          _filters['color_primary'] = colorPrimaryController
                              .text
                              .trim();
                          _filters['color_secondary'] = colorSecondaryController
                              .text
                              .trim();
                          _filters['material'] = materialController.text.trim();
                          _filters['aisle'] = aisleController.text.trim();
                          _filters['shelf'] = shelfController.text.trim();
                          _filters['shelf_level'] = shelfLevelController.text
                              .trim();

                          Navigator.pop(context);
                          _fetchProducts();
                        },
                        child: const Text('Aplicar'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      brandController.dispose();
      typeController.dispose();
      colorPrimaryController.dispose();
      colorSecondaryController.dispose();
      materialController.dispose();
      aisleController.dispose();
      shelfController.dispose();
      shelfLevelController.dispose();
    });
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildIndexView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    if (_products.isEmpty) {
      return const Center(child: Text('No hay productos cargados.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return GestureDetector(
          onTap: () => _openDetails(product),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: product.imagePath == null
                          ? Text(
                              product.sku,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.network(
                                product.imagePath!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Text(
                                  product.sku,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.modelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.brand,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${product.type} • ${product.colorPrimary}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = _selectedIndex == 0;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre o SKU',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onSubmitted: (value) {
                  _filters['q'] = value.trim();
                  _fetchProducts();
                },
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _openFilters,
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CaptureBurstScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: _selectedIndex == 0 ? _buildIndexView() : const ScannerScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: 'Indice'),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'Camara',
          ),
        ],
      ),
      backgroundColor: AppTheme.bone,
    );
  }
}
