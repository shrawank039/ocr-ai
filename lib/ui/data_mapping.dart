import 'package:flutter/material.dart';

class JsonDisplayPage extends StatelessWidget {
  final Map<String, dynamic> jsonResponse;

  const JsonDisplayPage({super.key, required this.jsonResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Extracted Information')),
      body: ListView(
        children: _buildJsonWidgets(jsonResponse),
      ),
    );
  }

  // Recursive function to build widgets for each key-value pair
  List<Widget> _buildJsonWidgets(Map<String, dynamic> json) {
    List<Widget> widgets = [];

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        // If the value is a map, recursively build its key-value pairs
        widgets.add(
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _buildJsonWidgets(value),
            ),
        );
      } else if (value is List) {
        // If the value is a list, handle each item in the list
        widgets.add(ListTile(title: Text(key)));
        for (var item in value) {
          if (item is Map<String, dynamic>) {
            widgets.add(Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildJsonWidgets(item),
              ),
            ));
          } else {
            widgets.add(Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ListTile(
                title: Text(item.toString()),
                subtitle: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1.0,
                    ),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: TextField(
                    controller: TextEditingController(text: item.toString()),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ),
            ));
          }
        }
      } else {
        // If the value is neither a map nor a list, just display it as a key-value pair
        widgets.add(ListTile(
          title: Text(key),
          subtitle: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey,
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(5.0),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: TextEditingController(text: value.toString()),
              decoration: const InputDecoration(
                border: InputBorder.none,
              ),
            ),
          ),
        ));
      }
    });

    return widgets;
  }
}
