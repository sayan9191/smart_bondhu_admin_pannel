import 'package:flutter/material.dart';
import 'package:smartbandhu_admin/core/theme/app_theme.dart';
import 'package:smartbandhu_admin/data/admin_api.dart';
import 'package:smartbandhu_admin/features/banners/banners_page.dart';
import 'package:smartbandhu_admin/features/bookings/bookings_page.dart';
import 'package:smartbandhu_admin/features/catalog/catalog_page.dart';
import 'package:smartbandhu_admin/features/control/control_page.dart';
import 'package:smartbandhu_admin/features/dashboard/dashboard_page.dart';
import 'package:smartbandhu_admin/features/enquiries/enquiries_page.dart';
import 'package:smartbandhu_admin/features/users/users_page.dart';

class _MenuItem {
  const _MenuItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

const _menu = <_MenuItem>[
  _MenuItem(label: 'Dashboard', icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard),
  _MenuItem(label: 'Catalog', icon: Icons.category_outlined, activeIcon: Icons.category),
  _MenuItem(label: 'Banners', icon: Icons.view_carousel_outlined, activeIcon: Icons.view_carousel),
  _MenuItem(label: 'Bookings', icon: Icons.event_note_outlined, activeIcon: Icons.event_note),
  _MenuItem(label: 'Website enquiries', icon: Icons.mark_email_unread_outlined, activeIcon: Icons.mark_email_unread),
  _MenuItem(label: 'Users', icon: Icons.people_outline, activeIcon: Icons.people),
  _MenuItem(label: 'Control', icon: Icons.tune_outlined, activeIcon: Icons.tune),
];

class AdminShellPage extends StatefulWidget {
  const AdminShellPage({super.key, required this.api});

  final AdminApi api;

  @override
  State<AdminShellPage> createState() => _AdminShellPageState();
}

class _AdminShellPageState extends State<AdminShellPage> {
  int _index = 0;
  final _builtPages = <int, Widget>{};
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Widget _pageForIndex(int index) {
    return _builtPages.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return DashboardPage(key: const PageStorageKey('dashboard'), api: widget.api);
        case 1:
          return CatalogPage(key: const PageStorageKey('catalog'), api: widget.api);
        case 2:
          return BannersPage(key: const PageStorageKey('banners'), api: widget.api);
        case 3:
          return BookingsPage(key: const PageStorageKey('bookings'), api: widget.api);
        case 4:
          return EnquiriesPage(key: const PageStorageKey('enquiries'), api: widget.api);
        case 5:
          return UsersPage(key: const PageStorageKey('users'), api: widget.api);
        default:
          return ControlPage(key: const PageStorageKey('control'), api: widget.api);
      }
    });
  }

  void _select(int index) {
    setState(() => _index = index);
    _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final menu = _SideMenu(current: _index, onSelect: _select);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          _menu[_index].label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        automaticallyImplyLeading: !wide,
      ),
      drawer: wide ? null : Drawer(child: menu),
      body: Row(
        children: [
          if (wide) SizedBox(width: 260, child: menu),
          Expanded(child: _pageForIndex(_index)),
        ],
      ),
    );
  }
}

class _SideMenu extends StatelessWidget {
  const _SideMenu({required this.current, required this.onSelect});

  final int current;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
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
                  const Expanded(
                    child: Text(
                      'SmartBondhu Admin',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  for (var i = 0; i < _menu.length; i++)
                    _MenuTile(
                      item: _menu[i],
                      selected: i == current,
                      onTap: () => onSelect(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _MenuItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        selected: selected,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
        leading: Icon(
          selected ? item.activeIcon : item.icon,
          color: selected ? AppColors.primary : AppColors.textSecondary,
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
