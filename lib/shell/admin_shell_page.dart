import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/features/bookings/bookings_page.dart';
import 'package:smartbandhu_admin/features/control/control_page.dart';
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
        case 2:
          return UsersPage(key: const PageStorageKey('users'), api: widget.api);
        default:
          return ControlPage(key: const PageStorageKey('control'), api: widget.api);
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
            Expanded(
              child: Text(
                'SmartBondhu Admin',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
      body: _pageForIndex(_index),
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 56,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavIcon(
                index: 0,
                current: _index,
                icon: Icons.dashboard_outlined,
                activeIcon: Icons.dashboard,
                tooltip: 'Dashboard',
                onTap: () => setState(() => _index = 0),
              ),
              _NavIcon(
                index: 1,
                current: _index,
                icon: Icons.event_note_outlined,
                activeIcon: Icons.event_note,
                tooltip: 'Bookings',
                onTap: () => setState(() => _index = 1),
              ),
              _NavIcon(
                index: 2,
                current: _index,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                tooltip: 'Users',
                onTap: () => setState(() => _index = 2),
              ),
              _NavIcon(
                index: 3,
                current: _index,
                icon: Icons.tune_outlined,
                activeIcon: Icons.tune,
                tooltip: 'Control',
                onTap: () => setState(() => _index = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.index,
    required this.current,
    required this.icon,
    required this.activeIcon,
    required this.tooltip,
    required this.onTap,
  });

  final int index;
  final int current;
  final IconData icon;
  final IconData activeIcon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 56,
          height: 48,
          child: Icon(
            selected ? activeIcon : icon,
            color: selected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
