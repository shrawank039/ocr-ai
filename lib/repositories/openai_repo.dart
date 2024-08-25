import 'dart:developer';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> fetchOpenAIResponse(String scannedText) async {
  final response = await http.post(
    Uri.parse('https://api.openai.com/v1/chat/completions'),
    headers: {
      'Authorization': 'Bearer ${dotenv.env['OPENAI_API_KEY']}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'model': 'gpt-4o-mini',
      'temperature': 0,
      "response_format": {"type": "json_object"},
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an assistant that extracts structured information from an ocr extracted visiting card text. Format the output as JSON with keys like "name", "address", "phone", "email", etc.',
        },
        {
          'role': 'user',
          'content':
              'Extract the information from the following text: $scannedText.',
        },
      ],
      'max_tokens': 256,
    }),
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    log('jsonData $jsonData');
    final mainContent =
        jsonDecode(jsonData['choices'][0]['message']['content']);
    log('jsonDecode $mainContent');
    return mainContent;
  } else {
    throw Exception('Failed to load data from OpenAI');
  }
}
