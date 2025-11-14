import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

/// Сторінка журналу аудиту.
///
/// Відображає список подій у системі у вигляді таблиці на великих екранах
/// та у вигляді карток на малих екранах. Використовує кольори з теми для
/// фонів, тексту та статусів, щоб підлаштовуватись під темну/світлу
/// схему та залишатись читабельною на будь‑якому розмірі екрану.
class AuditLogPage extends StatelessWidget {
  const AuditLogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    // Тимчасові демо‑дані для журналу аудиту.
    final List<Map<String, String>> logs = [
      {
        'time': '13.11.2025 09:40',
        'user': 'Підрозділ Alpha',
        'action': 'Вхід у систему',
        'status': 'Успішно',
      },
      {
        'time': '13.11.2025 09:43',
        'user': 'Підрозділ Bravo',
        'action': 'Зміна налаштувань користувача',
        'status': 'Відхилено',
      },
      {
        'time': '13.11.2025 10:05',
        'user': 'Підрозділ Charlie',
        'action': 'Оновлення статусу вузла',
        'status': 'Успішно',
      },
      {
        'time': '13.11.2025 10:20',
        'user': 'Підрозділ Alpha',
        'action': 'Спроба доступу до обліку засобів',
        'status': 'Відхилено',
      },
      {
        'time': '13.11.2025 11:15',
        'user': 'Підрозділ Delta',
        'action': 'Експорт журналу аудиту',
        'status': 'Успішно',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Адаптивність: на вузьких екранах показуємо картки замість таблиці.
        final bool isWide = constraints.maxWidth >= 700;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Журнал аудиту',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: extra.borderDefault),
                ),
                child: isWide
                    ? _buildTable(context, logs, extra)
                    : _buildCards(context, logs, extra),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Побудова таблиці для широких екранів.
  Widget _buildTable(BuildContext context, List<Map<String, String>> logs,
      AppExtraColors extra) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 42,
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columnSpacing: 24,
        horizontalMargin: 0,
        headingTextStyle: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        columns: const [
          DataColumn(label: Text('Час')),
          DataColumn(label: Text('Користувач')),
          DataColumn(label: Text('Подія')),
          DataColumn(label: Text('Статус')),
        ],
        rows: logs.map((log) {
          final bool success = log['status'] == 'Успішно';
          // Для фону статусу використовуємо напівпрозорий колір успіху/помилки
          final Color statusBg = success
              ? extra.success.withOpacity(0.15)
              : colorScheme.error.withOpacity(0.15);
          final Color statusColor = success
              ? extra.success
              : colorScheme.error;
          return DataRow(
            cells: [
              DataCell(Text(
                log['time'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )),
              DataCell(Text(
                log['user'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )),
              DataCell(Text(
                log['action'] ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log['status'] ?? '',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  /// Побудова карток для вузьких екранів.
  Widget _buildCards(BuildContext context, List<Map<String, String>> logs,
      AppExtraColors extra) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        for (final log in logs)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: extra.borderDefault),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['time'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Користувач: ${log['user'] ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Подія: ${log['action'] ?? ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Статус: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (log['status'] == 'Успішно')
                            ? extra.success.withOpacity(0.15)
                            : colorScheme.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log['status'] ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: (log['status'] == 'Успішно')
                              ? extra.success
                              : colorScheme.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}