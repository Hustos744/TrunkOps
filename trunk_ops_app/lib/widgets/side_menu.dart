import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class SideMenu extends StatelessWidget {
  /// Активний пункт меню
  final int selectedIndex;

  /// Чи меню зараз розкрите
  final bool isExpanded;

  /// Клік по пункту меню (міняє контент справа)
  final ValueChanged<int> onItemSelected;

  /// Зміна стану розкриття/стиснення меню
  final ValueChanged<bool> onExpandedChanged;

  const SideMenu({
    super.key,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onItemSelected,
    required this.onExpandedChanged,
  });

  static const double _collapsedWidth = 72;

  static const List<_MenuItemData> _topItems = [
    _MenuItemData(icon: Icons.dashboard_outlined, label: 'Dashboard'),
    _MenuItemData(icon: Icons.map_outlined, label: 'Мапа покриття'),
    _MenuItemData(icon: Icons.shield_outlined, label: 'Підрозділи'),
    _MenuItemData(icon: Icons.devices_other_outlined, label: 'Облік засобів'),
    _MenuItemData(icon: Icons.build_circle_outlined, label: 'Обслуговування'),
    _MenuItemData(icon: Icons.article_outlined, label: 'Журнал аудиту'),
  ];

  static const List<_MenuItemData> _bottomItems = [
    _MenuItemData(icon: Icons.settings_outlined, label: 'Налаштування'),
    _MenuItemData(icon: Icons.notifications_none_outlined, label: 'Сповіщення'),
    _MenuItemData(icon: Icons.logout_outlined, label: 'Вихід'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    final screenWidth = MediaQuery.of(context).size.width;
    final expandedWidth = (screenWidth * 0.18).clamp(200.0, 320.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      width: isExpanded ? expandedWidth : _collapsedWidth,
      color: colorScheme.surface, // фон меню з теми
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Хедер з логотипом — завжди по центру по горизонталі
          GestureDetector(
            onTap: () => onExpandedChanged(!isExpanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool canShowText =
                      isExpanded && constraints.maxWidth > 140;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/trunkops_logo.svg',
                        width: 28,
                        height: 28,
                        colorFilter: ColorFilter.mode(
                          extra.warning, // золото з теми
                          BlendMode.srcIn,
                        ),
                      ),
                      if (canShowText) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'TrunkOps',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontFamily: 'Volja',
                              fontSize: 18,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // УСІ пункти меню в одному ListView (верхні + нижні)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: [
                for (var i = 0; i < _topItems.length; i++)
                  _MenuTile(
                    data: _topItems[i],
                    index: i,
                    selectedIndex: selectedIndex,
                    isExpanded: isExpanded,
                    onItemSelected: onItemSelected,
                    onExpandedChanged: onExpandedChanged,
                  ),

                const SizedBox(height: 12),
                Divider(color: extra.borderDefault, height: 24),
                const SizedBox(height: 4),

                for (var i = 0; i < _bottomItems.length; i++)
                  _MenuTile(
                    data: _bottomItems[i],
                    index: _topItems.length + i,
                    selectedIndex: selectedIndex,
                    isExpanded: isExpanded,
                    onItemSelected: onItemSelected,
                    onExpandedChanged: onExpandedChanged,
                  ),

                const SizedBox(height: 8),
              ],
            ),
          ),

          // Нижня стрілочка згортання
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 4),
              child: Center(
                child: GestureDetector(
                  onTap: () => onExpandedChanged(false),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: extra.surfaceElevated,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: extra.borderDefault, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.5),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.keyboard_double_arrow_left,
                      size: 20,
                      color: extra.borderLight,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;

  const _MenuItemData({required this.icon, required this.label});
}

class _MenuTile extends StatelessWidget {
  final _MenuItemData data;
  final int index;
  final int selectedIndex;
  final bool isExpanded;
  final ValueChanged<int> onItemSelected;
  final ValueChanged<bool> onExpandedChanged;

  const _MenuTile({
    required this.data,
    required this.index,
    required this.selectedIndex,
    required this.isExpanded,
    required this.onItemSelected,
    required this.onExpandedChanged,
  });

  bool get isActive => index == selectedIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool canShowText = isExpanded && constraints.maxWidth > 130;
        final bool isCollapsedView = !canShowText; // стисле меню
        final bool highlightRow = isActive && !isCollapsedView;

        // фон всього рядка (тільки в розгорнутому активному)
        final Color tileBg = highlightRow
            ? extra.accentSoft
            : Colors.transparent;

        final Color tileBorder = highlightRow
            ? extra.accent
            : Colors.transparent;

        // базові значення для іконки
        Color iconBg = isActive ? extra.accentSoft : Colors.transparent;
        Color iconBorder = isActive ? Colors.transparent : extra.borderDefault;
        Color iconColor = isActive
            ? colorScheme.onPrimary
            : theme.textTheme.bodySmall?.color ??
                  colorScheme.onSurface.withOpacity(0.7);

        // 🔥 СПЕЦІАЛЬНЕ ВИДІЛЕННЯ ДЛЯ СТИСЛОГО МЕНЮ
        if (isCollapsedView && isActive) {
          iconBg = extra.accentSoft;
          iconBorder = extra.accent.withOpacity(0.8);
          iconColor = extra.accent; // яскравий золотий/primary акцент
        }

        final Color textColor = highlightRow
            ? colorScheme.onSurface
            : theme.textTheme.bodySmall?.color ??
                  colorScheme.onSurface.withOpacity(0.8);

        final FontWeight textWeight = highlightRow
            ? FontWeight.w600
            : FontWeight.w400;

        final BorderRadius iconRadius = BorderRadius.circular(
          isCollapsedView ? 999 : 10,
        );

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            onItemSelected(index);

            // якщо меню стисло — розгортаємо, якщо розгорнуте — стискаємо
            if (!isExpanded) {
              onExpandedChanged(true);
            } else {
              onExpandedChanged(false);
            }
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: tileBorder,
                width: highlightRow ? 1.2 : 0.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            child: Row(
              mainAxisAlignment: canShowText
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                // Ліва смужка тільки в розгорнутому режимі
                if (canShowText)
                  Container(
                    width: 3,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isActive ? extra.warning : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),

                // Іконка
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: iconRadius,
                    border: Border.all(
                      color: iconBorder,
                      width: isActive && !isCollapsedView ? 0.0 : 1.0,
                    ),
                  ),
                  child: Icon(data.icon, color: iconColor),
                ),

                // Текст — тільки в розгорнутому
                if (canShowText) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontSize: 14,
                        color: textColor,
                        fontWeight: textWeight,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
