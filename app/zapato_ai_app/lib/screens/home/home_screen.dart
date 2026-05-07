import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
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
        _showSnack('No se encontró detalle para ${product.sku}');
      }
    } catch (e) {
      _showSnack('Error: $e');
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: AppTheme.cream, fontSize: 14),
        ),
        backgroundColor: AppTheme.charcoal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    // Load distinct values from DB for each filter field
    final fields = ['brand', 'type', 'color_primary', 'color_secondary', 'material', 'aisle', 'shelf', 'shelf_level'];
    final labels = ['Marca', 'Tipo', 'Color primario', 'Color secundario', 'Material', 'Pasillo', 'Estante', 'Nivel'];
    
    final Map<String, List<String>> options = {};
    for (final field in fields) {
      try {
        options[field] = await _apiService.getDistinctValues(field);
      } catch (_) {
        options[field] = [];
      }
    }

    if (!mounted) return;

    // Working copy of selections
    final selected = Map<String, String?>.from(
      {for (final f in fields) f: _filters[f]?.isNotEmpty == true ? _filters[f] : null},
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: AppTheme.cream,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusXl),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.silver,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filtros',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setModalState(() {
                                for (final f in fields) {
                                  selected[f] = null;
                                }
                              });
                            },
                            child: Text(
                              'LIMPIAR',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.citrus,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      for (int i = 0; i < fields.length; i++) ...[
                        if (options[fields[i]]?.isNotEmpty == true)
                          _FilterDropdown(
                            label: labels[i],
                            options: options[fields[i]]!,
                            value: selected[fields[i]],
                            onChanged: (val) {
                              setModalState(() => selected[fields[i]] = val);
                            },
                          ),
                      ],
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancelar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                for (final f in fields) {
                                  _filters[f] = selected[f] ?? '';
                                }
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogView() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.citrus),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cargando catálogo...',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.ash,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off_rounded,
                  size: 48, color: AppTheme.silver),
              const SizedBox(height: 16),
              Text(
                'Sin conexión',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Verifica tu conexión e intenta de nuevo',
                style: TextStyle(color: AppTheme.ash, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProducts,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 48, color: AppTheme.silver),
            const SizedBox(height: 16),
            Text(
              'Catálogo vacío',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra tu primer producto',
              style: TextStyle(color: AppTheme.ash, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.72,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _ProductCard(
          product: product,
          onTap: () => _openDetails(product),
          index: index,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: _selectedIndex == 0
            ? Column(
                children: [
                  // ─── Premium Header ───
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'SHOESLY',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                                letterSpacing: 4,
                              ),
                            ),
                            Row(
                              children: [
                                _HeaderButton(
                                  icon: Icons.filter_list_rounded,
                                  onTap: _openFilters,
                                ),
                                const SizedBox(width: 8),
                                _HeaderButton(
                                  icon: Icons.add_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const CaptureBurstScreen(),
                                      ),
                                    );
                                  },
                                  accent: true,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ─── Search Bar ───
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.bone,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              color: AppTheme.ink,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Buscar por nombre o código...',
                              prefixIcon: Icon(Icons.search_rounded,
                                  color: AppTheme.silver, size: 22),
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14),
                            ),
                            onSubmitted: (value) {
                              _filters['q'] = value.trim();
                              _fetchProducts();
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),

                  // ─── Product Grid ───
                  Expanded(child: _buildCatalogView()),
                ],
              )
            : const ScannerScreen(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.grid_view_rounded,
                  label: 'Catálogo',
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.center_focus_strong_rounded,
                  label: 'Escanear',
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Product Card ───
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final int index;

  const _ProductCard({
    required this.product,
    required this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.normal,
        curve: AppTheme.defaultCurve,
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.bone,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: product.imagePath == null
                    ? Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: AppTheme.silver,
                        ),
                      )
                    : ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusMd),
                        ),
                        child: Image.network(
                          product.imagePath!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, _, _) => Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: AppTheme.silver,
                            ),
                          ),
                        ),
                      ),
              ),
            ),

            // Info area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.modelName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: AppTheme.ash,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bone,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm / 2),
                      ),
                      child: Text(
                        '${product.type} · ${product.colorPrimary}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.ash,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header Button ───
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool accent;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent ? AppTheme.ink : AppTheme.bone,
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Icon(
          icon,
          size: 20,
          color: accent ? AppTheme.bone : AppTheme.ink,
        ),
      ),
    );
  }
}

// ─── Nav Item ───
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppTheme.fast,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.ink.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? AppTheme.ink : AppTheme.silver,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? AppTheme.ink : AppTheme.silver,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Filter Dropdown ───
class _FilterDropdown extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: AppTheme.ash,
          ),
          filled: true,
          fillColor: AppTheme.bone,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            borderSide: BorderSide.none,
          ),
        ),
        dropdownColor: AppTheme.white,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: AppTheme.ink,
        ),
        items: [
          DropdownMenuItem<String>(
            value: null,
            child: Text(
              'Todos',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: AppTheme.silver,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          ...options.map(
            (opt) => DropdownMenuItem<String>(
              value: opt,
              child: Text(opt),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
