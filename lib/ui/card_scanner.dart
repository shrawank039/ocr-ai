import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class CardScannerScreen extends StatefulWidget {
  @override
  _CardScannerScreenState createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends State<CardScannerScreen> {
  late CameraController _cameraController;
  late Interpreter _interpreter;
  bool _isCameraInitialized = false;
  bool _isModelLoaded = false;
  bool _isDetecting = false;
  Rect? _detectedCardRect;
  String? _croppedCardPath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadModel();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
    await _cameraController.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
    _startCardDetection();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model.tflite');
      setState(() {
        _isModelLoaded = true;
      });
    } catch (e) {
      print('Error loading model: $e');
    }
  }

  void _startCardDetection() {
    _cameraController.startImageStream((image) {
      if (!_isDetecting && _isModelLoaded) {
        _isDetecting = true;
        _detectCard(image);
      }
    });
  }

   Future<void> _detectCard(CameraImage image) async {
    if (_interpreter == null) return;

    try {
      final inputImage = _preprocessImage(image);
      final outputShape = _interpreter!.getOutputTensor(0).shape;
      final outputType = _interpreter!.getOutputTensor(0).type;

      // Create output tensor
      final outputBuffer =
          List<double>.filled(outputShape.reduce((a, b) => a * b), 0)
              .reshape(outputShape);

      // Run inference
      _interpreter!.run(inputImage, outputBuffer);

      Rect? _postprocessOutput(
          List<dynamic> output, int imageWidth, int imageHeight) {
        // Convert outputBuffer to List<double>
        final outputDoubles =
            output.map((element) => element as double).toList();

        // This is a placeholder implementation. You need to adjust this based on your model's output format.
        // For example, if your model outputs [x, y, width, height, confidence] for each detection:
        if (outputDoubles.length >= 5 && outputDoubles[4] > 0.5) {
          // Assuming a confidence threshold of 0.5
          return Rect.fromLTWH(
            outputDoubles[0] * imageWidth,
            outputDoubles[1] * imageHeight,
            outputDoubles[2] * imageWidth,
            outputDoubles[3] * imageHeight,
          );
        }
        return null;
      }

      final detectedRect =
          _postprocessOutput(outputBuffer, image.width, image.height);

      setState(() {
        _detectedCardRect = detectedRect;
      });
    } catch (e) {
      print('Error during detection: $e');
    } finally {
      _isDetecting = false;
    }
  }

  List<double> _preprocessImage(CameraImage image) {
    // Convert YUV420 to RGB
    final rgbImage = img.Image(width: image.width, height: image.height);
    final yBuffer = image.planes[0].bytes;
    final uBuffer = image.planes[1].bytes;
    final vBuffer = image.planes[2].bytes;

    int uvIndex = 0;
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final yValue = yBuffer[y * image.width + x];
        final uValue = uBuffer[uvIndex];
        final vValue = vBuffer[uvIndex];

        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        rgbImage.setPixelRgb(x, y, r, g, b);

        if (x % 2 == 1 && y % 2 == 1) {
          uvIndex++;
        }
      }
    }

    // Resize and normalize the image
    final resizedImage = img.copyResize(rgbImage, width: 300, height: 300);
    // Use imageToByteList method
    final inputBuffer = imageToByteList(resizedImage, 300, 300);
    // Convert Uint8List to List<double>
    final inputDoubles = inputBuffer.map((e) => e.toDouble()).toList();
    return inputDoubles;
  }

  Uint8List imageToByteList(img.Image image, int inputSizeX, int inputSizeY) {
    var resizedImage =
        img.copyResize(image, width: inputSizeX, height: inputSizeY);

    var convertedBytes = Uint8List(inputSizeX * inputSizeY * 3);
    // Get the ByteBuffer from the Uint8List
    var buffer = convertedBytes.buffer.asByteData();

    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        img.Pixel pixel = resizedImage.getPixel(x, y);

        // Extract color channels manually using bitwise operations
        buffer.setUint8(pixelIndex++, (pixel.r.toInt() >> 16) & 0xFF); // Red
        buffer.setUint8(pixelIndex++, (pixel.g.toInt() >> 8) & 0xFF); // Green
        buffer.setUint8(pixelIndex++, pixel.b.toInt() & 0xFF); // Blue
      }
    }
    return convertedBytes;
  }


  Rect? _postprocessOutput(
      List<double> output, int imageWidth, int imageHeight) {
    // This is a placeholder implementation. You need to adjust this based on your model's output format.
    // For example, if your model outputs [x, y, width, height, confidence] for each detection:
    if (output.length >= 5 && output[4] > 0.5) {
      // Assuming a confidence threshold of 0.5
      return Rect.fromLTWH(
        output[0] * imageWidth,
        output[1] * imageHeight,
        output[2] * imageWidth,
        output[3] * imageHeight,
      );
    }
    return null;
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
    if (!_isCameraInitialized || !_isModelLoaded) {
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
    _interpreter.close();
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
