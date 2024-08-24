import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CardScannerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CardScannerScreen(),
    );
  }
}

class CardScannerScreen extends StatefulWidget {
  @override
  _CardScannerScreenState createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  late CameraController _cameraController;
  late ObjectDetector _objectDetector;
  bool _isCameraInitialized = false;
  bool _isDetecting = false;
  Rect? _detectedCardRect;
  String? _croppedCardPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeDetector();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _startCardDetection();
  }

  void _initializeDetector() async {
    final modelPath = 'assets/ml/object_labeler.tflite';
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: false,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _startCardDetection() {
    _cameraController.startImageStream((image) {
      if (!_isDetecting) {
        _isDetecting = true;
        _processImage(image);
      }
    });
  }

  void _processImage(CameraImage image) async {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final InputImageRotation imageRotation = InputImageRotation.rotation0deg;

    final InputImageFormat inputImageFormat = InputImageFormat.yuv420;

    // final planeData = image.planes.map(
    //   (Plane plane) {
    //     return InputImagePlaneMetadata(
    //       bytesPerRow: plane.bytesPerRow,
    //       height: plane.height,
    //       width: plane.width,
    //     );
    //   },
    // ).toList();

    final inputImageData = InputImageMetadata(
      size: imageSize,
      rotation: imageRotation,
      format: inputImageFormat,
      bytesPerRow: 100000,
    );

    final inputImage = InputImage.fromBytes(
      bytes: bytes,
      metadata: inputImageData,
    );

    final objects = await _objectDetector.processImage(inputImage);

    for (DetectedObject object in objects) {
      if (object.labels
          .any((label) => label.text.toLowerCase().contains('card'))) {
        setState(() {
          _detectedCardRect = object.boundingBox;
        });
        break;
      }
    }

    _isDetecting = false;
  }

  Future<String?> _captureAndCropCard() async {
    if (_detectedCardRect == null) return null;

    final image = await _cameraController.takePicture();
    final capturedImage =
        img.decodeImage(await File(image.path).readAsBytes())!;

    final croppedImage = img.copyCrop(
      capturedImage,
      x: _detectedCardRect!.left.toInt(),
      y: _detectedCardRect!.top.toInt(),
      width: _detectedCardRect!.width.toInt(),
      height: _detectedCardRect!.height.toInt(),
    );

    final directory = await getApplicationDocumentsDirectory();
    final croppedImagePath = path.join(
        directory.path, 'card_${DateTime.now().millisecondsSinceEpoch}.png');
    final croppedImageFile = File(croppedImagePath);
    await croppedImageFile.writeAsBytes(img.encodePng(croppedImage));

    return croppedImagePath;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Card Scanner')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController),
          if (_detectedCardRect != null)
            CustomPaint(
              painter: CardOverlayPainter(_detectedCardRect!),
            ),
          if (_croppedCardPath != null)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(_croppedCardPath!)),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          final croppedPath = await _captureAndCropCard();
          if (croppedPath != null) {
            setState(() {
              _croppedCardPath = croppedPath;
            });
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _objectDetector.close();
    super.dispose();
  }
}

class CardOverlayPainter extends CustomPainter {
  final Rect cardRect;

  CardOverlayPainter(this.cardRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(cardRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
