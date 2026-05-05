import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/api/api_service.dart';
import '../details/details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  final List<String> _capturedImages = [];
  bool _isProcessing = false;

  // Consenso Temporal: Capturamos ráfaga de 4 fotos
  Future<void> _captureFrame() async {
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (photo != null) {
      setState(() {
        _capturedImages.add(photo.path);
      });

      if (_capturedImages.length >= 4) {
        _processAndRecognize();
      }
    }
  }

  Future<void> _processAndRecognize() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _apiService.recognizeShoe(_capturedImages);
      
      if (result['details'] != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(productData: result['details'] as Map<String, dynamic>),
          ),
        );
      } else if (mounted) {
        _showError("No se pudo reconocer el modelo. Inténtalo de nuevo.");
      }
    } catch (e) {
      if (mounted) {
        _showError("Error de conexión: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _capturedImages.clear();
        });
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Simulated Camera View (Full screen)
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[900],
            child: Center(
              child: Text(
                "Sigue girando el zapato...\n${_capturedImages.length}/4 fotos",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          
          // Top Controls
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Capture Button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: _isProcessing 
                ? const CircularProgressIndicator(color: Colors.white)
                : GestureDetector(
                    onTap: _captureFrame,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                      ),
                      child: Center(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
