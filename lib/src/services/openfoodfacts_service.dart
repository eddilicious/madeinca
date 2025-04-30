import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'app_server_services.dart';

class OpenfoodfactsService {
  // Set up the class as a singleton
  static final OpenfoodfactsService _instance = OpenfoodfactsService._internal(); // ✅ Singleton instance
  
  String cookiesString = ''; // Initialize with an empty string
  
  // product_query_configurations.dart line 18 
  Map<String, String> domains = {
    "food": "world.openfoodfacts.org",
    "beauty": "world.openbeautyfacts.org",
    "pet": "world.openpetfoodfacts.org",
    "petfood": "world.openpetfoodfacts.org",
    "products": "world.openproductsfacts.org"
  };

  String path = '/api/v2/product/';     // barcode
  bool online = false;
  bool verified = false;

  factory OpenfoodfactsService() {
    return _instance;
  }

  OpenfoodfactsService._internal(); // ✅ Private constructor
  // Complete singleton preparation


  /// ✅ Initialization function to check server status
  Future<void> initialize() async {

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("openfoodfacts_cookies")) {
      cookiesString = prefs.getString("openfoodfacts_cookies")!;
    }
    initializeCookies(cookiesString);

  }

  // uri_helper.dart line 25
  Uri getUri(String barcode) =>
      Uri(
        scheme: 'https',
        host: 'world.openfoodfacts.org',
        path: path + barcode,
        queryParameters: {'lc': 'en', 'tags_lc': 'en'}, // tempoarary
        userInfo: null,
      );

  String getUrlString(String category, String barcode) {
    // https://world.openfoodfacts.org/api/v2/product/0059600038135.json
    // v3 link below not used
    // 'https://world.openfoodfacts.org/api/v3/product/$barcode/?lc=en&tags_lc=en&app_name=MapleFind';

    String link = 'https://${domains[category]}$path$barcode.json';
    return link;
  }

  Future<String> fetchBarcodeService(String barcode) async {
    Uri url = Uri.parse(getUrlString('food', barcode));

    try {
      http.Response response = await http.get(url, headers: headers);
      String body = response.body;
      
      if (response.statusCode != 200) {
        Map<String, dynamic> state = jsonDecode(body);
        
        RegExp regExp = RegExp(r'product type:\s*(\w+)');
        Match? match = regExp.firstMatch(state['status_verbose']);
        
        if (match == null) return '';
        String sisterSite = match.group(1)!;
        if (!domains.containsKey(sisterSite)) return '';

        url = Uri.parse(getUrlString(sisterSite, barcode));
        response = await http.get(url, headers: headers);
        if (response.statusCode == 200) { 
          body = response.body;
        } 
      } 

      if (body.isNotEmpty) {
        String jstr = processResponse(body);
        return jstr;
      }
    } catch (e) {
      debugPrint('Error fetching barcode data: $e');
    }

    return '';
  }

  // http_helper.dart line 275
  // openfoodfacts does not require cookies
  Map<String, String> headers = {
    'Accept': 'application/json', 
    'User-Agent': ' - MapleFind', 
    'From': 'anonymous'
  };


  Map<String, String> cookies = {};

  Future<void> initializeCookies(String strCookies) async {
    try {
      // Parse cookies
      List<String> cookieList = strCookies.split(';');
      for (var cookie in cookieList) {
        cookie = cookie.trim();
            // Find the first '=' to separate name and value
        int idx = cookie.indexOf('=');
        if (idx != -1) {
        // Extract name and value based on the first '=' occurrence
          String name = cookie.substring(0, idx);
          String value = cookie.substring(idx + 1);
          cookies[name] = value;
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  String getCookiesString() {
    return cookies.entries.map((entry) => '${entry.key}=${entry.value}').join('; ');
  }

  String uniDecode(String input) {
    return input.replaceAllMapped(RegExp(r'\\u([0-9A-Fa-f]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    });
  }

  String processResponse(jsonString) {
    String jsonError = '{"code": "ERROR","title": "Not Found","description": "Product details not available"}';
    String jsonUnknown = '{"title": "Unknown Product","description": "Private product code. The product information is not available for public."}';

    try {
        // Validate JSON
        var jsonResp = jsonDecode(jsonString);
        if (jsonResp == null || jsonResp.isEmpty) return '';
        if (!jsonResp.containsKey('product')) return '';

          // Access 'items' list
        Map<String, dynamic> product = jsonResp['product'];
        if (product.isEmpty) {
          return jsonUnknown;
        }

        Map<String, dynamic> data = {};
        data['ean'] = jsonResp['code'];
        data['title'] = "${product['product_name'] ?? 'Unknown Product'} ${(product.containsKey('quantity') && product['quantity'] != '1') ? ' ${product['quantity']}' : ''}";
        data['brand'] = product['brands'] ?? 'Unknown Brand';
        if (product.containsKey('nutriments') && (product['nutriments'] as Map).isNotEmpty) {
          data['description'] = '<h4>Nutritions</h4>' + generateNutritionTable(product['nutriments']);
        } else if (product['nutriments'] is String) {
          data['description'] = product['nutriments'];
        } else {
          data['description'] = '';
        }

        if (product.containsKey('ingredients') && product['ingredients'].isNotEmpty) {
          data['description'] += '${data['description'].isNotEmpty? "<br>":""}<h4>Ingredients</h4>';
          if (product['ingredients_text'] != null && product['ingredients_text'].isNotEmpty) {
            data['description'] += '<span>${product['ingredients_text']}</span><br>';
          }
          data['description'] += generateIngredientList(product['ingredients']);
        } 

        if (product.containsKey('ingredients_analysis_tags') && product['ingredients_analysis_tags'].isNotEmpty) {
          data['description'] += '${data['description'].isNotEmpty? "<br>":""}<h4>Ingredients Analysis</h4>';
          data['description'] += generateAnalysisTagsList(product['ingredients_analysis_tags']);
        } 

        if (product.containsKey('label') && product['label'].isNotEmpty) {
          data['description'] = '<h4>${product['label']}</h4>${data['description']}';
        }

        data['images'] = [];
        data['images'].add(product['image_url'] ?? product['image_small_url'] ?? product['image_thumb_url'] ?? product['image_nutrition_url'] ?? product['image_front_url'] ?? product['image_back_url'] ?? product['image_ingredients_url'] ?? product['image_packaging_url'] ?? product['image_ingredients_small_url'] ?? product['image_packaging_small_url'] ?? product['image_front_small_url'] ?? product['image_back_small_url']);

        if (product.containsKey('countries')) {
          data["made"] = findCountry(product['countries'].toString());
        }

        return jsonEncode(data); // Pretty-print with indentation
    } catch (error) {

        // Return a JSON string indicating invalid data
        return '';
    }
  }

  String generateAnalysisTagsList(List<dynamic> ingredientsAnalysisTags) {
    StringBuffer html = StringBuffer('<ul>');

    for (var tag in ingredientsAnalysisTags) {
      // Check if the tag starts with "en:" and remove it
      if (tag.startsWith('en:')) {
        tag = tag.substring(3);  // Remove the "en:" prefix
      } else if (tag.contains(':')) {
        // If it contains a language code other than "en", skip beautification
        continue;
      }

      String tagName = beautifyKey(tag);
      html.write('<li>$tagName</li>');
    }

    html.write('</ul>');
    return html.toString();
  }

  String generateIngredientList(List<dynamic> jsonData) {
    StringBuffer html = StringBuffer('<ul>');

    for (var ingredient in jsonData) {
      String ingredientName = beautifyKey(ingredient['text']);
      double percent = (ingredient['percent_estimate'] ?? ingredient['percent'] ?? 0).toDouble();
      
      // Add the main ingredient
      html.write('<li>$ingredientName: ${percent.toStringAsFixed(1)}%</li>');
      
      // If the ingredient has sub-ingredients
      if (ingredient['ingredients'] != null) {
        html.write('<ul>');
        for (var subIngredient in ingredient['ingredients']) {
          String subIngredientName = beautifyKey(subIngredient['text']);
          double subPercent = (subIngredient['percent_estimate'] ?? subIngredient['percent'] ?? 0).toDouble();
          html.write('<li>— $subIngredientName: ${subPercent.toStringAsFixed(1)}% (estimate)</li>');
        }
        html.write('</ul>');
      }
    }

    html.write('</ul>');
    return html.toString();
  }

  String generateNutritionTable(Map<String, dynamic> nutriments) {
    StringBuffer html = StringBuffer();
    html.writeln('<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif;">');
    html.writeln('<thead><tr style="background-color: #f4f4f4;">');
    html.writeln('<th style="padding: 10px; text-align: left;">Nutrition Facts</th>');
    html.writeln('<th style="padding: 10px; text-align: center;">Per 100 g</th>');
    html.writeln('<th style="padding: 10px; text-align: center;">Per Serving</th>');
    html.writeln('</tr></thead><tbody>');

    // Extract unique keys
    Set<String> uniqueKeys = {};
    nutriments.keys.forEach((key) {
      if (!key.contains('_100g') && !key.contains('_serving') && !key.contains('_unit') && !key.contains('_value')) {
        uniqueKeys.add(key);
      }
    });

    for (String key in uniqueKeys) {
      String unit = nutriments['${key}_unit'] ?? '';
      dynamic value100g = nutriments['${key}_100g'] ?? '?';
      dynamic valueServing = nutriments['${key}_serving'] ?? '?';
      
      // Format values
      if (value100g is num) {
        value100g = formatValue(value100g, unit);
      }
      if (valueServing is num) {
        valueServing = formatValue(valueServing, unit);
      }

      // Beautify key names
      String displayKey = beautifyKey(key);

      html.writeln('<tr>');
      html.writeln('<td style="padding: 10px;">$displayKey</td>');
      html.writeln('<td style="padding: 10px; text-align: center;">$value100g</td>');
      html.writeln('<td style="padding: 10px; text-align: center;">$valueServing</td>');
      html.writeln('</tr>');
    }

    html.writeln('</tbody></table>');
    return html.toString();
  }

  String formatValue(num value, String unit) {
    if (unit == 'g' && value < 1) {
      return '${(value * 1000).toStringAsFixed(1)} mg';
    } else if (unit == 'g') {
      return '${value.toStringAsFixed(1)} g';
    } else if (unit == 'kcal') {
      return '${value.toStringAsFixed(0)} kcal';
    } else {
      return '$value $unit';
    }
  }

  String beautifyKey(String key) {
    return key.split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String findCountry(String input) {
    if (input == null || input.isEmpty) {
      return '';
    }

    // Step 1: Remove the first 3 characters if the string starts with "**:"
    List<String> items = input.split(',').map((e) {
      e = e.trim();
      // If it starts with a language prefix like "en:", remove the first 3 characters
      if (e.length > 3 && e[2] == ':') {
        e = e.substring(3).trim();
      }
      return e;
    }).toList();

    // Step 2: Check for Canada, then United States, else return first item
    for (String item in items) {
      if (["ca", "canada"].contains(item)) return "Canada";
    }
    for (String item in items) {
      if (["us", "usa", "united states"].contains(item)) return "United States";
    }
    
    return items.isNotEmpty ? items.first : '';
  }

}