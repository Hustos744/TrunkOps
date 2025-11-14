import 'package:flutter/material.dart';
import 'package:trunk_ops_app/screens/shell/pages/assets_page.dart';
import 'package:trunk_ops_app/screens/shell/pages/audit_log_page.dart';
import 'package:trunk_ops_app/screens/shell/pages/maintenance_page.dart';
import 'package:trunk_ops_app/screens/shell/pages/notifications_page.dart';
import 'package:trunk_ops_app/screens/shell/pages/settings_page.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

import '../../widgets/side_menu.dart';
import 'pages/coverage_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/units_page.dart';

class DashboardShellScreen extends StatefulWidget {
  static const routeName = '/dashboard';

  const DashboardShellScreen({super.key});

  @override
  State<DashboardShellScreen> createState() => _DashboardShellScreenState();
}

class _DashboardShellScreenState extends State<DashboardShellScreen> {
  int _selectedIndex = 0;
  bool _isMenuExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = context.extra; // з AppExtraColorsX

    return Scaffold(
      // темний "outer" фон навколо всієї панелі
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            // світліша робоча панель
            decoration: BoxDecoration(
              color: extra.surfaceSubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: extra.borderDefault.withOpacity(0.9),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Бокове меню
                SideMenu(
                  selectedIndex: _selectedIndex,
                  isExpanded: _isMenuExpanded,
                  onItemSelected: (index) {
                    // 8 — "Вихід"
                    if (index == 8) {
                      // TODO: тут зробиш logout + перехід на LoginScreen
                      return;
                    }
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  onExpandedChanged: (expanded) {
                    setState(() {
                      _isMenuExpanded = expanded;
                    });
                  },
                ),

                // Права частина — контент + затемнення (тільки над ним)
                Expanded(
                  child: Stack(
                    children: [
                      // Контент сторінок
                      IndexedStack(
                        index: _selectedIndex,
                        children: const [
                          DashboardPage(),
                          CoveragePage(),
                          UnitsPage(),
                          AssetsPage(),
                          MaintenancePage(),
                          AuditLogPage(),
                          SettingsPage(),
                          NotificationsPage(),
                          // index 8 — logout, контент не потрібен
                        ],
                      ),

                      // Затемнення ТІЛЬКИ над контентом, а НЕ над меню
                      if (_isMenuExpanded)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _isMenuExpanded = false;
                            });
                          },
                          child: Container(
                            color: colorScheme.scrim.withOpacity(0.35),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
