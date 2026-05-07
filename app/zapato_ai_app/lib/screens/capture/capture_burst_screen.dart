import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import 'capture_form_screen.dart';

class CaptureBurstScreen extends StatefulWidget {
  const CaptureBurstScreen({super.key, this.frames = 15});

  final int frames;

  @override
  State<CaptureBurstScreen> createState() => _CaptureBurstScreenState();
}

class _CaptureBurstScreenState extends State<CaptureBurstScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;
  int _captured = 0;
  final List<String> _paths = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    super.dispose();
  }

  Future<void> _captureBurst() async {
    if (_controller == null || !_isReady || _isCapturing) return;

    setState(() {
      _isCapturing = true;
      _captured = 0;
      _paths.clear();
    });

    for (int i = 0; i < widget.frames; i++) {
      final file = await _controller!.takePicture();
      _paths.add(file.path);
      if (!mounted) return;
      setState(() {
        _captured = i + 1;
      });
      await Future.delayed(const Duration(milliseconds: 250));
    }

    if (!mounted) return;
    setState(() {
      _isCapturing = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CaptureFormScreen(imagePaths: _paths),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress =
        widget.frames > 0 ? _captured / widget.frames : 0.0;

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

          // ─── Scan Frame ───
          if (_isReady)
            Positioned.fill(
              child: CustomPaint(
                painter: _CaptureOverlayPainter(isCapturing: _isCapturing),
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
                  Text(
                    'REGISTRAR',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(width: 40),
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
                      _isCapturing
                          ? 'Capturando  $_captured/${widget.frames}'
                          : 'Presiona para capturar ${widget.frames} vistas',
                      key: ValueKey(_captured),
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
                  if (_isCapturing)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: progress,
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
                    onTap: _isCapturing ? null : _captureBurst,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        final scale =
                            _isCapturing ? 1.0 : _pulseAnimation.value;
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _isCapturing
                                    ? AppTheme.citrus.withValues(alpha: 0.4)
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                if (!_isCapturing)
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                  ),
                              ],
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: AppTheme.fast,
                                width: _isCapturing ? 28 : 58,
                                height: _isCapturing ? 28 : 58,
                                decoration: BoxDecoration(
                                  color: _isCapturing
                                      ? AppTheme.citrus
                                      : Colors.white,
                                  shape: _isCapturing
                                      ? BoxShape.rectangle
                                      : BoxShape.circle,
                                  borderRadius: _isCapturing
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

// ─── Capture Overlay ───
class _CaptureOverlayPainter extends CustomPainter {
  final bool isCapturing;

  _CaptureOverlayPainter({required this.isCapturing});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final rectSize = size.width * 0.65;
    final rect = Rect.fromCenter(
      center: center,
      width: rectSize,
      height: rectSize,
    );

    final dimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(20)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, dimPaint);

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
  }

  @override
  bool shouldRepaint(covariant _CaptureOverlayPainter old) =>
      old.isCapturing != isCapturing;
}
