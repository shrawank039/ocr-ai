// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_ai/functions/image_pick.dart';
import 'package:ocr_ai/models/OcrResponse.dart';
import 'package:ocr_ai/recognizer/interface/text_recognizer.dart';
import 'package:ocr_ai/recognizer/mlkit_recognizer.dart';
import 'package:ocr_ai/repositories/openai_repo.dart';
import 'package:ocr_ai/ui/data_mapping.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late ImagePicker _picker;
  late ITextRecognizer _recognizer;
  OcrResponse? _response;
  DocumentScanner? _documentScanner;

  DocumentScannerOptions documentOptions = DocumentScannerOptions(
    documentFormat: DocumentFormat.jpeg,
    mode: ScannerMode.filter,
    pageLimit: 1, 
    isGalleryImport: true,
  );

  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();
    _recognizer = MLKitTextRecognizer();
    _documentScanner = DocumentScanner(options: documentOptions);
  }

  @override
  void dispose() {
    super.dispose();
    (_recognizer as MLKitTextRecognizer).dispose();
    (_documentScanner as DocumentScanner).close();
  }

  Future<String?> obtainImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    return file?.path;
  }

  void processOCR(String imgPath) async {
    final text = await _recognizer.processImage(imgPath);
    setState(() {
      _response = OcrResponse(imgPath: imgPath, recognizedText: text);
    });
  }

  void startDocumentScan() async {
    try {
      DocumentScanningResult scannedDocument = await _documentScanner!.scanDocument();
      final imgPath = scannedDocument.images.first;
        processOCR(imgPath);
    } catch (e) {
      debugPrint('Failed to scan document: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR-AI'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: startDocumentScan,
        // () {
        //   showDialog(
        //     context: context,
        //     builder: (context) => imagePickAlert(
        //       onCameraPressed: () async {
        //         final imgPath = await obtainImage(ImageSource.camera);
        //         if (imgPath != null) {
        //           processOCR(imgPath);
        //         }
        //         Navigator.of(context).pop();
        //       },
        //       onGalleryPressed: () async {
        //         final imgPath = await obtainImage(ImageSource.gallery);
        //         if (imgPath != null) {
        //           processOCR(imgPath);
        //         }
        //         Navigator.of(context).pop();
        //       },
        //     ),
        //   );
        // },
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
                        const SizedBox(height: 10),
                        // OpenAI Function
                        if (_response!.recognizedText.isNotEmpty)
                          MaterialButton(
                            color: Colors.black,
                            textColor: Colors.white,
                            child: const Text('Map Data'),
                            onPressed: () async {
                              try {
                                // Call the API to fetch the mapped data
                                final Map<String, dynamic> jsonResponse =
                                    await fetchOpenAIResponse(
                                        _response!.recognizedText);
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => JsonDisplayPage(
                                        jsonResponse: jsonResponse),
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Failed to map data: $e');
                              }
                            },
                          ),
                        const SizedBox(height: 10),
                      ],
                    )),
              ],
            ),
    );
  }
}
