import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart';

/// A responsive page for viewing and scheduling maintenance activities.
///
/// This page adapts to available screen width by adjusting the number of
/// columns used when displaying summary statistics.  It also uses
/// [`AppExtraColors`](package:trunk_ops_app/theme/app_colors.dart) where
/// possible to keep styling consistent with the rest of the application.
class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final subtitleColor =
        textTheme.bodySmall?.color ?? colorScheme.onBackground.withOpacity(0.7);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 16.0;

        // Determine how many cards fit in a row based on the width.
        int cardsPerRow;
        if (maxWidth >= 1500) {
          cardsPerRow = 4;
        } else if (maxWidth >= 1200) {
          cardsPerRow = 3;
        } else if (maxWidth >= 900) {
          cardsPerRow = 2;
        } else {
          cardsPerRow = 1;
        }

        final totalSpacing = spacing * (cardsPerRow + 1);
        final cardWidth =
            (maxWidth - totalSpacing).clamp(220.0, maxWidth) / cardsPerRow;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Page title
              Text(
                'Технічне обслуговування',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Планування та моніторинг задач з технічного обслуговування',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: 24),

              // Summary cards
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: const _MaintenanceStatCard(
                      title: 'Заплановані задачі',
                      value: '6',
                      subtitle: 'на найближчий тиждень',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _MaintenanceStatCard(
                      title: 'Виконані задачі',
                      value: '18',
                      subtitle: 'за поточний місяць',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _MaintenanceStatCard(
                      title: 'Критичні задачі',
                      value: '1',
                      subtitle: 'потребують уваги',
                      highlight: true,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _MaintenanceStatCard(
                      title: 'Відкладені задачі',
                      value: '2',
                      subtitle: 'чекають ресурсів',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Table/list of individual maintenance tasks
              const _MaintenanceTaskList(),
            ],
          ),
        );
      },
    );
  }
}

/// A small card used to display summary statistics for maintenance tasks.
class _MaintenanceStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  const _MaintenanceStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final extra = theme.extension<AppExtraColors>();

    final borderColor = highlight
        ? (extra?.warning ?? colorScheme.secondary)
        : (extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7));
    final valueColor = highlight
        ? (extra?.warning ?? colorScheme.secondary)
        : colorScheme.onSurface;
    final subtitleColor = textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: highlight ? 1.3 : 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 12,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A list widget that renders each maintenance task as a row in a card-like
/// container.  It uses demonstration data for now.  In a real application
/// these would be fetched from a backend or state management layer.
class _MaintenanceTaskList extends StatelessWidget {
  const _MaintenanceTaskList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final tasks = _demoTasks;
    final dividerColor = extra?.borderDefault ??
        colorScheme.outline.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant ??
                  colorScheme.surface.withOpacity(1.02),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                _TaskHeaderCell(flex: 2, label: 'Задача'),
                _TaskHeaderCell(flex: 1, label: 'Планова дата'),
                _TaskHeaderCell(flex: 1, label: 'Статус'),
                _TaskHeaderCell(flex: 2, label: 'Опис'),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: dividerColor),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tasks.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, thickness: 1, color: dividerColor),
            itemBuilder: (context, index) {
              final task = tasks[index];
              return _MaintenanceTaskRow(task: task);
            },
          ),
        ],
      ),
    );
  }
}

class _TaskHeaderCell extends StatelessWidget {
  final int flex;
  final String label;

  const _TaskHeaderCell({required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final color = textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: textTheme.bodySmall?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class _MaintenanceTaskRow extends StatelessWidget {
  final _MaintenanceTask task;

  const _MaintenanceTaskRow({required this.task});

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;
    switch (task.status) {
      case 'OK':
        return extra?.success ?? colorScheme.primary;
      case 'Warning':
        return extra?.warning ?? colorScheme.secondary;
      case 'Critical':
        return colorScheme.error;
      default:
        return theme.textTheme.bodySmall?.color ??
            colorScheme.onSurface.withOpacity(0.7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(context);
    final muted = textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);
    return InkWell(
      onTap: () {
        // TODO: open detailed view of maintenance task
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                task.title,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                task.date,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 6),
                    Text(
                    task.statusLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                task.description,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Data class representing a maintenance task.
class _MaintenanceTask {
  final String title;
  final String date;
  final String status;
  final String statusLabel;
  final String description;

  _MaintenanceTask({
    required this.title,
    required this.date,
    required this.status,
    required this.statusLabel,
    required this.description,
  });
}

// Demo data for maintenance tasks.  In a real app this would be replaced
// with calls to your data layer or network.
final List<_MaintenanceTask> _demoTasks = [
  _MaintenanceTask(
    title: 'Перевірка резервного генератора',
    date: '15.11.2025',
    status: 'OK',
    statusLabel: 'Заплановано',
    description: 'Тест працездатності та заправка палива.',
  ),
  _MaintenanceTask(
    title: 'Оновлення ПЗ базової станції',
    date: '16.11.2025',
    status: 'Warning',
    statusLabel: 'Відкладено',
    description: 'Очікується підтвердження від відділу безпеки.',
  ),
  _MaintenanceTask(
    title: 'Планова ревізія антенного обладнання',
    date: '18.11.2025',
    status: 'Critical',
    statusLabel: 'Критично',
    description: 'Виявлено порушення в попередніх оглядах, потрібен інженер.',
  ),
  _MaintenanceTask(
    title: 'Перевірка акумуляторних блоків',
    date: '20.11.2025',
    status: 'OK',
    statusLabel: 'Заплановано',
    description: 'Замір напруги та ємності кожного блоку.',
  ),
];