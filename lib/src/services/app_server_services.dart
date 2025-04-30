import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AppServerService {
  // Set up the class as a singleton
  static final AppServerService _instance = AppServerService._internal(); // ✅ Singleton instance
  
  Map<String, dynamic> instructions = {}; // ✅ Stores server instructions
  String baseUrl = "http://madeinca.metasolutions.space/api"; // ✅ App launch server URL
  String token = "J29kZXg6cmVzdF9hcGlfdGVzdAo="; // ✅ App server authorization token
  bool online = false;

  factory AppServerService() {
    return _instance;
  }

  AppServerService._internal(); // ✅ Private constructor
  // Complete singleton preparation


  /// ✅ Initialization function to check server status
  Future<void> initialize() async {

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("app_server")) {
      baseUrl = prefs.getString("app_server")!;
    }

    if (prefs.containsKey("app_token")) {
      token = prefs.getString("app_token")!;
    }

    await checkServerStatus();
  }

  /// ✅ Function to check if the server is online
  Future<void> checkServerStatus() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/server-status.php"),
      );

      if (response.statusCode == 200) {
        online = true;
        instructions = json.decode(response.body); // ✅ Read JSON response
      } else {
        online = false;
      }
    } catch (e) {
      online = false;
    }
  }

  /// **GET request**
  Future<Map<String, dynamic>?> getRequest(String endpoint) async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json", // Optional but recommended
        },
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint("GET request failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("GET request error: $e");
      return null;
    }
  }

  /// **POST request**
  Future<Map<String, dynamic>?> postRequest(String endpoint, Map<String, dynamic> data) async {
    try {
      // String u = "$baseUrl$endpoint";

      final response = await http.post(
        Uri.parse("$baseUrl$endpoint"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json"},
        body: json.encode(data),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("Response: ${response.body}");
        return json.decode(response.body);
      } else {
        print("POST request failed: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("POST request error: $e");
      return null;
    }
  }
}