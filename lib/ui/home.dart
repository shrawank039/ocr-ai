import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_ai/functions/image_pick.dart';
import 'package:ocr_ai/models/OcrResponse.dart';
import 'package:ocr_ai/recognizer/interface/text_recognizer.dart';
import 'package:ocr_ai/recognizer/mlkit_recognizer.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late ImagePicker _picker;
  late ITextRecognizer _recognizer;
  OcrResponse? _response;

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _recognizer = MLKitTextRecognizer();
  }

  @override
  void dispose() {
    super.dispose();
    (_recognizer as MLKitTextRecognizer).dispose();
  }

  Future<String?> obtainImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    return file?.path;
  }

  void processImage(String imgPath) async {
    final text = await _recognizer.processImage(imgPath);
    setState(() {
      _response = OcrResponse(imgPath: imgPath, recognizedText: text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR-AI'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => imagePickAlert(
              onCameraPressed: () async {
                final imgPath = await obtainImage(ImageSource.camera);
                if (imgPath != null) {
                  processImage(imgPath);
                }
                Navigator.of(context).pop();
              },
              onGalleryPressed: () async {
                final imgPath = await obtainImage(ImageSource.gallery);
                if (imgPath != null) {
                  processImage(imgPath);
                }
                Navigator.of(context).pop();
              },
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
       body: _response == null
          ? const Center(
              child: Text('Pick image to continue'),
            )
          : ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.width,
                  width: MediaQuery.of(context).size.width,
                  child: Image.file(File(_response!.imgPath)),
                ),
                Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Recognized Text",
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(
                                      text: _response!.recognizedText),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Copied to Clipboard'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.copy),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(_response!.recognizedText),
                      ],
                    )),
              ],
            ),
    );
  }
}
