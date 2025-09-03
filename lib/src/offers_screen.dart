import 'package:flutter/material.dart';
import 'widgets/deal_tab_widget.dart';
import 'widgets/navbar_bottom_widget.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OffersScreen> {
  String postalCode = "M5V3C6"; // Preset postal code

  @override
  void initState() {
    super.initState();
    _getPostalCode(0,0); // Call the function to fetch details
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DealTabWidget(postalCode: postalCode),
      bottomNavigationBar: const NavbarBottomWidget(currentRoute: '/offers'),
    );
  }

  Future<void> _getPostalCode(double lat, double lng) async {
    // Fetch barcode data
    try {
      // postalCode = await _barcodeDataServices.fetchBarcodeData(barcode);
      debugPrint('Postal Code: $postalCode');
    } catch (e) {
      debugPrint('Error: $e');
    }

  }


}