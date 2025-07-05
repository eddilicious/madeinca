import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_review/in_app_review.dart';


class RateAppService {
  static Future<void> showRatePopupIfNeeded(BuildContext context) async {

    final prefs = await SharedPreferences.getInstance();
    bool hasRated = prefs.getBool('has_rated') ?? false;
    if (hasRated) return; // User already rated

    var usageCount = prefs.getInt("usage_count") ?? 0;
    if (usageCount == 10 || (usageCount % 100 == 0 && usageCount > 10)) {
      // One hack to check if context is still valid
      try {
        // Try accessing something from the context
        context.findRenderObject();
      } catch (e) {
        return; // Context is not valid, exit early
      }

      // Show the dialog BEFORE checking inAppReview availability
      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => RateDialog(),
      );

      if (result != true) return;

      final inAppReview = InAppReview.instance;

      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        // If in-app is not available, open the store
        if (Platform.isIOS) {
          await inAppReview.openStoreListing(appStoreId: '6745431345'); // 👈 REQUIRED on iOS
        } else {
          await inAppReview.openStoreListing(); // 👈 No ID needed on Android
        }
      }

      await prefs.setBool('has_rated', true); // Remember they rated
    }

    // Show the popup only if the app has been used at least 5 times
    usageCount++;
    await prefs.setInt("usage_count", usageCount);
    return;

  }

}


class RateDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Rate the app"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("Are you enjoying the app?"),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '🍁',
                style: TextStyle(fontSize: 28),
              ),
            ),),  // Use heart icon Icon(Icons.favorite, color: Colors.red)
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text("Later, eh?"),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        TextButton(
          child: Text("Let’s rate it"),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
