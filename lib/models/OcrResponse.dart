class OcrResponse {
  final String imgPath;
  final String recognizedText;

  OcrResponse({
    required this.imgPath,
    required this.recognizedText,
  });

@override
  bool operator ==(covariant OcrResponse other) {
    if (identical(this, other)) return true;

    return other.imgPath == imgPath && other.recognizedText == recognizedText;
  }

  @override
  int get hashCode => imgPath.hashCode ^ recognizedText.hashCode;

}
