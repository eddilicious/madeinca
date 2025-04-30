import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' show parseFragment;
import 'package:html/dom.dart' as dom;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'app_server_services.dart';

class GS1Service {
  // Set up the class as a singleton
  static final GS1Service _instance = GS1Service._internal(); // ✅ Singleton instance
  
  String cookiesString = 'OptanonAlertBoxClosed=2025-02-27T03:28:53.864Z; _ga=GA1.1.1422167157.1740626934; Drupal.visitor.teamMember=no; SSESS924798324822d30ca03a54f5de4e433f=JVNyhsxh-Z05mAGPRj4BhMoPWujzwf6F64B%2Cyi2Bi-xflRWe; gsone_verified_search_terms_1_2=1; vfs_token=xnjq4gj7T2E_hmNgOW3OiLTK5KxzEsuP80RNQRVpzOM; _ga_49BMZJWL9R=GS1.1.1740629085.2.0.1740629085.60.0.0; OptanonConsent=isGpcEnabled=0&datestamp=Wed+Feb+26+2025+23%3A30%3A41+GMT-0500+(Eastern+Standard+Time)&version=6.30.0&isIABGlobal=false&hosts=&landingPath=NotLandingPage&groups=C0001%3A1%2CC0003%3A0%2CC0002%3A0%2CC0004%3A0&geolocation=CA%3BQC&AwaitingReconsent=false';
  Map<String, String> captcha = {};
  bool online = false;
  bool verified = false;

  factory GS1Service() {
    return _instance;
  }

  GS1Service._internal(); // ✅ Private constructor
  // Complete singleton preparation


  /// ✅ Initialization function to check server status
  Future<void> initialize() async {

    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("gs1_cookies")) {
      cookiesString = prefs.getString("gs1_cookies")!;
    }
    initializeCookies(cookiesString);

    if (prefs.containsKey("gs1_captcha")) {
      String strCaptcha = prefs.getString("gs1_captcha")!;
      if (strCaptcha.isNotEmpty) {
        Map<String, dynamic> newCaptcha = jsonDecode(strCaptcha);
        String captcha_sid = newCaptcha['captcha_sid']?.toString() ?? "";
        String captcha_token = newCaptcha['captcha_token']?.toString() ?? "";
        String vfs_token = newCaptcha['vfs_token']?.toString() ?? "";
        String form_build_id = newCaptcha['form_build_id']?.toString() ?? "";
        updateBodyCaptcha(captcha_sid, captcha_token, vfs_token, form_build_id);
      }
    }

    await fetchCookiesInBackground();
  }

  Future<void> updateBodyCaptcha(String captcha_sid, String captcha_token, String vfs_token, String form_build_id) async{
    try {
      String? sid2Str = body['captcha_sid']?.toString();

      int? sid1 = int.tryParse(captcha_sid);
      int? sid2 = (sid2Str != null) ? int.tryParse(sid2Str) : null;

      if (sid1 != null && sid2 != null && sid1 > sid2) {
        if (captcha_sid != "") { body['captcha_sid'] = captcha_sid;}
        if (captcha_token != "") {body['captcha_token'] = captcha_token;}
        if (vfs_token != "") {body['vfs_token'] = vfs_token;}
        if (form_build_id != "") {body['form_build_id'] = form_build_id;}
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> updatePrefCaptcha(String captcha_sid, String captcha_token, String vfs_token, String form_build_id) async {
    final prefs = await SharedPreferences.getInstance();
    String appCaptcha = "";

    try {
      Map<String, dynamic> newCaptcha = {
        'captcha_sid': captcha_sid,
        'captcha_token': captcha_token,
        'vfs_token': vfs_token,
        'form_build_id': form_build_id,
      };

      if (prefs.containsKey("gs1_captcha")) {
        appCaptcha = prefs.getString("gs1_captcha")!;
      }  

      if (appCaptcha.isNotEmpty) {
        Map<String, dynamic> mapCaptcha = jsonDecode(appCaptcha);
        String? sid1Str = mapCaptcha['captcha_sid']?.toString();
 
        int? sid1 = (sid1Str != null) ? int.tryParse(sid1Str) : null;
        int? sid2 = int.tryParse(captcha_sid);

        if (sid1 != null && sid2 != null && sid1 <= sid2) {
          String strCaptcha = jsonEncode(newCaptcha);
          await prefs.setString("gs1_captcha", strCaptcha);
          // Update the captcha to the server
          var response = await AppServerService().postRequest("/update-captcha.php", newCaptcha);
          if (response != null) {
            debugPrint("Server Response: $response");
          } 
        }

      } else {
        await prefs.setString("gs1_captcha", jsonEncode(newCaptcha));
      } 

    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchCookiesInBackground() async {
    
    HeadlessInAppWebView? headlessWebView;
    CookieManager cookieManager = CookieManager.instance();

    headlessWebView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri("https://www.gs1.org/services/verified-by-gs1/results")),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true, // Enable JavaScript
      ),
      onLoadStop: (controller, url) async {
        if (online) { return;}

        try {
          // Simulate clicking the cookie consent button
          await controller.evaluateJavascript(source: """
            document.getElementById('onetrust-reject-all-handler')?.click();
          """);

          // Wait a few seconds to let the website set cookies
          await Future.delayed(Duration(seconds: 3));

          // Extract cookies using JavaScript
          String newCookies = await controller.evaluateJavascript(source: "document.cookie");
          debugPrint("New Cookies: $newCookies");

          // Extract structured cookies using CookieManager
          List<Cookie> cookieList = await cookieManager.getCookies(url: url!);
          for (var cookie in cookieList) {
            debugPrint("Cookie: ${cookie.name}=${cookie.value}");
            debugPrint("Current Cookies: ${cookies[cookie.name]}");
            cookies[cookie.name] = cookie.value;
          }

          
          // Wait a few seconds to let the website set cookies
          // await Future.delayed(Duration(seconds: 10));

          // Get the modified HTML from the WebView
          /*
          String? modifiedHtml = await controller.evaluateJavascript(
            source: "document.documentElement.outerHTML"
          );

          if (modifiedHtml == null || modifiedHtml.isEmpty) {
            debugPrint("Error: Modified HTML is empty");
          } else {
            // Save the modified HTML to a file
            await writeToFile('init.html', modifiedHtml);
          }
          */
          

          // Close WebView
          // Extract cookies using JavaScript
          verified = await controller.evaluateJavascript(source: "!document.querySelector('[data-drupal-selector=\"edit-captcha\"]')");

          online = true;
        } catch (e) {
          debugPrint("Error: $e");
        }

        await headlessWebView?.dispose();
      },
    );

    // Start the headless WebView
    await headlessWebView.run();
  }

  Future<void> writeToFile(String fileName, String content) async {
    // Get the directory for external storage (Downloads folder)
    Directory? directory = Directory('/storage/emulated/0/Download');

    if (!directory.existsSync()) {
      debugPrint("Directory does not exist!");
      return;
    }

    // Create the file
    File file = File('${directory.path}/$fileName');

    // Write to file
    await file.writeAsString(content);
    debugPrint("File written: ${file.path}");
  }


  Future<String> fetchBarcodeService(String barcode) async {
    final url = Uri.parse(
        'https://www.gs1.org/services/verified-by-gs1/results?gtin=$barcode&ajax_form=1&_wrapper_format=drupal_ajax');

    body['gtin'] = barcode;
    String retVal = '';

    try {
      int count = 0;
      bool resending = true;

      while (resending) {
        count++;
        if (count > 1) {
          await Future.delayed(Duration(seconds: 5));
        }

        headers['Cookie'] = getCookiesString();
debugPrint("Headers: ${jsonEncode(headers)}");
debugPrint("Body: ${jsonEncode(body)}");
        http.Response response = await http.post(url, headers: headers, body: body);

        if (response.headers.containsKey("set-cookie")) {
          var newcookie = response.headers["set-cookie"];
          debugPrint("New Cookies: $newcookie");
          if (newcookie is String && newcookie.isNotEmpty) {
            updateCookie(newcookie); // Extract cookie
          }
          resending = true;
        } else {
          resending= false; // Extract cookie
        }

        List<dynamic> jsonData = jsonDecode(response.body);
        String newBuildId = '';

        // Loop through each command
        for (var item in jsonData) {
          if (item is Map<String, dynamic> && item['command'] == 'update_build_id') {
            newBuildId = item['new']; // Extract the "new" value
            body['form_build_id'] = newBuildId;

          } else if (item is Map<String, dynamic> && item['command'] == 'insert' && item['method'] == 'replaceWith') {
            // Extract the "data" value
            String encodedHtml = item['data'];
            String html = uniDecode(encodedHtml);
            if (item['selector'] == '#verified-search-form-wrapper') {
              await updateRequestForm(html, newBuildId);
            } else if (item['selector'] == '#product-container') {
                resending= false;
                retVal = getCompanyInfoJson(html);
            }
            count += 1;
          }
        }


      }
    } catch (e) {
      retVal = '';
    }

    return retVal;
  }

  Future<void> updateRequestForm(String html, String newBuildId) async{
    String captchaSid = '';
    String captchaToken = '';
    String vfsToken = '';

    // Parse the HTML fragment into a DocumentFragment
    dom.DocumentFragment doc = parseFragment(html);

    // Use a CSS selector to locate the input element
    dom.Element? element = doc.querySelector('input[data-drupal-selector="edit-captcha-sid"]');
    element ??= doc.querySelector('input[name="captcha_sid"]');
    if (element != null) {
      // Get the value attribute of the input element
      captchaSid = element.attributes['value'] ?? '';
    } 

    element = doc.querySelector('input[data-drupal-selector="edit-captcha-token"]');
    element ??= doc.querySelector('input[name="captcha_token"]');
    if (element != null) {
      // Get the value attribute of the input element
      captchaToken = element.attributes['value'] ?? '';
    } 

    element = doc.querySelector('input[data-drupal-selector="edit-vfs-token"]');
    element ??= doc.querySelector('input[name="vfs_token"]');
    if (element != null) {
      // Get the value attribute of the input element
      vfsToken = element.attributes['value'] ?? '';
    } 

    debugPrint('Captcha SID: $captchaSid \n Captcha Token: $captchaToken \n VFS Token: $vfsToken');
    await updateBodyCaptcha(captchaSid, captchaToken, vfsToken, newBuildId);
    await updatePrefCaptcha(captchaSid, captchaToken, vfsToken, newBuildId);

  }

  String getCompanyInfoJson(String html) {
    // Parse the HTML content
    dom.DocumentFragment doc = parseFragment(html);

    // Find the div with id="companyInformation"
    dom.Element? container = doc.querySelector('#companyInformation');
    container ??= doc.querySelector('.tab-content');
    if (container == null) {return '';}

    // Select all table rows within the <table class="company">
    List<dom.Element> rows = container.querySelectorAll('.company tr');

    // Create a map to store extracted data
    Map<String, String> companyInfo = {};
    // Loop through each <tr> and extract the key-value pairs
    for (var row in rows) {
      List<dom.Element> cells = row.querySelectorAll('td');
      if (cells.length == 2) {
        String key = cells[0].text.trim();
        String value = cells[1].text.trim();
        companyInfo[key] = value;
      }
    }

    companyInfo['made'] = companyInfo['Licensing GS1 Member Organisation']!.replaceAll("GS1 ", "");
    companyInfo['gln'] = companyInfo['Global Location Number (GLN)']!;
    companyInfo['Company'] = companyInfo['Company Name']!;
    companyInfo.remove('Licensing GS1 Member Organisation');
    companyInfo.remove('Global Location Number (GLN)');
    companyInfo.remove('Company Name');
    String company = companyInfo['Company'] ?? '';
    String address = companyInfo['Address'] ?? '';
    address = address.replaceFirst(company, "").trim();
    companyInfo['Address'] = address;


    // Convert to JSON string
    return jsonEncode(companyInfo);
  }


  Map<String, String> headers = {
    'authority': 'www.gs1.org',
    'method': 'POST',
    'scheme': 'https',
    'path': '/services/verified-by-gs1/results?gtin=067714008241&ajax_form=1&_wrapper_format=drupal_ajax',
    'Accept': 'application/json, text/javascript, */*; q=0.01',
    'Accept-Encoding': 'gzip, deflate, br, zstd',
    'Accept-Language': 'en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7,ru;q=0.6',
    'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
    //'Cookie': getCookiesString(),
    //'Cookie': 'OptanonAlertBoxClosed=2025-02-27T03:28:53.864Z; _ga=GA1.1.1422167157.1740626934; Drupal.visitor.teamMember=no; SSESS924798324822d30ca03a54f5de4e433f=JVNyhsxh-Z05mAGPRj4BhMoPWujzwf6F64B%2Cyi2Bi-xflRWe; gsone_verified_search_terms_1_2=1; vfs_token=xnjq4gj7T2E_hmNgOW3OiLTK5KxzEsuP80RNQRVpzOM; _ga_49BMZJWL9R=GS1.1.1740629085.2.0.1740629085.60.0.0; OptanonConsent=isGpcEnabled=0&datestamp=Wed+Feb+26+2025+23%3A30%3A41+GMT-0500+(Eastern+Standard+Time)&version=6.30.0&isIABGlobal=false&hosts=&landingPath=NotLandingPage&groups=C0001%3A1%2CC0003%3A0%2CC0002%3A0%2CC0004%3A0&geolocation=CA%3BQC&AwaitingReconsent=false',
    'X-Requested-With': 'XMLHttpRequest',
    'Origin': 'https://www.gs1.org',
    'Referer': 'https://www.gs1.org/services/verified-by-gs1/results?gtin=',
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
    'Sec-Fetch-Dest': 'empty',
    'Sec-Fetch-Mode': 'cors',
    'Sec-Fetch-Site': 'same-origin',
    'Sec-Ch-Ua': '"Google Chrome";v="123", "Not:A-Brand";v="8", "Chromium";v="123"',
    'Sec-Ch-Ua-Mobile': '?0',
    'Sec-Ch-Ua-Platform': '"Windows"',
  };

  Map<String, String> body = {
    'search_type': 'gtin',
    'gtin': '067714008241',
    'gln': '',
    'country': '',
    'street_address': '',
    'postal_code': '',
    'city': '',
    'company_name': '',
    'other_key_type': '',
    'other_key': '',
    'vfs_token': 'xnjq4gj7T2E_hmNgOW3OiLTK5KxzEsuP80RNQRVpzOM',
    'captcha_sid': '11100969', //'10930582',
    'captcha_token': 'zp0sDeGFWMWr-Oz2jsDSiJ33B7S6uC4Jlujs6zdNODE', //'yDVSnMcFJJLOr8xsx_BOFZJJZkiKlMhUgHqa0VuIcd4',
    'captcha_response': '',
    'form_build_id': 'form-jnN18hOLTSrgNQJUyhy2AWMwsJjvG395t2yiaHDa_FM',
    'form_id': 'verified_search_form',
    '_triggering_element_name': 'gtin_submit',
    '_triggering_element_value': 'Search',
    '_drupal_ajax': '1',
    'ajax_page_state[theme]': 'gsone_revamp',
    'ajax_page_state[theme_token]': '',
    'ajax_page_state[libraries]': 'addtoany/addtoany.front,bootstrap_barrio/bootstrap-icons',
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

  Future<void> updateCookie(String cookie) async {
    // Extract only the 'name=value' part before the first semicolon
    String newCookie = cookie.split(";")[0].trim();
    int idx = newCookie.indexOf('=');
    if (idx != -1) {
    // Extract name and value based on the first '=' occurrence
      String name = newCookie.substring(0, idx);
      String value = newCookie.substring(idx + 1);
      debugPrint("Update Cookie: $name=$value");
      debugPrint("Current Cookies: ${cookies[name]}");
      //cookies[name] = value;
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



}