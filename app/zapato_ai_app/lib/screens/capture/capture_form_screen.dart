import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/api_service.dart';

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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (widget.imagePaths.isEmpty) {
      _showSnack('Debes capturar imagenes');
      return;
    }

    if (_referenceImagePath == null) {
      _showSnack('Selecciona una imagen referencial');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final payload = {
        'sku': _skuController.text.trim(),
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

      await _apiService.createProduct(payload);
      await _apiService.uploadProductImage(
        sku: _skuController.text.trim(),
        imagePath: _referenceImagePath!,
      );
      await _apiService.createCapture(
        sku: _skuController.text.trim(),
        imagePaths: widget.imagePaths,
        source: 'app',
      );

      if (!mounted) return;
      _showSnack('Producto y captura guardados');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildField(
    String label,
    TextEditingController controller, {
    bool requiredField = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: requiredField ? '$label *' : label,
          border: const OutlineInputBorder(),
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
      appBar: AppBar(title: const Text('Registrar modelo')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Capturas: ${widget.imagePaths.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final path = widget.imagePaths[index];
                      return Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemCount: widget.imagePaths.length,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Imagen referencial (para el catalogo)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_referenceImagePath != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_referenceImagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _pickReferenceImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera),
                        label: const Text('Camara'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _pickReferenceImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Galeria'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildField('SKU', _skuController, requiredField: true),
                _buildField('Marca', _brandController, requiredField: true),
                _buildField('Modelo', _modelController, requiredField: true),
                _buildField('Tipo', _typeController, requiredField: true),
                _buildField(
                  'Color primario',
                  _colorPrimaryController,
                  requiredField: true,
                ),
                _buildField('Color secundario', _colorSecondaryController),
                _buildField('Material', _materialController),
                _buildField('Pasillo', _aisleController),
                _buildField('Estante', _shelfController),
                _buildField('Nivel', _shelfLevelController),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveCapture,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
