import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'result_screen.dart'; // Import your result screen

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}


class _ScannerScreenState extends State<ScannerScreen> {
  bool _isDetecting = false; // Flag to prevent multiple detections
  String _notificationMessage = ""; // Message to show in the notification

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text("Scan Barcode", style: TextStyle(
                                                          fontSize: 20, // Slightly larger for elegance
                                                          fontWeight: FontWeight.w600, // Semi-bold for a premium feel
                                                          letterSpacing: 0.5, // Subtle spacing for a refined look
                                                          color: Colors.black87, // Darker but not pure black (for a softer look)
                                                        ),
                                                      ),),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (BarcodeCapture barcodeCapture) {
              if (_isDetecting) return; // Prevent multiple detections
              _isDetecting = true; // Set the flag to true to prevent further detections

              final barcode = barcodeCapture.barcodes.first; // Get the first barcode
              final code = barcode.rawValue;
              if (code != null) {
                if (code.length <= 13 && code.length > 11) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ResultScreen(barcode: code)),
                  ).then((_) {
                    // Reset _isDetecting when returning to scan again
                    setState(() {
                      _isDetecting = false;
                    });
                  });
                } else {
                  // Show a notification at the top
                  _showNotification("Valid barcode length. Please try again.");
                  debugPrint("----------------------------------------------------------- barcode: $code");

                  setState(() {
                    Future.delayed(Duration(seconds: 2), () {
                      _isDetecting = false; // Set the flag to true after the first scan
                    });
                  });

                  return; // Don't pop or proceed further if the barcode is invalid
                }

                // If you want to navigate after scanning:
                // Navigator.pop(context, code); // Pass barcode back to previous screen
              }
            },
          ),
          Positioned(
            top: 100, // Adjust to position the text in a visible area
            left: 20,
            child: Material(
              color: Colors.transparent,
              child: Text(
                _notificationMessage,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5), // Semi-transparent white text
                  fontSize: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show a notification at the top of the screen
  bool _displaying = false;
  void _showNotification(String message) {
    // Use a SnackBar to show the message
    if (_displaying) return; 
    _displaying = true; 
    debugPrint("----------------------------------------------------------- message: $message");
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
