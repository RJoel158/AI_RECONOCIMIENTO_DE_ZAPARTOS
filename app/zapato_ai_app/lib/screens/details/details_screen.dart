import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: AppTheme.cream,
      body: CustomScrollView(
        slivers: [
          // ─── Hero Image App Bar ───
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppTheme.cream,
            foregroundColor: AppTheme.ink,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white,
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: product['image_path'] != null
                  ? Image.network(
                      product['image_path'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => Container(
                        color: AppTheme.bone,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.image_outlined,
                                  size: 48, color: AppTheme.silver),
                              const SizedBox(height: 8),
                              Text(
                                product['sku'],
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  color: AppTheme.ash,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: AppTheme.bone,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_outlined,
                                size: 48, color: AppTheme.silver),
                            const SizedBox(height: 8),
                            Text(
                              product['sku'],
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                color: AppTheme.ash,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),

          // ─── Content ───
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name + brand
                  Text(
                    product['model_name'],
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['brand'],
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      color: AppTheme.ash,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Product type + color tag
                  Wrap(
                    spacing: 8,
                    children: [
                      _Tag(label: product['type'] ?? ''),
                      _Tag(label: product['color_primary'] ?? ''),
                      if (product['material'] != null &&
                          product['material'].toString().isNotEmpty)
                        _Tag(label: product['material']),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ─── Warehouse Location ───
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppTheme.citrus.withValues(alpha: 0.12),
                                borderRadius:
                                    BorderRadius.circular(AppTheme.radiusSm / 2),
                              ),
                              child: Icon(Icons.location_on_rounded,
                                  color: AppTheme.citrus, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'UBICACIÓN EN ALMACÉN',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ash,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _LocationItem(
                                label: 'Pasillo', value: aisle ?? 'N/A'),
                            const SizedBox(width: 20),
                            _LocationItem(
                                label: 'Estante', value: shelf ?? 'N/A'),
                            const SizedBox(width: 20),
                            _LocationItem(
                                label: 'Nivel', value: shelfLevel ?? 'N/A'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── Stock Section ───
                  Text(
                    'STOCK DISPONIBLE',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ash,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: stockItems.map((item) {
                      final hasStock = item['quantity'] > 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: hasStock
                              ? AppTheme.success.withValues(alpha: 0.1)
                              : AppTheme.error.withValues(alpha: 0.08),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          border: Border.all(
                            color: hasStock
                                ? AppTheme.success.withValues(alpha: 0.2)
                                : AppTheme.error.withValues(alpha: 0.15),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${item['size']}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.ink,
                              ),
                            ),
                            Text(
                              '${item['quantity']} uds',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                color: hasStock
                                    ? AppTheme.success
                                    : AppTheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),

                  // ─── Out of stock + recommendations ───
                  if (totalStock == 0) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withValues(alpha: 0.06),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        border: Border.all(
                          color: AppTheme.error.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppTheme.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Modelo agotado — te recomendamos similares',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 160,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: similarProducts?.length ?? 0,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final sim = similarProducts![index];
                          return Container(
                            width: 130,
                            decoration: AppTheme.cardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppTheme.bone,
                                      borderRadius:
                                          const BorderRadius.vertical(
                                        top: Radius.circular(
                                            AppTheme.radiusMd),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.image_outlined,
                                        color: AppTheme.silver,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: Text(
                                    sim['model_name'] ?? '',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.ink,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tag Chip ───
class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.bone,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm / 2),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppTheme.ash,
        ),
      ),
    );
  }
}

// ─── Location Item ───
class _LocationItem extends StatelessWidget {
  final String label;
  final String value;

  const _LocationItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            color: AppTheme.silver,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}
