import 'package:flutter/material.dart';
import 'scanner_screen.dart'; // Import the BarcodeScannerWithOverlay widget
//import 'services/device_info_services.dart'; // Import the DeviceInfoService

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _onTap() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
      ),
      body: Center(
        child: GestureDetector(
          onTap: _onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Tap the loading indicator to start the barcode scanner',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(), // Circular loading indicator
            ],
          ),
        ),
      ),
    );
  }
}
