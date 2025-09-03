import 'package:flutter/material.dart';

class AppBarActionsWidget extends StatelessWidget {
  final String currentPage; // e.g., 'location', 'scan', 'settings'

  const AppBarActionsWidget({super.key, required this.currentPage});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildIcon(
          context,
          icon: Icons.location_on_outlined,
          tooltip: 'Location',
          route: '/location',
          isActive: currentPage != 'location',
        ),
        _buildIcon(
          context,
          icon: Icons.local_offer_outlined,
          tooltip: 'Offers',
          route: '/offers',
          isActive: currentPage != 'offers',
        ),
        _buildIcon(
          context,
          icon: Icons.flip_sharp,
          tooltip: 'Scan',
          route: '/scan',
          isActive: currentPage != 'scan',
        ),
        _buildIcon(
          context,
          icon: Icons.settings,
          tooltip: 'Settings',
          route: '/settings',
          isActive: currentPage != 'settings',
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context,
      {required IconData icon,
      required String tooltip,
      required String route,
      required bool isActive}) {
    return IconButton(
      icon: Icon(icon,
          color: isActive ? Colors.black : Colors.grey.shade400), // dim if inactive
      tooltip: tooltip,
      onPressed: isActive
          ? () {
              Navigator.pushNamed(context, route);
            }
          : null, // disables the button
    );
  }
}
