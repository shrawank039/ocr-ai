import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(MaterialApp(home: ObjectDetectionPage(camera: cameras.first)));
}

class ObjectDetectionPage extends StatefulWidget {
  final CameraDescription camera;

  const ObjectDetectionPage({Key? key, required this.camera}) : super(key: key);

  @override
  _ObjectDetectionPageState createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends State<ObjectDetectionPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late ObjectDetector _objectDetector;
  bool _isDetecting = false;
  List<DetectedObject> _detectedObjects = [];

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  void _initializeCamera() async {
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _startDetection();
    });
  }

  void _initializeObjectDetector() async {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  void _startDetection() {
    _controller.startImageStream((CameraImage image) {
      if (_isDetecting) return;
      _isDetecting = true;
      _processImage(image);
    });
  }

  void _processImage(CameraImage image) async {
    final InputImage inputImage = InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation
            .rotation0deg, // Adjust based on camera orientation
        format:
            InputImageFormat.nv21, // This format works for most Android devices
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    try {
      final objects = await _objectDetector.processImage(inputImage);
      setState(() {
        _detectedObjects = objects;
      });
    } catch (e) {
      debugPrint('Error processing image: $e');
    }

    _isDetecting = false;
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _controller.dispose();
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Real-time Object Detection')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                CameraPreview(_controller),
                CustomPaint(
                  painter: ObjectPainter(
                      _detectedObjects, _controller.value.previewSize!),
                ),
              ],
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class ObjectPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;

  ObjectPainter(this.objects, this.imageSize);

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (DetectedObject detectedObject in objects) {
      final Rect scaledRect = Rect.fromLTRB(
        detectedObject.boundingBox.left * scaleX,
        detectedObject.boundingBox.top * scaleY,
        detectedObject.boundingBox.right * scaleX,
        detectedObject.boundingBox.bottom * scaleY,
      );

      canvas.drawRect(scaledRect, paint);

      TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: detectedObject.labels.isNotEmpty
              ? '${detectedObject.labels.first.text} ${(detectedObject.labels.first.confidence * 100).toStringAsFixed(0)}%'
              : 'Unknown',
          style: TextStyle(color: Colors.red, fontSize: 18),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(scaledRect.left, scaledRect.top - textPainter.height),
      );
    }
  }

  @override
  bool shouldRepaint(ObjectPainter oldDelegate) => true;
}
