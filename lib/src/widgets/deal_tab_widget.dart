import 'package:flutter/material.dart';
import '../services/rate_app_services.dart'; // Import the RateAppService
import 'deal_display_widget.dart'; // Import the WebDisplayWidget
import 'package:flutter_inappwebview/flutter_inappwebview.dart'; // Import InAppWebViewController
// import 'appbar_actions_widget.dart'; // Import the AppBarActionsWidget

class DealTabWidget extends StatefulWidget {
  final String postalCode;

  const DealTabWidget({
    super.key,
    required this.postalCode,
  });

  @override
  State<DealTabWidget> createState() => _DealTabWidgetState();
}

class _DealTabWidgetState extends State<DealTabWidget> {
  // Expose the inAppWebViewController in this widget state
  InAppWebViewController? _webviewController;

  // Callback that gets called when the WebView is created
  void handleWebViewCreated(InAppWebViewController controller) {
    _webviewController = controller;
  
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Local Deals", style: TextStyle(
                                                          fontSize: 20, // Slightly larger for elegance
                                                          fontWeight: FontWeight.w600, // Semi-bold for a premium feel
                                                          letterSpacing: 0.5, // Subtle spacing for a refined look
                                                          color: Colors.black87, // Darker but not pure black (for a softer look)
                                                        ),
                                                      ),
                      // actions: [  AppBarActionsWidget(currentPage: 'offers'),            ],
                      backgroundColor: Colors.white, // White background for a clean look      
      ),

      body: Stack(children: [
          DealDisplayWidget(postalCode: widget.postalCode, onWebViewCreated: handleWebViewCreated),
          // Swipe-to-go-back gesture
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.15,
              height: double.infinity,
              child: GestureDetector(
                onHorizontalDragEnd: (details) async{
                  if (details.primaryVelocity! > 400) {
                    // If no back history, show rate popup if needed
                    if (context.mounted) {
                      await RateAppService.showRatePopupIfNeeded(context);
                    }
                    // If the webview can go back, do that
                    if (_webviewController != null) {
                      final canGoBack = await _webviewController!.canGoBack();
                      if (canGoBack) {
                        await _webviewController!.goBack();
                        return; // ✅ do not call widget.onBack()
                      }
                    }

                    // after await, the widget might have been unmounted, it's no longer part of the widget tree
                    // so context could be invalid or throw errors
                    //if (context.mounted) {
                    //  widget.onBack(); // Just go back to Scanner
                    //}
                  }
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ]),
    );
  }

}