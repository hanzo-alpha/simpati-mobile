import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FrontCameraSelfieScreen extends StatefulWidget {
  const FrontCameraSelfieScreen({super.key});

  @override
  State<FrontCameraSelfieScreen> createState() =>
      _FrontCameraSelfieScreenState();
}

enum LivenessStep { alignFace, blinkEyes, smileFace, verified }

class _FrontCameraSelfieScreenState extends State<FrontCameraSelfieScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  late CameraDescription _cameraDescription;
  bool _isInitializing = true;
  bool _isCapturing = false;
  bool _isProcessingFrame = false;
  String? _errorMessage;

  // ML Kit Face Detector
  late final FaceDetector _faceDetector;

  // Real Liveness Detection State
  LivenessStep _currentStep = LivenessStep.alignFace;
  double _livenessProgress = 0.15;
  double? _lastLeftEyeOpen;
  double? _lastRightEyeOpen;
  double? _lastSmileProb;

  late AnimationController _pulseController;
  late Animation<double> _ringGlowAnimation;

  final Map<DeviceOrientation, int> _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _ringGlowAnimation = Tween<double>(begin: 3.0, end: 7.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Initialize ML Kit Face Detector with classification enabled (Smile & Eyes)
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);

    _initFrontCamera();
  }

  Future<void> _initFrontCamera() async {
    try {
      final cameras = await availableCameras();
      _cameraDescription = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        _cameraDescription,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitializing = false;
        });

        // Start processing live camera frames for ML Kit face detection
        controller.startImageStream(_processCameraFrame);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal membuka kamera depan: $e';
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    if (_isProcessingFrame ||
        _isCapturing ||
        _currentStep == LivenessStep.verified) {
      return;
    }

    _isProcessingFrame = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final List<Face> faces = await _faceDetector.processImage(inputImage);

        if (faces.isNotEmpty && mounted) {
          final Face face = faces.first;

          final double? leftEye = face.leftEyeOpenProbability;
          final double? rightEye = face.rightEyeOpenProbability;
          final double? smile = face.smilingProbability;

          setState(() {
            _lastLeftEyeOpen = leftEye;
            _lastRightEyeOpen = rightEye;
            _lastSmileProb = smile;
          });

          // Step 1: Align Face Detected
          if (_currentStep == LivenessStep.alignFace) {
            setState(() {
              _currentStep = LivenessStep.blinkEyes;
              _livenessProgress = 0.40;
            });
          }
          // Step 2: Detect Real Eye Blink (Either eye probability drops below 0.35)
          else if (_currentStep == LivenessStep.blinkEyes) {
            if ((leftEye != null && leftEye < 0.35) ||
                (rightEye != null && rightEye < 0.35)) {
              setState(() {
                _currentStep = LivenessStep.smileFace;
                _livenessProgress = 0.75;
              });
            }
          }
          // Step 3: Detect Real Smile Expression (Smile probability above 0.50)
          else if (_currentStep == LivenessStep.smileFace) {
            if (smile != null && smile > 0.50) {
              setState(() {
                _currentStep = LivenessStep.verified;
                _livenessProgress = 1.0;
              });
              _controller?.stopImageStream();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('ML Kit Face Detection Error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_controller == null) return null;

    final sensorOrientation = _cameraDescription.sensorOrientation;
    InputImageRotation? rotation;
    if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (_cameraDescription.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    } else if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    }
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null ||
        (Platform.isAndroid &&
            format != InputImageFormat.nv21 &&
            format != InputImageFormat.yuv420) ||
        (Platform.isIOS && format != InputImageFormat.bgra8888)) {
      return null;
    }

    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _captureSelfie() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      final XFile photo = await _controller!.takePicture();
      if (mounted) {
        Navigator.pop(context, photo);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCapturing = false);
      }
    }
  }

  @override
  void dispose() {
    _faceDetector.close();
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Deteksi Ekspresi & Liveness',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isInitializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D9488)),
                  SizedBox(height: 16),
                  Text(
                    'Inisialisasi Deteksi Wajah...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.camera_front_outlined,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _initFrontCamera,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D9488),
                      ),
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            )
          : AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final bool isVerified = _currentStep == LivenessStep.verified;
                final Color strokeColor = isVerified
                    ? const Color(0xFF10B981) // Emerald Success
                    : const Color(0xFF0D9488); // Teal Active

                return Stack(
                  children: [
                    // 1. Live Camera Preview
                    Positioned.fill(child: CameraPreview(_controller!)),

                    // 2. Professional Dark Vignette Mask with Oval Face Cutout
                    Positioned.fill(
                      child: CustomPaint(
                        painter: FaceCutoutOverlayPainter(
                          strokeColor: strokeColor,
                          strokeWidth: _ringGlowAnimation.value,
                          isVerified: isVerified,
                        ),
                      ),
                    ),

                    // 3. Top Active Liveness Challenge Card
                    Positioned(
                      top: 16,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A).withAlpha(225),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: strokeColor.withAlpha(160),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: strokeColor.withAlpha(60),
                              blurRadius: 20,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildChallengeIcon(),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _getChallengeTitle(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Live AI Probability Telemetry Feedback
                            if (!isVerified)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Mata (L/R): ${((_lastLeftEyeOpen ?? 1.0) * 100).toInt()}% / ${((_lastRightEyeOpen ?? 1.0) * 100).toInt()}% | Senyum: ${((_lastSmileProb ?? 0.0) * 100).toInt()}%',
                                    style: GoogleFonts.inter(
                                      color: Colors.white70,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),

                            // Progress Indicator Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _livenessProgress,
                                minHeight: 5,
                                backgroundColor: Colors.white.withAlpha(30),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  strokeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 4. Shutter Capture Button (Unlocked on Verification)
                    Positioned(
                      bottom: 36,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isVerified)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF10B981,
                                      ).withAlpha(100),
                                      blurRadius: 16,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'DETEKSI WAJAH SUKSES',
                                      style: GoogleFonts.outfit(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            GestureDetector(
                              onTap: _isCapturing ? null : _captureSelfie,
                              child: Container(
                                width: 82,
                                height: 82,
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 4,
                                  ),
                                  color: strokeColor.withAlpha(220),
                                  boxShadow: [
                                    BoxShadow(
                                      color: strokeColor.withAlpha(100),
                                      blurRadius: 25,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: _isCapturing
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      )
                                    : Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                        ),
                                        child: Icon(
                                          Icons.camera_alt_rounded,
                                          color: strokeColor,
                                          size: 38,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildChallengeIcon() {
    switch (_currentStep) {
      case LivenessStep.alignFace:
        return const Icon(
          Icons.face_rounded,
          color: Color(0xFF38BDF8),
          size: 22,
        );
      case LivenessStep.blinkEyes:
        return const Icon(
          Icons.remove_red_eye_rounded,
          color: Color(0xFFF59E0B),
          size: 22,
        );
      case LivenessStep.smileFace:
        return const Icon(
          Icons.sentiment_very_satisfied_rounded,
          color: Color(0xFFEC4899),
          size: 22,
        );
      case LivenessStep.verified:
        return const Icon(
          Icons.verified_rounded,
          color: Color(0xFF10B981),
          size: 22,
        );
    }
  }

  String _getChallengeTitle() {
    switch (_currentStep) {
      case LivenessStep.alignFace:
        return 'Mendeteksi Wajah...';
      case LivenessStep.blinkEyes:
        return 'Silakan Kedipkan Mata';
      case LivenessStep.smileFace:
        return 'Silakan Tersenyum';
      case LivenessStep.verified:
        return 'Verifikasi Wajah Berhasil! Tekan Tombol Foto';
    }
  }
}

/// Custom Painter that creates a dark professional vignette mask with a crisp PERFECT CIRCLE Cutout
class FaceCutoutOverlayPainter extends CustomPainter {
  final Color strokeColor;
  final double strokeWidth;
  final bool isVerified;

  FaceCutoutOverlayPainter({
    required this.strokeColor,
    required this.strokeWidth,
    required this.isVerified,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dark Vignette Background Mask
    final backgroundPaint = Paint()
      ..color = Colors.black.withAlpha(190)
      ..style = PaintingStyle.fill;

    // Perfect Circle dimensions (Radius = 38% of screen width)
    final double circleRadius = size.width * 0.38;
    final Offset center = Offset(size.width / 2, size.height / 2 - 30);

    final Rect circleRect = Rect.fromCircle(
      center: center,
      radius: circleRadius,
    );

    // Create Path with difference cutout
    final fullScreenPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final circlePath = Path()..addOval(circleRect);
    final cutoutPath = Path.combine(
      PathOperation.difference,
      fullScreenPath,
      circlePath,
    );

    canvas.drawPath(cutoutPath, backgroundPaint);

    // 2. Glowing Outer Ring around Perfect Circle Cutout
    final borderPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, circleRadius, borderPaint);

    // 3. Corner Accent Markers (High Tech HUD Styling around Circle)
    final hudPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final double hudLen = 20;
    // Top-Left corner tick
    canvas.drawLine(
      Offset(center.dx - circleRadius - 6, center.dy - circleRadius + hudLen),
      Offset(center.dx - circleRadius - 6, center.dy - circleRadius - 6),
      hudPaint,
    );
    canvas.drawLine(
      Offset(center.dx - circleRadius - 6, center.dy - circleRadius - 6),
      Offset(center.dx - circleRadius + hudLen, center.dy - circleRadius - 6),
      hudPaint,
    );

    // Top-Right corner tick
    canvas.drawLine(
      Offset(center.dx + circleRadius + 6, center.dy - circleRadius + hudLen),
      Offset(center.dx + circleRadius + 6, center.dy - circleRadius - 6),
      hudPaint,
    );
    canvas.drawLine(
      Offset(center.dx + circleRadius + 6, center.dy - circleRadius - 6),
      Offset(center.dx + circleRadius - hudLen, center.dy - circleRadius - 6),
      hudPaint,
    );
  }

  @override
  bool shouldRepaint(FaceCutoutOverlayPainter oldDelegate) {
    return oldDelegate.strokeColor != strokeColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isVerified != isVerified;
  }
}
