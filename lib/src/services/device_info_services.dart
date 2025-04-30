import 'dart:io';
import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'app_server_services.dart';

class DeviceInfoService {

  // the code below will make the class a singleton
  static final DeviceInfoService _instance = DeviceInfoService._internal(); // ✅ Singleton instance

  factory DeviceInfoService() {
    return _instance; // ✅ Always return the same instance
  }

  DeviceInfoService._internal(); // ✅ Private constructor prevents new instances
  // Complete singleton preparation

  String deviceId = '';

  Future<bool> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    deviceId = prefs.getString("device_id") ?? '';

    if (deviceId.isEmpty) {
      // Step 1: Create a new device_id in the SharedPreferences
      Map<String, dynamic> deviceInfo = await _getDeviceInfo();
      if (deviceInfo["id"] == null) { return true; }

      deviceId = deviceInfo["id"];
      if (!AppServerService().online) {
        return true;
      }

      // Step 2: Save the device info to the web server
      Map<String, dynamic> selectedInfo = {
        "platform": deviceInfo["platform"],
        "model": deviceInfo["model"],
        "device": deviceInfo["device"],
        "systemVersion": deviceInfo["systemVersion"],
        "id": deviceInfo["id"]
      };
      // ✅ Convert to JSON string
      String jsonInfo = jsonEncode(selectedInfo);

      bool success = await _registerDevice(jsonInfo, deviceId);
      debugPrint("Device Registration: $success");

      await prefs.setString("device_id", deviceId);
      return true;
    }
    return false;
  }

  Future<bool> _registerDevice(String jsonInfo, String deviceId) async {

 
    // ✅ Send the POST request
    var response = await AppServerService().postRequest("/user.php", {
      "id": deviceId,
      "data": jsonInfo // JSON string
    });

    if (response != null) {
      print("Server Response: $response");
      return response["success"];
    }
    return false;
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    
    Map<String, dynamic> info = {
      "appName": packageInfo.appName,
      "packageName": packageInfo.packageName,
      "version": packageInfo.version,
      "buildNumber": packageInfo.buildNumber,
      "networkType": connectivityResult.toString(),
    };

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      info.addAll({
        "platform": "Android",
        "model": androidInfo.model,
        "manufacturer": androidInfo.manufacturer,
        "brand": androidInfo.brand,
        "hardware": androidInfo.hardware,
        "device": androidInfo.device,
        "product": androidInfo.product,
        "host": androidInfo.host,
        "fingerprint": androidInfo.fingerprint,
        "systemVersion": androidInfo.version.release,
        "sdkVersion": androidInfo.version.sdkInt.toString(),
        "id": androidInfo.id,
        "isPhysicalDevice": androidInfo.isPhysicalDevice,
      });
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
      info.addAll({
        "platform": "iOS",
        "model": iosInfo.model,
        "device": iosInfo.name,
        "systemName": iosInfo.systemName,
        "systemVersion": iosInfo.systemVersion,
        "id": iosInfo.identifierForVendor,
        "isPhysicalDevice": iosInfo.isPhysicalDevice,
      });
    }

    return info;
  }
}
