// lib/screens/home_shell.dart - ALIGNED WITH NEW APP THEME
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/api_client.dart';
import 'tab_search_professional.dart';
import 'tab_publish.dart';
import 'tab_my_rides.dart';
import 'tab_inbox.dart';
import 'tab_profile.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.api});
  final ApiClient api;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      TabSearchProfessional(api: widget.api),
      TabPublish(api: widget.api),
      TabMyRides(api: widget.api),
      TabInbox(api: widget.api),
      TabProfile(api: widget.api),
    ];

    return Scaffold(
      body: tabs[_index],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          indicatorColor: AppTheme.primaryBlue.withOpacity(0.1),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.search_outlined,
                color: _index == 0 ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
              selectedIcon: const Icon(Icons.search, color: AppTheme.primaryBlue),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.add_circle_outline,
                color: _index == 1 ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
              selectedIcon: const Icon(Icons.add_circle, color: AppTheme.primaryBlue),
              label: 'Publish',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.directions_car_outlined,
                color: _index == 2 ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
              selectedIcon: const Icon(Icons.directions_car, color: AppTheme.primaryBlue),
              label: 'Your Rides',
            ),
            NavigationDestination(
              icon: Stack(
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    color: _index == 3 ? AppTheme.primaryBlue : AppTheme.textMuted,
                  ),
                  // Add unread indicator (you can implement this based on actual unread count)
                  // Positioned(
                  //   top: 0,
                  //   right: 0,
                  //   child: Container(
                  //     width: 8,
                  //     height: 8,
                  //     decoration: const BoxDecoration(
                  //       color: AppTheme.statusError,
                  //       shape: BoxShape.circle,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
              selectedIcon: const Icon(Icons.inbox, color: AppTheme.primaryBlue),
              label: 'Inbox',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: _index == 4 ? AppTheme.primaryBlue : AppTheme.textMuted,
              ),
              selectedIcon: const Icon(Icons.person, color: AppTheme.primaryBlue),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
