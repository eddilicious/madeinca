import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String barcode;

  const ResultPage({super.key, required this.barcode});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scanned Barcode")),
      body: GestureDetector(
        onTap: () {
          // Go back to the ScannerPage
          Navigator.pop(context);
        },
        child: Center(
          child: Text(
            "Scanned Code: $barcode",
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}