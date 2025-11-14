import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

/// Сторінка сповіщень.
///
/// Показує останні сповіщення у вигляді списку або таблиці залежно від
/// ширини екрана. Кожне сповіщення містить іконку, заголовок, опис та
/// відмітку часу. Статуси сповіщень (наприклад, нове чи прочитане) також
/// відображаються різними кольорами з теми.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    // Демонстраційні дані сповіщень
    final List<Map<String, dynamic>> notifications = [
      {
        'icon': Icons.warning_amber_outlined,
        'title': 'Критичний інцидент',
        'description': 'Перевантаження на вузлі №5 перевищує 90%',
        'time': '13.11.2025 11:25',
        'status': 'unread',
      },
      {
        'icon': Icons.info_outline,
        'title': 'Планове обслуговування',
        'description': 'Завтра о 08:00 запланована технічна перевірка',
        'time': '13.11.2025 10:00',
        'status': 'read',
      },
      {
        'icon': Icons.check_circle_outline,
        'title': 'Оновлення завершено',
        'description': 'Підрозділ Alpha успішно оновив обладнання',
        'time': '12.11.2025 16:45',
        'status': 'read',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Сповіщення',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: extra.borderDefault),
                ),
                padding: const EdgeInsets.all(16),
                child: isWide
                    ? _buildTable(context, notifications, extra)
                    : _buildList(context, notifications, extra),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Побудова таблиці сповіщень для широких екранів.
  Widget _buildTable(BuildContext context,
      List<Map<String, dynamic>> notifications, AppExtraColors extra) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 60,
        columnSpacing: 24,
        horizontalMargin: 0,
        headingTextStyle: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: Text('')), // Icon column
          DataColumn(label: Text('Заголовок')),
          DataColumn(label: Text('Опис')),
          DataColumn(label: Text('Час')),
        ],
        rows: notifications.map((n) {
          final bool unread = n['status'] == 'unread';
          final Color rowBg = unread ? extra.accentSoft : Colors.transparent;
          return DataRow(
            color: MaterialStateProperty.resolveWith<Color?>((states) => rowBg),
            cells: [
              DataCell(
                Icon(
                  n['icon'] as IconData,
                  color: unread ? extra.accent : colorScheme.onSurface,
                ),
              ),
              DataCell(Text(
                n['title'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                ),
              )),
              DataCell(Text(
                n['description'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              )),
              DataCell(Text(
                n['time'] as String,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Побудова списку сповіщень для вузьких екранів.
  Widget _buildList(BuildContext context,
      List<Map<String, dynamic>> notifications, AppExtraColors extra) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        for (final n in notifications)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: extra.borderDefault),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (n['status'] == 'unread')
                        ? extra.accentSoft
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: extra.borderDefault),
                  ),
                  child: Icon(
                    n['icon'] as IconData,
                    color: (n['status'] == 'unread')
                        ? extra.accent
                        : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        n['title'] as String,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: (n['status'] == 'unread')
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['description'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        n['time'] as String,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}