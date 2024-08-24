import 'package:flutter/material.dart';

class JsonDisplayPage extends StatelessWidget {
  final Map<String, dynamic> jsonResponse;

  const JsonDisplayPage({required this.jsonResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Extracted Information')),
      body: ListView.builder(
        itemCount: jsonResponse.length,
        itemBuilder: (context, index) {
          String key = jsonResponse.keys.elementAt(index);
          return ListTile(
            title: Text(key),
            subtitle: Text(jsonResponse[key].toString()),
          );
        },
      ),
    );
  }
}
