import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerTabWidget extends StatefulWidget {
  final void Function(String barcode) onBarcodeScanned;

  const ScannerTabWidget({super.key, required this.onBarcodeScanned});

  @override
  State<ScannerTabWidget> createState() => _ScannerTabWidgetState();
}

class _ScannerTabWidgetState extends State<ScannerTabWidget> {
  bool _isDetecting = false;
  String _notificationMessage = "";

  void _onBarcodeScanned(String code) {
    if (code.length <= 13 && code.length > 11) {
      widget.onBarcodeScanned(code);
    } else {
      _showNotification("Invalid barcode length. Please try again.");
      Future.delayed(const Duration(seconds: 2), () {
        setState(() => _isDetecting = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // prevent route from being popped automatically
      child: Scaffold(

      appBar: AppBar(title: Text("Scan Barcode", style: TextStyle(
                                                          fontSize: 20, // Slightly larger for elegance
                                                          fontWeight: FontWeight.w600, // Semi-bold for a premium feel
                                                          letterSpacing: 0.5, // Subtle spacing for a refined look
                                                          color: Theme.of(context).colorScheme.onSurface, // Darker but not pure black (for a softer look)
                                                        ),
                                                      ),
                      backgroundColor: Colors.white, // White background for a clean look      
      ),
      body: Stack(
        children: [
          // Scanner or Result based on _barcode
          MobileScanner(
            onDetect: (barcodeCapture) {
              if (_isDetecting) return;
              _isDetecting = true;

              final code = barcodeCapture.barcodes.first.rawValue;
              if (code != null) _onBarcodeScanned(code);
            },
          ),
          // Optional floating message
          if (_notificationMessage.isNotEmpty)
            Positioned(
              top: 100,
              left: 20,
              child: Material(
                color: Colors.transparent,
                child: Text(
                  _notificationMessage,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 32,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }

  // Function to show a notification at the top of the screen
  bool _displaying = false;
  void _showNotification(String message) {
    // Use a SnackBar to show the message
    if (_displaying) return; 
    _displaying = true; 
    setState(() {
      _notificationMessage = message;
    });

    // Hide the notification after 0.5 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      setState(() {
      _notificationMessage = '';
      _displaying = false;
      });
    });
  }



}
