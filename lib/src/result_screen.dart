import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'services/barcode_data_services.dart'; // Import the BarcodeDataServices
import 'services/rate_app_services.dart'; // Import the RateAppService
import 'custom_progress_widget.dart'; // Import the CustomProgressIndicator widget
import 'web_display_widget.dart'; // Import the WebDisplayWidget

class ResultScreen extends StatefulWidget {
  final String barcode;
  const ResultScreen({super.key, required this.barcode});
  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isLoading = true; // Add this state variable
  late String barcode; // Declare the barcode variable
  var _productDetails = '';
  final BarcodeDataServices _barcodeDataServices = BarcodeDataServices(); // Create an instance

  @override
  void initState() {
    super.initState();
    barcode = widget.barcode; // Assign the barcode from the widget
    _queryDetails(barcode); // Call the function to fetch details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isLoading ? null: AppBar(title: const Text('Search Result',   style: TextStyle(
                                                            fontSize: 20, // Slightly larger for elegance
                                                            fontWeight: FontWeight.w600, // Semi-bold for a premium feel
                                                            letterSpacing: 0.5, // Subtle spacing for a refined look
                                                            color: Colors.black87, // Darker but not pure black (for a softer look)
                                                          ),
                                                        ),
        leading : GestureDetector(
          onTap: () {Navigator.pop(context);},
          child: Container(
            margin: const EdgeInsets.all(8), // Spacing around the button
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.05), // Soft background
              borderRadius: BorderRadius.circular(8), // Rounded edges
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.1), // Darker border color
                width: 1, // Border thickness
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
            ),
          ),
        ),
      
      
      ),
      body: _isLoading
        ? const CustomProgressWidget() // Show loading indicator if _isLoading is true
        : Stack(children: [
            // Full-screen InAppWebView displayed as the bottom child
            WebDisplayWidget(jsonData: _productDetails),
            // Left 30% GestureDetector overlay, placed on top of WebDisplayWidget
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.15, // 15% of the screen width
                height: double.infinity,
                child: RawGestureDetector(
                  gestures: {
                    HorizontalDragGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
                      () => HorizontalDragGestureRecognizer(),
                      (HorizontalDragGestureRecognizer instance) {
                        instance.onEnd = (details) async {
                          if (details.primaryVelocity! > 400) {
                            if (context.mounted) {
                              await RateAppService.showRatePopupIfNeeded(context);
                            }
                            // after await, the widget might have been unmounted, it's no longer part of the widget tree
                            // so context could be invalid or throw errors
                            if (context.mounted && Navigator.canPop(context)) {
                              Navigator.pop(context); // Perform the action for a left swipe
                            }
                          }
                        };
                      },
                    ),
                  },
                  child: Container(color: Colors.transparent), // Transparent to allow gestures
                ),
              ),
            ),
        ]),
    );
  }

  Future<void> _queryDetails(String barcode) async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Fetch barcode data
    try {
      _productDetails = await _barcodeDataServices.fetchBarcodeData(barcode);
      debugPrint('Product Details: $_productDetails');
    } catch (e) {
      debugPrint('Error: $e');
    }

    setState(() {
      _isLoading = false; // Hide loading indicator and show result
    });

    // Implement your process here
  }
}
