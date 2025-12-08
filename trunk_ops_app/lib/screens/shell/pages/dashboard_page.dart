import 'package:flutter/material.dart';
import 'package:trunk_ops_app/models/asset.dart';
import 'package:trunk_ops_app/services/asset_local_repository.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  bool _hasLastCheck(Asset a) {
    final v = a.lastCheck.trim();
    return v.isNotEmpty && v != '-';
  }

  List<_ActivityLogEntry> _buildActivityLog(List<Asset> assets) {
    final List<_ActivityLogEntry> entries = [];

    for (final a in assets) {
      // Беремо тільки засоби, де є дата перевірки або статус не "У строю"
      final hasCheck = _hasLastCheck(a);
      if (!hasCheck && a.status == 'У строю') continue;

      final String statusBadge;
      switch (a.status) {
        case 'На ремонті':
          statusBadge = 'Error';
          break;
        case 'Резерв':
          statusBadge = 'Warning';
          break;
        default:
          statusBadge = 'OK';
      }

      final timeLabel = hasCheck ? a.lastCheck.trim() : '—';
      final unitLabel = (a.unit.isNotEmpty ? a.unit : 'Підрозділ не вказано');

      String action;
      switch (a.status) {
        case 'На ремонті':
          action = 'Засіб на ремонті (інв. № ${a.invNumber})';
          break;
        case 'Резерв':
          action = 'Переведено у резерв (інв. № ${a.invNumber})';
          break;
        default:
          action = hasCheck
              ? 'Підтверджено працездатність (інв. № ${a.invNumber})'
              : 'Статус у строю, без дати перевірки';
      }

      entries.add(
        _ActivityLogEntry(
          time: timeLabel,
          unit: unitLabel,
          action: action,
          status: statusBadge,
        ),
      );
    }

    // Пробуємо відсортувати за датою як текст (краще, ніж нічого).
    // Якщо формат дати консистентний (напр. dd.MM.yyyy), виглядатиме нормально.
    entries.sort((a, b) => b.time.compareTo(a.time));

    // Показуємо тільки останні 5 подій
    return entries.take(5).toList();
  }

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

        return FutureBuilder<List<Asset>>(
          future: AssetLocalRepository().getAll(),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final hasError = snapshot.hasError;
            final assets = snapshot.data ?? const <Asset>[];

            // Метрики
            final totalAssets = assets.length;
            final inService = assets.where((a) => a.status == 'У строю').length;
            final inRepair = assets
                .where((a) => a.status == 'На ремонті')
                .length;
            final inReserve = assets.where((a) => a.status == 'Резерв').length;
            final withoutCheck = assets.where((a) {
              final v = a.lastCheck.trim();
              return v.isEmpty || v == '-';
            }).length;

            final activityEntries = _buildActivityLog(assets);

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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Підзаголовок + статус даних
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Огляд стану засобів та активності мережі транкінгового звʼязку',
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            color:
                                textTheme.bodySmall?.color ??
                                colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isLoading)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Оновлення...',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        )
                      else if (hasError)
                        Text(
                          'Помилка завантаження даних',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Стат-карточки
                  Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Засобів всього',
                          value: totalAssets.toString(),
                          subtitle: 'усі засоби в системі',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'У строю',
                          value: inService.toString(),
                          subtitle: 'готові до використання',
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'На ремонті',
                          value: inRepair.toString(),
                          subtitle: 'потребують уваги',
                          highlight: inRepair > 0,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: DashboardStatCard(
                          title: 'Без дати перевірки',
                          value: withoutCheck.toString(),
                          subtitle: 'потрібно запланувати ТО',
                          highlight: withoutCheck > 0,
                        ),
                      ),
                      if (crossAxisCount > 1)
                        SizedBox(
                          width: cardWidth,
                          child: DashboardStatCard(
                            title: 'У резерві',
                            value: inReserve.toString(),
                            subtitle: 'можуть бути задіяні за потреби',
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
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Блок активності
                  _LastActivityCard(
                    isLoading: isLoading,
                    hasError: hasError,
                    entries: activityEntries,
                  ),
                ],
              ),
            );
          },
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
    final extra = theme.extension<AppExtraColors>();

    final borderColor = highlight
        ? (extra?.accent ?? colorScheme.primary)
        : (extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7));

    final backgroundColor = highlight
        ? (extra?.accentSoft ?? colorScheme.primary.withOpacity(0.06))
        : (extra?.surfaceElevated ?? colorScheme.surface);

    final valueColor = highlight
        ? (extra?.accent ?? colorScheme.primary)
        : colorScheme.onSurface;

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
  final bool isLoading;
  final bool hasError;
  final List<_ActivityLogEntry> entries;

  const _LastActivityCard({
    required this.isLoading,
    required this.hasError,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final backgroundColor = extra?.surfaceElevated ?? colorScheme.surface;
    final borderColor =
        extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7);

    Widget child;

    if (isLoading && entries.isEmpty) {
      child = const Center(
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: CircularProgressIndicator(),
        ),
      );
    } else if (hasError) {
      child = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Не вдалося завантажити останню активність',
          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error),
        ),
      );
    } else if (entries.isEmpty) {
      child = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'Немає зафіксованої активності (немає дат перевірок чи змін статусів).',
          style: theme.textTheme.bodyMedium,
        ),
      );
    } else {
      child = Column(
        children: [
          for (int i = 0; i < entries.length; i++) ...[
            if (i > 0) const Divider(height: 16),
            ActivityRow(
              time: entries[i].time,
              unit: entries[i].unit,
              action: entries[i].action,
              status: entries[i].status,
            ),
          ],
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: child,
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
    final extra = theme.extension<AppExtraColors>();

    switch (status) {
      case 'Warning':
        return extra?.warning ?? colorScheme.secondary;
      case 'Error':
        return colorScheme.error;
      default:
        return extra?.success ?? colorScheme.primary;
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
        // "Час" (тут — мітка дати / часу)
        SizedBox(
          width: 90,
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

class _ActivityLogEntry {
  final String time;
  final String unit;
  final String action;
  final String status; // OK / Warning / Error

  _ActivityLogEntry({
    required this.time,
    required this.unit,
    required this.action,
    required this.status,
  });
}
