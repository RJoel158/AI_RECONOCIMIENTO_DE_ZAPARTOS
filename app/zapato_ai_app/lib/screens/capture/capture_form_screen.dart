import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';

class CaptureFormScreen extends StatefulWidget {
  const CaptureFormScreen({super.key, required this.imagePaths});

  final List<String> imagePaths;

  @override
  State<CaptureFormScreen> createState() => _CaptureFormScreenState();
}

class _CaptureFormScreenState extends State<CaptureFormScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _colorPrimaryController = TextEditingController();
  final TextEditingController _colorSecondaryController =
      TextEditingController();
  final TextEditingController _materialController = TextEditingController();
  final TextEditingController _aisleController = TextEditingController();
  final TextEditingController _shelfController = TextEditingController();
  final TextEditingController _shelfLevelController = TextEditingController();

  String? _referenceImagePath;
  bool _isSaving = false;

  @override
  void dispose() {
    _skuController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _typeController.dispose();
    _colorPrimaryController.dispose();
    _colorSecondaryController.dispose();
    _materialController.dispose();
    _aisleController.dispose();
    _shelfController.dispose();
    _shelfLevelController.dispose();
    super.dispose();
  }

  Future<void> _saveCapture() async {
    if (!_formKey.currentState!.validate()) return;

    if (widget.imagePaths.isEmpty) {
      _showSnack('Debes capturar imágenes');
      return;
    }

    if (_referenceImagePath == null) {
      _showSnack('Selecciona una imagen referencial');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final sku = _skuController.text.trim();
      final payload = {
        'sku': sku,
        'brand': _brandController.text.trim(),
        'model_name': _modelController.text.trim(),
        'type': _typeController.text.trim(),
        'color_primary': _colorPrimaryController.text.trim(),
        'color_secondary': _colorSecondaryController.text.trim(),
        'material': _materialController.text.trim(),
        'aisle': _aisleController.text.trim(),
        'shelf': _shelfController.text.trim(),
        'shelf_level': _shelfLevelController.text.trim(),
      };

      // Step 1: Create product
      await _apiService.createProduct(payload);

      // Step 2: Upload reference image → sets image_path in DB
      try {
        await _apiService.uploadProductImage(
          sku: sku,
          imagePath: _referenceImagePath!,
        );
      } catch (e) {
        _showSnack('Producto creado, pero error al subir imagen: $e');
      }

      // Step 3: Upload capture images for training
      try {
        await _apiService.createCapture(
          sku: sku,
          imagePaths: widget.imagePaths,
          source: 'app',
        );
      } catch (e) {
        _showSnack('Producto creado, pero error en capturas: $e');
      }

      if (!mounted) return;
      _showSnack('Producto y captura guardados ✓');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error al crear producto: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool requiredField = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 15,
          color: AppTheme.ink,
        ),
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: AppTheme.silver)
              : null,
        ),
        validator: requiredField
            ? (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Requerido';
                }
                return null;
              }
            : null,
      ),
    );
  }

  Future<void> _pickReferenceImage(ImageSource source) async {
    final XFile? photo = await _picker.pickImage(
      source: source,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _referenceImagePath = photo.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      appBar: AppBar(
        title: Text(
          'Registrar Modelo',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Captured Images ───
                _SectionHeader(
                  title: 'Capturas',
                  trailing: '${widget.imagePaths.length} fotos',
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final path = widget.imagePaths[index];
                      return Container(
                        width: 88,
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusSm),
                          child: Image.file(File(path), fit: BoxFit.cover),
                        ),
                      );
                    },
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemCount: widget.imagePaths.length,
                  ),
                ),

                const SizedBox(height: 28),

                // ─── Reference Image ───
                _SectionHeader(
                  title: 'Imagen referencial',
                  trailing: 'Para el catálogo',
                ),
                const SizedBox(height: 10),
                if (_referenceImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                        child: Image.file(
                          File(_referenceImagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickReferenceImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_rounded, size: 18),
                        label: const Text('Cámara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickReferenceImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Galería'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ─── Product Info ───
                _SectionHeader(title: 'Información del producto'),
                const SizedBox(height: 14),
                _buildField('Código Producto', _skuController,
                    requiredField: true, icon: Icons.qr_code_rounded),
                _buildField('Marca', _brandController,
                    requiredField: true, icon: Icons.business_rounded),
                _buildField('Modelo', _modelController,
                    requiredField: true, icon: Icons.label_outline_rounded),
                _buildField('Tipo', _typeController,
                    requiredField: true, icon: Icons.category_rounded),
                _buildField('Color primario', _colorPrimaryController,
                    requiredField: true, icon: Icons.palette_rounded),
                _buildField('Color secundario', _colorSecondaryController,
                    icon: Icons.palette_outlined),
                _buildField('Material', _materialController,
                    icon: Icons.texture_rounded),

                const SizedBox(height: 12),

                // ─── Location ───
                _SectionHeader(title: 'Ubicación en almacén'),
                const SizedBox(height: 14),
                _buildField('Pasillo', _aisleController,
                    icon: Icons.signpost_rounded),
                _buildField('Estante', _shelfController,
                    icon: Icons.shelves),
                _buildField('Nivel', _shelfLevelController,
                    icon: Icons.layers_rounded),

                const SizedBox(height: 24),

                // ─── Save Button ───
                AnimatedContainer(
                  duration: AppTheme.fast,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveCapture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.ink,
                      foregroundColor: AppTheme.cream,
                      disabledBackgroundColor: AppTheme.graphite,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusMd),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppTheme.citrus),
                            ),
                          )
                        : Text(
                            'GUARDAR PRODUCTO',
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Section Header ───
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.ash,
            letterSpacing: 2,
          ),
        ),
        if (trailing != null)
          Text(
            trailing!,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: AppTheme.silver,
            ),
          ),
      ],
    );
  }
}
