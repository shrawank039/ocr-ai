import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class CardDetector {
  late Interpreter interpreter;
  late List<int> inputShape;
  late List<int> outputShape;

  CardDetector() {
    _loadModel();
  }

  Future<void> _loadModel() async {
    // Load the TFLite model from assets
    interpreter = await Interpreter.fromAsset('model.tflite');

    // Get input and output shapes
    inputShape = interpreter.getInputTensor(0).shape;
    outputShape = interpreter.getOutputTensor(0).shape;
  }

  Future<List<dynamic>> detectCard(img.Image image) async {
    // Resize image to the required input size
    img.Image resizedImage =
        img.copyResize(image, width: inputShape[1], height: inputShape[2]);

    // Convert image to Uint8List
    var input = imageToByteList(resizedImage, inputShape[1], inputShape[2]);

    // Prepare output buffer
    var output = List.filled(outputShape.reduce((a, b) => a * b), 0.0)
        .reshape(outputShape);

    // Run inference
    interpreter.run(input, output);

    // Process and return output
    return output;
  }

  Uint8List imageToByteList(img.Image image, int inputSizeX, int inputSizeY) {
    // Resize the image to the input size required by the model.
    img.Image resizedImage =
        img.copyResize(image, width: inputSizeX, height: inputSizeY);

    // Prepare a byte buffer to hold the model input data.
    Uint8List convertedBytes = Uint8List(inputSizeX * inputSizeY * 3);
    ByteData buffer = ByteData.view(convertedBytes.buffer);

    int pixelIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        // Get the pixel value.
        img.Pixel pixel = resizedImage.getPixel(x, y);

        // Extract RGB components from the pixel.
        int red = pixel.r.toInt(); // Convert num to int if necessary.
        int green = pixel.g.toInt(); // Convert num to int if necessary.
        int blue = pixel.b.toInt(); // Convert num to int if necessary.

        // Write RGB values to the byte buffer.
        buffer.setUint8(pixelIndex++, red);
        buffer.setUint8(pixelIndex++, green);
        buffer.setUint8(pixelIndex++, blue);
      }
    }
    return convertedBytes;
  }
}
