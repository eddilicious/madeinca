import 'package:flutter/material.dart';
import '../services/barcode_data_services.dart'; // Import the BarcodeDataServices
import '../services/rate_app_services.dart'; // Import the RateAppService
import 'custom_progress_widget.dart'; // Import the CustomProgressIndicator widget
import 'web_display_widget.dart'; // Import the WebDisplayWidget
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import InAppWebViewController
// import 'appbar_actions_widget.dart'; // Import the AppBarActionsWidget


class ResultTabWidget extends StatefulWidget {
  final String barcode;
  final VoidCallback onBack;

  const ResultTabWidget({
    super.key,
    required this.barcode,
    required this.onBack,
  });

  @override
  State<ResultTabWidget> createState() => _ResultTabWidgetState();
}

class _ResultTabWidgetState extends State<ResultTabWidget> {
  bool _isLoading = true;
  var _productDetails = '';
  final BarcodeDataServices _barcodeDataServices = BarcodeDataServices();
  // Expose the inAppWebViewController in this widget state
  InAppWebViewController? _webviewController;

  // Callback that gets called when the WebView is created
  void handleWebViewCreated(InAppWebViewController controller) {
    _webviewController = controller;
  }

  @override
  void initState() {
    super.initState();
    _queryDetails(widget.barcode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLoading ? 'Searching...': 'Search Result',   style: TextStyle(
                                                            fontSize: 20, // Slightly larger for elegance
                                                            fontWeight: FontWeight.w600, // Semi-bold for a premium feel
                                                            letterSpacing: 0.5, // Subtle spacing for a refined look
                                                            color: Theme.of(context).colorScheme.onSurface, // Darker but not pure black (for a softer look)
                                                          ),
                                                        ),
        leading : GestureDetector(
          onTap: () {widget.onBack();},
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
        backgroundColor: Colors.white, // White background for a clean look      
      ),
      body: _isLoading
        ? const Center(child: CustomProgressWidget()) // Show loading indicator if _isLoading is true
        : Stack(children: [
          WebDisplayWidget(jsonData: _productDetails, 
            onWebViewCreated: handleWebViewCreated, // Pass the callback to the WebDisplayWidget
          ),
          // Swipe-to-go-back gesture
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.15,
              height: double.infinity,
              child: GestureDetector(
                onHorizontalDragEnd: (details) async{
                  if (details.primaryVelocity! > 400) {
                    // If the webview can go back, do that
                    if (_webviewController != null) {
                      final canGoBack = await _webviewController!.canGoBack();
                      if (canGoBack) {
                        await _webviewController!.goBack();
                        return; // ✅ do not call widget.onBack()
                      }
                    }

                    // If no back history, show rate popup if needed
                    if (context.mounted) {
                      await RateAppService.showRatePopupIfNeeded(context);
                    }
                    // after await, the widget might have been unmounted, it's no longer part of the widget tree
                    // so context could be invalid or throw errors
                    if (context.mounted) {
                      widget.onBack(); // Just go back to Scanner
                    }
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ]),
    );
  }

  Future<void> _queryDetails(String barcode) async {
    try {
      _productDetails = await _barcodeDataServices.fetchBarcodeData(barcode);
    } catch (e) {
      debugPrint('Error: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

}