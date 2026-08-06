import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/features/bookings/bookings_page.dart';
import 'package:smartbandhu_admin/features/dashboard/dashboard_page.dart';
import 'package:smartbandhu_admin/features/users/users_page.dart';

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;
  final _builtPages = <int, Widget>{};

  Widget _pageForIndex(int index) {
    return _builtPages.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return DashboardPage(key: const PageStorageKey('dashboard'), api: widget.api);
        case 1:
          return BookingsPage(key: const PageStorageKey('bookings'), api: widget.api);
        default:
          return UsersPage(key: const PageStorageKey('users'), api: widget.api);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Text(
                'SB',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SmartBondhu Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Internal dashboard', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
      body: _pageForIndex(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.event_note_outlined), selectedIcon: Icon(Icons.event_note), label: 'Bookings'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Users'),
        ],
      ),
    );
  }
}
