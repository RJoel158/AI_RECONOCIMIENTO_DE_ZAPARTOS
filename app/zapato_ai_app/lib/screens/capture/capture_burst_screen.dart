import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'capture_form_screen.dart';

class CaptureBurstScreen extends StatefulWidget {
  const CaptureBurstScreen({super.key, this.frames = 4});

  final int frames;

  @override
  State<CaptureBurstScreen> createState() => _CaptureBurstScreenState();
}

class _CaptureBurstScreenState extends State<CaptureBurstScreen> {
  CameraController? _controller;
  bool _isReady = false;
  bool _isCapturing = false;
  int _captured = 0;
  final List<String> _paths = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      return;
    }

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_controller != null && _isReady)
            Positioned.fill(child: CameraPreview(_controller!))
          else
            const Center(child: CircularProgressIndicator()),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  _isCapturing
                      ? 'Capturando $_captured/${widget.frames}'
                      : 'Presiona para capturar varias vistas',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _isCapturing ? null : _captureBurst,
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          color: _isCapturing ? Colors.grey : Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
