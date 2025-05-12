import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'dart:convert'; // Import jsonEncode
import 'dart:io'; // Add platform switch

class WebDisplayWidget extends StatefulWidget {
  final String jsonData;

  const WebDisplayWidget({super.key, required this.jsonData});

  @override
  State<WebDisplayWidget> createState() => _WebDisplayWidgetState();
}

class _WebDisplayWidgetState extends State<WebDisplayWidget> {
  bool linkClicked = false; // Track if a link has been clicked

//final String jsonData = '{  "code": "OK",  "total": 1,  "offset": 0,  "items": [{  "ean": "0064642051967",  "title": "Jamieson Vitamin C + D Chewable  75 tabs  for ASIN  B00CP7Q59Q",  "description": "Jamieson Vitamins C & D - Chewable Morello Cherry is the first Vitamin C formula to be enriched with Vitamin D3  the same disease-fighting form produced when your skin is exposed to sunlight. Combined  they protect you - even during the winter months when sunshine is limited. This innovative product is a great choice for anyone who regularly takes Vitamin C  but wants additional protection from Vitamin D.",  "upc": "064642051967",  "brand": "Jamieson",  "model": "5196",  "color": "",  "size": "",  "dimension": "",  "weight": "",  "category": "Sporting Goods > Outdoor Recreation > Equestrian > Horse Care",  "currency": "",  "lowest_recorded_price": 5.77,  "highest_recorded_price": 81.88,  "images": [  "https://i5.walmartimages.com/asr/c5d38cc3-40fd-4a10-8ab6-185c1b82205a.42c3740d6d743f562e425b1fe53208bc.jpeg?odnHeight=450&odnWidth=450&odnBg=ffffff",  "https://i5.walmartimages.ca/images/Large/921/794/6000196921794.jpg"  ],  "offers": [{  "merchant": "Wal-Mart.com",  "domain": "walmart.com",  "title": "Jamieson Vitamin C + D Chewable  75 tabs  for ASIN  B00CP7Q59Q",  "currency": "",  "list_price": "",  "price": 21.32,  "shipping": "Free Shipping",  "condition": "New",  "availability": "Out of Stock",  "link": "https://www.upcitemdb.com/norob/alink/?id=13q213v2z213c474q2&tid=1&seq=1739312069&plt=99950b8f3ed7bf6584bf588f492391cb",  "updated_t": 1683311707  }, {  "merchant": "WalMart Canada",  "domain": "walmart.ca",  "title": "Jamieson Laboratories Jamieson Chewable Vitamin C 500 Mg And Vitamin D3 500 Iu Morello Cherry Flavour Tablets",  "currency": "CAD",  "list_price": 6.97,  "price": 5.77,  "shipping": "",  "condition": "New",  "availability": "",  "link": "https://www.upcitemdb.com/norob/alink/?id=v2r213v2036374d4q2&tid=1&seq=1739312069&plt=50a2100415cebfa5455b1bc5972ddcd4",  "updated_t": 1624235456  }],  "elid": 285156567729  }]  }';

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
          initialFile: 'assets/html/product_display.html', // Ensure the correct file path
          initialSettings: InAppWebViewSettings(
            javaScriptEnabled: true,
            useShouldOverrideUrlLoading: true,
            mediaPlaybackRequiresUserGesture: false,
          ),
          shouldOverrideUrlLoading: (controller, navigationAction) async {
            var uri = navigationAction.request.url.toString();
            debugPrint("####################################   Opening: $uri");
            linkClicked = true; // Set to true when a link is clicked

            return NavigationActionPolicy.ALLOW; // Let the WebView open links
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT);
          },          
          onWebViewCreated: (controller) {
            controller.addJavaScriptHandler(
              handlerName: 'sendJsonData',
              callback: (args) {
                return widget.jsonData;
              },
            );
          },
          onLoadStop: (controller,url) async {
            if (linkClicked) return;
            
              // Show a Flutter AlertDialog
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Inspect JSON Data"),
      content: SingleChildScrollView(
        child: Text(widget.jsonData.toString()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("OK"),
        ),
      ],
    ),
  );

            final jsonDataString = jsonEncode(widget.jsonData); // Convert JSON data to string

            if (Platform.isAndroid) {
              controller.evaluateJavascript(source: """
                window.postMessage($jsonDataString, '*');
              """);
            } else {
              controller.evaluateJavascript(source: """
                alert($jsonDataString);
                displayJsonData($jsonDataString);
              """);
            }
          },
        ),
      ),
    );
  }
}
