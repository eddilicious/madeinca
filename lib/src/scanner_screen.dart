import 'package:flutter/material.dart';
import 'widgets/scanner_tab_widget.dart';
import 'widgets/result_tab_widget.dart';
import 'widgets/navbar_bottom_widget.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String? _barcode;

  void _onBarcodeScanned(String barcode) {
    setState(() {
      _barcode = barcode;
    });
  }

  void _onBack() {
    setState(() {
      _barcode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _barcode == null
          ? ScannerTabWidget(onBarcodeScanned: _onBarcodeScanned)
          : ResultTabWidget(barcode: _barcode!, onBack: _onBack),
      bottomNavigationBar: const NavbarBottomWidget(currentRoute: '/scanner'),
    );
  }
}
