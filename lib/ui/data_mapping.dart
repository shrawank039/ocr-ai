import 'package:flutter/material.dart';

class JsonDisplayPage extends StatelessWidget {
  final Map<String, dynamic> jsonResponse;

  const JsonDisplayPage({super.key, required this.jsonResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extracted Information')),
      body: ListView.builder(
        itemCount: jsonResponse.length,
        itemBuilder: (context, index) {
          String key = jsonResponse.keys.elementAt(index);
          return ListTile(
            title: Text(key),
            subtitle: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.grey, 
                  width: 1.0, 
                ),
                borderRadius:
                    BorderRadius.circular(5.0), 
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 8.0, vertical: 4.0), 
              child: TextField(
                controller:
                    TextEditingController(text: jsonResponse[key].toString()),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
