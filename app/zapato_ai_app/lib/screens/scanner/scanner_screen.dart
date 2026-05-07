import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_config.dart';
import '../../core/api/api_service.dart';
import '../../core/theme/app_theme.dart';
import '../details/details_screen.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  CameraController? _controller;
  final List<String> _capturedImages = [];
  bool _isReady = false;
  bool _isProcessing = false;
  int _captured = 0;
  static const int _totalFrames = 15;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await controller.initialize();
    if (!mounted) return;
    setState(() {
      _controller = controller;
      _isReady = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _pulseController.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _captureBurst() async {
    if (_controller == null || !_isReady || _isProcessing) return;

    setState(() {
      _capturedImages.clear();
      _captured = 0;
    });

    for (int i = 0; i < _totalFrames; i++) {
      final file = await _controller!.takePicture();
      _capturedImages.add(file.path);
      if (!mounted) return;
      setState(() {
        _captured = i + 1;
      });
      await Future.delayed(const Duration(milliseconds: 250));
    }

    await _processAndRecognize();
  }

  Future<void> _processAndRecognize() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _apiService.recognizeShoe(_capturedImages);
      if (!mounted) return;

      // Direct match — go straight to details
      if (result['details'] != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailsScreen(
              productData: result['details'] as Map<String, dynamic>,
            ),
          ),
        );
        return;
      }

      // Candidates available — show selection sheet
      final candidates = result['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        _showCandidateSheet(candidates);
      } else {
        _showError(result['message'] ?? 'No se encontraron coincidencias');
      }
    } catch (e) {
      if (mounted) {
        _showError('Error de conexión: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _captured = 0;
        });
      }
    }
  }

  void _showCandidateSheet(List<dynamic> candidates) {
    final baseUrl = ApiConfig.baseUrl;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.55,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cream,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTheme.radiusXl),
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 16),
              Text(
                '¿Es alguno de estos?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Selecciona el modelo que coincida',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: AppTheme.ash,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: candidates.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final c = candidates[index] as Map<String, dynamic>;
                    final sku = c['sku'] as String;
                    final score = (c['score'] as num).toDouble();
                    final percent = (score * 100).toInt();
                    final thumbUrl = '$baseUrl/products/$sku/thumbnail';

                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final nav = Navigator.of(context);
                        // Fetch full details for this SKU
                        try {
                          final details =
                              await _apiService.getProductBySku(sku);
                          if (!mounted) return;
                          if (details['details'] != null) {
                            nav.push(
                              MaterialPageRoute(
                                builder: (_) => DetailsScreen(
                                  productData: details['details']
                                      as Map<String, dynamic>,
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          _showError('Error al cargar detalles: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMd),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Thumbnail
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: AppTheme.bone,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusSm),
                                child: Image.network(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.image_outlined,
                                    color: AppTheme.silver,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sku,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // Score bar
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(2),
                                          child:
                                              LinearProgressIndicator(
                                            value: score,
                                            backgroundColor: AppTheme
                                                .bone,
                                            valueColor:
                                                AlwaysStoppedAnimation<
                                                    Color>(
                                              score > 0.7
                                                  ? AppTheme.success
                                                  : score > 0.4
                                                      ? AppTheme.citrus
                                                      : AppTheme.error,
                                            ),
                                            minHeight: 4,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '$percent%',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.ash,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: AppTheme.silver,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Ninguno — intentar de nuevo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
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

  @override
  Widget build(BuildContext context) {
    final progress = _captured / _totalFrames;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ─── Camera Preview ───
          if (_controller != null && _isReady)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            Center(
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
                    'Iniciando cámara...',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppTheme.silver,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // ─── Scan Overlay ───
          if (_isReady)
            Positioned.fill(
              child: CustomPaint(
                painter: _ScanOverlayPainter(
                  progress: progress,
                  scanProgress: _scanLineController.value,
                  isCapturing: _captured > 0 || _isProcessing,
                ),
              ),
            ),

          // ─── Top Bar ───
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: AppTheme.glassDecoration(
                        radius: AppTheme.radiusSm,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'ESCANEAR',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),

                  const SizedBox(width: 40), // balance
                ],
              ),
            ),
          ),

          // ─── Bottom Controls ───
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
                left: 32,
                right: 32,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status text
                  AnimatedSwitcher(
                    duration: AppTheme.fast,
                    child: Text(
                      _isProcessing
                          ? 'Procesando reconocimiento...'
                          : _captured > 0
                              ? 'Capturando vistas  $_captured/$_totalFrames'
                              : 'Apunta al calzado y presiona',
                      key: ValueKey('$_captured-$_isProcessing'),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Progress bar
                  if (_captured > 0 || _isProcessing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: _isProcessing ? null : progress,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.citrus,
                          ),
                          minHeight: 3,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Capture button
                  GestureDetector(
                    onTap: _isProcessing ? null : _captureBurst,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale =
                            (_captured > 0 || _isProcessing) ? 1.0 : _pulseAnimation.value;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isProcessing
                                    ? AppTheme.citrus.withValues(alpha: 0.4)
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                if (!_isProcessing)
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppTheme.fast,
                                width: _isProcessing ? 28 : 58,
                                height: _isProcessing ? 28 : 58,
                                decoration: BoxDecoration(
                                  color: _isProcessing
                                      ? AppTheme.citrus
                                      : Colors.white,
                                  shape: _isProcessing
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: _isProcessing
                                      ? BorderRadius.circular(6)
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Scan Overlay Painter ───
class _ScanOverlayPainter extends CustomPainter {
  final double progress;
  final double scanProgress;
  final bool isCapturing;

  _ScanOverlayPainter({
    required this.progress,
    required this.scanProgress,
    required this.isCapturing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final rectSize = size.width * 0.65;
    final rect = Rect.fromCenter(
      center: center,
      width: rectSize,
      height: rectSize,
    );

    // Dimmed area outside scan rect
    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(20)),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);

    // Corner accents
    final cornerLength = 28.0;
    final cornerPaint = Paint()
      ..color = isCapturing ? AppTheme.citrus : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomLeft,
      rect.bottomRight,
    ];

    for (int i = 0; i < corners.length; i++) {
      final c = corners[i];
      final hDir = (i % 2 == 0) ? 1.0 : -1.0;
      final vDir = (i < 2) ? 1.0 : -1.0;

      canvas.drawLine(
        Offset(c.dx, c.dy + vDir * 8),
        Offset(c.dx, c.dy + vDir * cornerLength),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(c.dx + hDir * 8, c.dy),
        Offset(c.dx + hDir * cornerLength, c.dy),
        cornerPaint,
      );
    }

    // Scan line (only when not capturing)
    if (!isCapturing) {
      final scanY = rect.top + rect.height * scanProgress;
      final scanPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.4),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(rect.left, scanY - 1, rect.width, 2));

      canvas.drawLine(
        Offset(rect.left + 20, scanY),
        Offset(rect.right - 20, scanY),
        scanPaint..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScanOverlayPainter old) => true;
}
