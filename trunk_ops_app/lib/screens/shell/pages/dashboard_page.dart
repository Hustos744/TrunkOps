import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 16.0;

        int crossAxisCount;
        if (maxWidth >= 1500) {
          crossAxisCount = 4;
        } else if (maxWidth >= 1200) {
          crossAxisCount = 3;
        } else if (maxWidth >= 800) {
          crossAxisCount = 2;
        } else {
          crossAxisCount = 1;
        }

        final totalSpacing = spacing * (crossAxisCount + 1);
        final cardWidth =
            (maxWidth - totalSpacing).clamp(220.0, maxWidth) / crossAxisCount;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок "Dashboard"
              Text(
                'Dashboard',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),

              // Підзаголовок
              Text(
                'Огляд стану мережі транкінгового звʼязку',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color:
                      textTheme.bodySmall?.color ??
                      colorScheme.onBackground.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 24),

              // Стат-карточки
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardStatCard(
                      title: 'Активні вузли',
                      value: '24',
                      subtitle: '+2 за останню добу',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardStatCard(
                      title: 'Середнє завантаження',
                      value: '63%',
                      subtitle: 'у піковий період',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardStatCard(
                      title: 'Інциденти',
                      value: '3',
                      subtitle: 'потребують уваги',
                      highlight: true,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const DashboardStatCard(
                      title: 'Сеанси звʼязку / год',
                      value: '172',
                      subtitle: 'середнє значення',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Заголовок "Остання активність"
              Text(
                'Остання активність',
                style: textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 12),

              // Блок активності
              _LastActivityCard(),
            ],
          ),
        );
      },
    );
  }
}

class DashboardStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  const DashboardStatCard({
    super.key,
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
    final extra = theme.extension<AppExtraColors>()!;

    final borderColor = highlight ? extra.accent : extra.borderDefault;
    final backgroundColor = highlight
        ? extra.accentSoft
        : extra.surfaceElevated;

    final valueColor = highlight ? extra.accent : colorScheme.onSurface;

    final subtitleColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок картки
          Text(
            title,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 8),

          // Значення
          Text(
            value,
            style: textTheme.headlineMedium?.copyWith(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 6),

          // Пояснення
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

class _LastActivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: extra.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: extra.borderDefault),
      ),
      child: const Column(
        children: [
          ActivityRow(
            time: '10:24',
            unit: 'Рота звʼязку 1',
            action: 'Запуск тестового сеансу',
            status: 'OK',
          ),
          Divider(height: 16),
          ActivityRow(
            time: '09:58',
            unit: 'Штаб батальйону',
            action: 'Фіксація короткочасної втрати каналу',
            status: 'Warning',
          ),
          Divider(height: 16),
          ActivityRow(
            time: '09:12',
            unit: 'Резервний вузол',
            action: 'Успішний перехід на резервний канал',
            status: 'OK',
          ),
        ],
      ),
    );
  }
}

class ActivityRow extends StatelessWidget {
  final String time;
  final String unit;
  final String action;
  final String status;

  const ActivityRow({
    super.key,
    required this.time,
    required this.unit,
    required this.action,
    required this.status,
  });

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>()!;

    switch (status) {
      case 'Warning':
        return extra.warning;
      case 'Error':
        return colorScheme.error;
      default:
        return extra.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final statusColor = _statusColor(context);
    final mutedColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Row(
      children: [
        // Час
        SizedBox(
          width: 64,
          child: Text(
            time,
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: mutedColor,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Опис підрозділу + дії
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                unit,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                action,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  color: mutedColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),

        // Badge статусу
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: statusColor),
            color: statusColor.withOpacity(0.12),
          ),
          child: Text(
            status,
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
