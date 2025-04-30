import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:madeinca_app/src/services/device_info_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'app_server_services.dart';
import 'gs1_service.dart';
import 'openfoodfacts_service.dart';

class BarcodeDataServices extends ChangeNotifier {
  // Add your state variables here
  bool _isInitialized = false;
  String _serviceUrl = 'https://api.upcitemdb.com/prod/trial/lookup?upc=';
  Map<String, dynamic>? _barcodeData;

  // Getter for the state variable
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get barcodeData => _barcodeData;

  // Initialization method
  Future<void> initialize() async {
    // Perform initialization tasks here
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("barcode_service")) {
      _serviceUrl = prefs.getString("barcode_service")!;
    }


    _isInitialized = true;
    notifyListeners();
  }

  // Cleanup method
  @override
  void dispose() {
    // Perform cleanup tasks here
    _isInitialized = false;
    super.dispose();
  }

  Future<String> fetchBarcodeData(String barcode) async {
    String jsonUnknown = '{"ean": "$barcode", "title": "Private Product Code","description": "The product code does not directly linked to any public product information. The product origin information displayed on this page is our best estimate from the product code. Some private product code does not follow industry conventions. Our estimate could be wrong due to non-standard code format. Pleasse look up for maple leaf sign, the Product of Canada or Made in Canada signs on the package to confirm its origin.","offers": [{"merchant": "none","title": "You can look up the company information below","link": "https://www.gs1.org/services/verified-by-gs1/results?gtin=$barcode"}]}';
    String desc = '';
    String type = '';
    if (barcode.length == 12) {
      barcode = '0$barcode'; // Prepend '0' for EAN-13 format
    }


    desc = await queryAppServer(barcode);

    if (desc.isEmpty) {
      desc = await fetchBarcodeService(barcode);
      if (desc.isNotEmpty) type = 'product';
    }

    if (desc.isEmpty) {
      desc = await OpenfoodfactsService().fetchBarcodeService(barcode);
    }
    
    // Save the barcode data to the app server
    if (desc.isEmpty && GS1Service().online) {
      desc = await GS1Service().fetchBarcodeService(barcode);
      if (desc.isNotEmpty) type = 'company';
    }

    // At this point, we do not have any data of the product
    if (desc.isEmpty) {
      desc = jsonUnknown;
    } 
    
    try {
      Map<String, dynamic> jsonData = json.decode(desc);
      // No need to save openfoodfacts data to app server for now, because it is public data
      if (type.isNotEmpty && !(jsonData.containsKey("code") && jsonData["code"].toString().toLowerCase() == "error")) {
        await saveBarcodeData(barcode, type, desc);
      }
      if (!jsonData.containsKey("made") || jsonData["made"].toString().isEmpty) {
        jsonData["made"] = getCountry(barcode);
        desc = jsonEncode(jsonData);
      }
    } catch(e) {
      return jsonUnknown;
    }

    return desc;
  }

  Future<void> saveBarcodeData(String barcode, String type, String desc) async {
    if (!AppServerService().online) {
      return;
    }

    var endpoint = "/item.php";
    var params = {
      "id": DeviceInfoService().deviceId,
      "upc": barcode,
      "type": type,
      "desc": desc
    };
    // ✅ Send the POST request
    var response = await AppServerService().postRequest(endpoint, params);
    debugPrint("Response: $response");
  }

  // Method to query the barcode from app server
  Future<String> queryAppServer(String barcode) async {
    if (!AppServerService().online) {
      return '';
    }
    
    var endpoint = "/item.php";
    var params = {
      "id": DeviceInfoService().deviceId,
      "upc": barcode
    };

    try {
      endpoint = "$endpoint?${Uri(queryParameters: params).query}";
      // ✅ Send the POST request
      var jsonResp = await AppServerService().getRequest(endpoint);

      // Decode JSON string to a Map
      if (jsonResp != null && jsonResp.isNotEmpty) {
        //Map<String, dynamic> jsonResp = json.decode(response);
        // Extracting each field
        // String upc = jsonResp["upc"];
        if (jsonResp.containsKey("description")) {
          String desc = jsonResp["description"];
          String origin = '';

          if (desc.isNotEmpty) {
            Map<String, dynamic> jsonData = json.decode(desc);
            if (jsonResp.containsKey("origin")) {
              if (jsonResp["origin"] != null && jsonResp["origin"].isNotEmpty) {
                origin = jsonResp["origin"];
              }
            }

            if (origin.isEmpty && !jsonData.containsKey("made")) {
              // Decode JSON string to a Map
              origin = getCountry(barcode);
              jsonData["made"] = origin;
            }

            desc = jsonEncode(jsonData);

            return desc;
          } 
        }
      }

    } catch (e) {
      if (e is FormatException) {
        debugPrint("Invalid JSON format: ${e.message}");
      } else {
        debugPrint("Unknown error: $e");
      }
    }



    return '';
  }

  // Method to call UPCitemDB API
  Future<String> fetchBarcodeService(String barcode) async {
    final url = '$_serviceUrl$barcode';
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    String jsonBusy = '{"code": "ERROR","title": "Connection Busy","description": "Public product database is busy. Please try again later."}';

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      
      if (response.statusCode == 200) {
        _barcodeData = json.decode(response.body);
        notifyListeners();
      } else {
        return '';
      }

      String jstr = processResponse(response.body);
      return jstr;
    } catch (e) {
      debugPrint('Error fetching barcode data: $e');
    }

    return '';
  }

  String processResponse(jsonString) {
    String jsonError = '{"code": "ERROR","title": "Not Found","description": "Product details not available"}';

    try {
        // Validate JSON
        var jsonResp = jsonDecode(jsonString);

          // Access 'items' list
        List<dynamic> items = jsonResp['items'];
        if (items.isEmpty) {
          return '';
        }

        // Get first item (items[0])
        Map<String, dynamic> item0 = items[0];
        // Identify country made
        String ean = item0['ean'];
        if (ean.isEmpty) {
          ean = item0['upc'];
          if (ean.length == 12) {
            ean = '0$ean'; // Prepend '0' for EAN-13 format
          }
        }

        item0["made"] = getCountry(ean);
        if (item0["title"].substring(item0["title"].length - 6).toLowerCase() == "canada") {    // || item0["title"].toLowerCase().endsWith("{imported from canada}")
          item0["made"] = "Canada"; // If no match is found
        }

        // Remove an existing property
        // delete obj.oldProperty; 

        // Convert back to string
        return jsonEncode(item0); // Pretty-print with indentation
    } catch (error) {

        // Return a JSON string indicating invalid data
        return jsonError;
    }
  }

  String getCountry(String ean) {
    var origin = "idk"; // If no match is found
    int prefix = int.parse(ean.substring(0, 3));
    for (var range in gs1CountryRanges) {
      if (prefix >= range["start"] && prefix <= range["end"]) {
        origin = range["country"];
        break;
      }
    }

    return origin;
  }

  List<Map<String, dynamic>> gs1CountryRanges = [
    {"start": 60, "end": 69, "country": "Canada"},
    {"start": 0, "end": 19, "country": "idk"},
    {"start": 0, "end": 139, "country": "United States"},
    {"start": 300, "end": 379, "country": "France"},
    {"start": 380, "end": 380, "country": "Bulgaria"},
    {"start": 383, "end": 383, "country": "Slovenia"},
    {"start": 385, "end": 385, "country": "Croatia"},
    {"start": 387, "end": 387, "country": "Bosnia"},
    {"start": 389, "end": 389, "country": "Montenegro"},
    {"start": 400, "end": 440, "country": "Germany"},
    {"start": 450, "end": 459, "country": "Japan"},
    {"start": 460, "end": 469, "country": "Russia"},
    {"start": 470, "end": 470, "country": "Kyrgyzstan"},
    {"start": 471, "end": 471, "country": "Taiwan"},
    {"start": 474, "end": 474, "country": "Estonia"},
    {"start": 475, "end": 475, "country": "Latvia"},
    {"start": 476, "end": 476, "country": "Azerbaijan"},
    {"start": 477, "end": 477, "country": "Lithuania"},
    {"start": 478, "end": 478, "country": "Uzbekistan"},
    {"start": 479, "end": 479, "country": "Sri Lanka"},
    {"start": 480, "end": 480, "country": "Philippines"},
    {"start": 481, "end": 481, "country": "Belarus"},
    {"start": 482, "end": 482, "country": "Ukraine"},
    {"start": 483, "end": 483, "country": "Turkmenistan"},
    {"start": 484, "end": 484, "country": "Moldova"},
    {"start": 485, "end": 485, "country": "Armenia"},
    {"start": 486, "end": 486, "country": "Georgia"},
    {"start": 487, "end": 487, "country": "Kazakhstan"},
    {"start": 488, "end": 488, "country": "Tajikistan"},
    {"start": 489, "end": 489, "country": "Hong Kong"},
    {"start": 490, "end": 499, "country": "Japan"},
    {"start": 500, "end": 509, "country": "United Kingdom"},
    {"start": 520, "end": 521, "country": "Greece"},
    {"start": 528, "end": 528, "country": "Lebanon"},
    {"start": 529, "end": 529, "country": "Cyprus"},
    {"start": 530, "end": 530, "country": "Albania"},
    {"start": 531, "end": 531, "country": "North Macedonia"},
    {"start": 535, "end": 535, "country": "Malta"},
    {"start": 539, "end": 539, "country": "Ireland"},
    {"start": 540, "end": 549, "country": "Belgium"},
    {"start": 560, "end": 560, "country": "Portugal"},
    {"start": 569, "end": 569, "country": "Iceland"},
    {"start": 570, "end": 579, "country": "Denmark"},
    {"start": 590, "end": 590, "country": "Poland"},
    {"start": 594, "end": 594, "country": "Romania"},
    {"start": 599, "end": 599, "country": "Hungary"},
    {"start": 600, "end": 601, "country": "South Africa"},
    {"start": 603, "end": 603, "country": "Ghana"},
    {"start": 604, "end": 604, "country": "Senegal"},
    {"start": 605, "end": 605, "country": "Uganda"},
    {"start": 606, "end": 606, "country": "Angola"},
    {"start": 607, "end": 607, "country": "Oman"},
    {"start": 608, "end": 608, "country": "Bahrain"},
    {"start": 609, "end": 609, "country": "Mauritius"},
    {"start": 611, "end": 611, "country": "Morocco"},
    {"start": 613, "end": 613, "country": "Algeria"},
    {"start": 615, "end": 615, "country": "Nigeria"},
    {"start": 616, "end": 616, "country": "Kenya"},
    {"start": 617, "end": 617, "country": "Cameroon"},
    {"start": 618, "end": 618, "country": "Ivory Coast"},
    {"start": 619, "end": 619, "country": "Tunisia"},
    {"start": 620, "end": 620, "country": "Tanzania"},
    {"start": 621, "end": 621, "country": "Syria"},
    {"start": 622, "end": 622, "country": "Egypt"},
    {"start": 623, "end": 623, "country": "Brunei"},
    {"start": 624, "end": 624, "country": "Libya"},
    {"start": 625, "end": 625, "country": "Jordan"},
    {"start": 626, "end": 626, "country": "Iran"},
    {"start": 627, "end": 627, "country": "Kuwait"},
    {"start": 628, "end": 628, "country": "Saudi Arabia"},
    {"start": 629, "end": 629, "country": "UAE"},
    {"start": 630, "end": 630, "country": "Qatar"},
    {"start": 631, "end": 631, "country": "Namibia"},
    {"start": 632, "end": 632, "country": "Rwanda"},
    {"start": 640, "end": 649, "country": "Finland"},
    {"start": 680, "end": 681, "country": "China"},
    {"start": 690, "end": 699, "country": "China"},
    {"start": 700, "end": 709, "country": "Norway"},
    {"start": 729, "end": 729, "country": "Israel"},
    {"start": 730, "end": 739, "country": "Sweden"},
    {"start": 740, "end": 740, "country": "Guatemala"},
    {"start": 741, "end": 741, "country": "El Salvador"},
    {"start": 742, "end": 742, "country": "Honduras"},
    {"start": 743, "end": 743, "country": "Nicaragua"},
    {"start": 744, "end": 744, "country": "Costa Rica"},
    {"start": 745, "end": 745, "country": "Panama"},
    {"start": 746, "end": 746, "country": "Dominican Republic"},
    {"start": 750, "end": 750, "country": "Mexico"},
    {"start": 754, "end": 755, "country": "Canada"},
    {"start": 759, "end": 759, "country": "Venezuela"},
    {"start": 760, "end": 769, "country": "Switzerland"},
    {"start": 770, "end": 771, "country": "Colombia"},
    {"start": 773, "end": 773, "country": "Uruguay"},
    {"start": 775, "end": 775, "country": "Peru"},
    {"start": 777, "end": 777, "country": "Bolivia"},
    {"start": 778, "end": 779, "country": "Argentina"},
    {"start": 780, "end": 780, "country": "Chile"},
    {"start": 784, "end": 784, "country": "Paraguay"},
    {"start": 785, "end": 785, "country": "Peru"},
    {"start": 786, "end": 786, "country": "Ecuador"},
    {"start": 789, "end": 790, "country": "Brazil"},
    {"start": 800, "end": 839, "country": "Italy"},
    {"start": 840, "end": 849, "country": "Spain"},
    {"start": 850, "end": 850, "country": "Cuba"},
    {"start": 858, "end": 858, "country": "Slovakia"},
    {"start": 859, "end": 859, "country": "Czech"},
    {"start": 860, "end": 860, "country": "Serbia"},
    {"start": 865, "end": 865, "country": "Mongolia"},
    {"start": 867, "end": 867, "country": "North Korea"},
    {"start": 868, "end": 869, "country": "Turkey"},
    {"start": 870, "end": 879, "country": "Netherlands"},
    {"start": 880, "end": 881, "country": "South Korea"},
    {"start": 883, "end": 883, "country": "Myanmar"},
    {"start": 884, "end": 884, "country": "Cambodia"},
    {"start": 885, "end": 885, "country": "Thailand"},
    {"start": 888, "end": 888, "country": "Singapore"},
    {"start": 890, "end": 890, "country": "India"},
    {"start": 893, "end": 893, "country": "Vietnam"},
    {"start": 896, "end": 896, "country": "Pakistan"},
    {"start": 899, "end": 899, "country": "Indonesia"},
    {"start": 900, "end": 919, "country": "Austria"},
    {"start": 930, "end": 939, "country": "Australia"},
    {"start": 940, "end": 949, "country": "New Zealand"},
    {"start": 955, "end": 955, "country": "Malaysia"},
    {"start": 958, "end": 958, "country": "Macau"},
    {"start": 960, "end": 961, "country": "Greece"},
    {"start": 962, "end": 962, "country": "Lebanon"},
    {"start": 963, "end": 963, "country": "Cyprus"},
    {"start": 964, "end": 964, "country": "Barbados"},
    {"start": 965, "end": 965, "country": "Mauritius"},
    {"start": 966, "end": 966, "country": "Pakistan"},
    {"start": 967, "end": 967, "country": "Bangladesh"},
    {"start": 968, "end": 968, "country": "Nigeria"},
    {"start": 969, "end": 969, "country": "Sri Lanka"},
  ];


  // Example method to update state
  void updateState(bool newState) {
    _isInitialized = newState;
    notifyListeners();
  }
}
