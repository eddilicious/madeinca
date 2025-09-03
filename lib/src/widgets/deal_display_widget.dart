import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:io'; // Add platform switch

class DealDisplayWidget extends StatefulWidget {
  final String postalCode;
  final void Function(InAppWebViewController)? onWebViewCreated;
  const DealDisplayWidget({super.key, required this.postalCode, this.onWebViewCreated});

  @override
  State<DealDisplayWidget> createState() => _DealDisplayWidgetState();
}

class _DealDisplayWidgetState extends State<DealDisplayWidget> {
  bool linkClicked = false; // Track if a link has been clicked
  late final InAppWebViewController _controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: InAppWebView(
          initialFile: 'assets/html/deals_display.html', // Ensure the correct file path
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true, // 👈 important  
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url;
            debugPrint("####################################   Opening: $uri");
            if (uri?.path.contains('deals_display.html') == false) {
              setState(() {
                linkClicked = true;
              });
            }

            return NavigationActionPolicy.ALLOW; // Let the WebView open links
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT);
          },          
          onWebViewCreated: (controller) {
            // Send controller to parent if provided
            _controller = controller;
            if (widget.onWebViewCreated != null) {
              widget.onWebViewCreated!(controller); // Notify parent
            }

            controller.addJavaScriptHandler(
              handlerName: 'loadDeals',
              callback: (args) {
                return widget.postalCode;
              },
            );
          },
          onLoadStop: (controller,url) async {
              // Show a Flutter AlertDialog
            if (linkClicked) return;
            
             if (Platform.isAndroid) {
              controller.evaluateJavascript(source: """
                window.postMessage('${widget.postalCode}', '*');
              """);
            } else {
              controller.evaluateJavascript(source: """
                loadDeals('${widget.postalCode}');
              """);
            }
          },
        ),
      ),
    );
  }
}
