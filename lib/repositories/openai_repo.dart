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
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an assistant that extracts structured information from text.',
        },
        {
          'role': 'user',
          'content':
              'Extract the name, address, contact details, and other relevant information from the following text: $scannedText. Format the output as JSON with keys like "name", "address", "contact", etc.',
        },
      ],
      'max_tokens': 150,
    }),
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    return jsonDecode(jsonData['choices'][0]['message']['content']);
  } else {
    throw Exception('Failed to load data from OpenAI');
  }
}
