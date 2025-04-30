import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:upgrader/upgrader.dart';
//import 'src/home_screen.dart'; // Import the HomeScreen widget
import 'src/scanner_screen.dart'; // Import the BarcodeScannerWithOverlay widget
import 'src/services/app_server_services.dart'; // Import the AppServerService
import 'src/services/device_info_services.dart';
import 'src/services/gs1_service.dart'; // Import the AppServerService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MyApp());
}

Future<void> readInstructions() async {
  final prefs = await SharedPreferences.getInstance();
  final instructions = AppServerService().instructions;

  if (instructions.containsKey("app_server")) {
    await prefs.setString("app_server", instructions["app_server"]);
  }

  if (instructions.containsKey("app_token")) {
    await prefs.setString("app_token", instructions["app_token"]);
  }

  if (instructions.containsKey("barcode_service")) {
    await prefs.setString("barcode_service", instructions["barcode_service"]);
  }

  if (instructions.containsKey("barcode_service_key")) {
    await prefs.setString("barcode_service_key", instructions["barcode_service_key"]);
  }

  if (instructions.containsKey("gs1_cookie")) {
    await prefs.setString("gs1_cookie", instructions["gs1_cookie"]);
  }

  if (instructions.containsKey("openfoodfacts_cookies")) {
    await prefs.setString("openfoodfacts_cookies", instructions["openfoodfacts_cookies"]);
  }

  String serverCaptcha = "";
  String appCaptcha = "";
  // Compare Server side captcha with App side captcha
  // to decide which is more up to date
  if (instructions.containsKey("gs1_captcha")) {
    serverCaptcha = instructions["gs1_captcha"];
  }
  
  if (prefs.containsKey("gs1_captcha")) {
    appCaptcha = prefs.getString("gs1_captcha")!;
  }  

  if (serverCaptcha.isNotEmpty) {
    if (appCaptcha.isEmpty) {
      await prefs.setString("gs1_captcha", instructions["gs1_captcha"]);
    } else {
      Map<String, dynamic> mapServer = jsonDecode(serverCaptcha);
      Map<String, dynamic> mapApp = jsonDecode(appCaptcha);
      String? sid1Str = mapServer['captcha_sid']?.toString();
      String? sid2Str = mapApp['captcha_sid']?.toString();

      int? sid1 = (sid1Str != null) ? int.tryParse(sid1Str) : null;
      int? sid2 = (sid2Str != null) ? int.tryParse(sid2Str) : null;

      if (sid1 != null && sid2 != null && sid1 > sid2) {
        await prefs.setString("gs1_captcha", instructions["gs1_captcha"]);
      }
    }
  }

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App with Splash Screen',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: UpgradeAlert( //checks the latest version from the App Store (iOS) or Play Store (Android).
        child: const SplashScreen(), // Set the SplashScreen as the initial screen
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  InAppWebViewController? _webViewController;
  bool _showingWelcomeScreen = false; // Tracks if welcome screen is active

  @override
  void initState() {
    super.initState();
  }

  Future<void> _initializeAndNavigate() async {
    // Let the splash screen delay for 5 seconds
    final startTime = DateTime.now();
    bool isFirstLaunch = false;

    // Show splash screen first
    _webViewController?.loadFile(assetFilePath: 'assets/html/splash_screen.html');

    /// 1. Initialize the AppServer service
    await AppServerService().initialize();
    /// 2. Initialize the DeviceInfo service after AppServerService
    isFirstLaunch = await DeviceInfoService().initialize();
    /// 3. Read the server instructions
    await readInstructions(); 
    /// 4. Initialize GS1 services
    await GS1Service().initialize();

    final elapsedTime = DateTime.now().difference(startTime);
    final remainingTime = Duration(seconds: 5) - elapsedTime;

    // Wait for the remaining time, ensuring it's not negative
    await Future.delayed(remainingTime > Duration.zero ? remainingTime : Duration.zero);

    if (isFirstLaunch) {
      // Switch to welcome screen
      setState(() {
        _showingWelcomeScreen = true;
      });
      _webViewController?.loadFile(assetFilePath: 'assets/html/welcome_screen.html');

      // Start a 3-second delay, but allow user to tap to skip
      Future.delayed(const Duration(seconds: 30), () {
        if (mounted && _showingWelcomeScreen) {
          _navigateToHomeScreen();
        }
      });


    } else {
      _navigateToHomeScreen();
    }
  }

  void _navigateToHomeScreen() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        //MaterialPageRoute(builder: (context) => const HomeScreen()),
        MaterialPageRoute(builder: (context) => const ScannerScreen())
      );
    }
  }

  @override
  Widget build(BuildContext context) {
  return Stack(
    children: [
      // WebView as background
      InAppWebView(
        // initialFile: 'assets/html/splash_screen.html',
        onWebViewCreated: (controller) {
          _webViewController = controller;
          _initializeAndNavigate();
        },
      ),
      // Transparent tap detector (only active for welcome screen)
      if (_showingWelcomeScreen)
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              _navigateToHomeScreen(); // Skip welcome screen on tap
            },
            child: Container(color: Colors.transparent), // Invisible overlay
          ),
        ),
      ],
    );
  }
}

