import 'package:flutter/material.dart';

class NavbarBottomWidget extends StatelessWidget {
  final String currentRoute;

  const NavbarBottomWidget({super.key, required this.currentRoute});

  static final List<Map<String, dynamic>> _items = [
    // {'icon': Icons.location_on_outlined, 'label': 'Location', 'route': '/location'},
    {'icon': Icons.local_offer_outlined, 'label': 'Hot Deals', 'route': '/offers'},
    {'icon': Icons.flip_sharp, 'label': 'Scan Barcode', 'route': '/scanner'},
  ];

  void _navigate(BuildContext context, int index) {
    final route = _items[index]['route'];
    if (route == currentRoute) return; // avoid redundant navigation
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    // Find the index of the current route
    final currentIndex = _items.indexWhere((item) => item['route'] == currentRoute);

    // Fallback to 0 if route not found (to avoid crash)
    final safeIndex = currentIndex == -1 ? 0 : currentIndex;

    return BottomNavigationBar(
      currentIndex: safeIndex,
      onTap: (index) => _navigate(context, index),
      selectedItemColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), // pale grey
      unselectedItemColor: Theme.of(context).colorScheme.onSurface, // dark for contrast
      items: _items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item['icon']),
          label: item['label'],
        );
      }).toList(),
    );
  }
}