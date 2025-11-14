import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class CoveragePage extends StatelessWidget {
  const CoveragePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final bool isWide = maxWidth >= 1100;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок + підзаголовок
              Text(
                'Мапа покриття',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Візуалізація зони дії транкінгової мережі та стан основних вузлів',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color:
                      textTheme.bodySmall?.color ??
                      colorScheme.onBackground.withOpacity(0.7),
                ),
              ),

              const SizedBox(height: 20),

              // Верхня панель фільтрів
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _FilterPill(
                    label: 'ОТУ',
                    value: 'ОТУ «Північ»',
                    onTap: () {
                      // TODO: вибір ОТУ / ТВД
                    },
                  ),
                  _FilterPill(
                    label: 'Масштаб',
                    value: 'Оперативно-тактичний',
                    onTap: () {
                      // TODO: вибір масштабу
                    },
                  ),
                  _FilterPill(
                    label: 'Шар',
                    value: 'Покриття + вузли',
                    onTap: () {
                      // TODO: вибір шарів на мапі
                    },
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () {
                      // TODO: скинути фільтри
                    },
                    child: Text(
                      'Скинути фільтри',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 13,
                        // акцентний / попереджувальний колір
                        color:
                            theme.extension<AppExtraColors>()?.warning ??
                            colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Основний контент: мапа + бокова панель
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: const _CoverageMapCard()),
                    const SizedBox(width: 20),
                    const Expanded(flex: 2, child: _SideStatusPanel()),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: const [
                    _CoverageMapCard(),
                    SizedBox(height: 16),
                    _SideStatusPanel(),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

/// ───────────────── МАПА (плейсхолдер під реальну карту) ─────────────────

class _CoverageMapCard extends StatelessWidget {
  const _CoverageMapCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final mutedText =
        theme.textTheme.bodySmall?.color ??
        colorScheme.onSurface.withOpacity(0.7);

    // статусні кольори
    final stableColor = extra?.success ?? colorScheme.primary;
    final degradedColor = extra?.warning ?? colorScheme.secondary;
    final criticalColor = colorScheme.error;

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Тло зі "стилізацією" під карту
            Positioned.fill(
              child: CustomPaint(
                painter: _GridBackgroundPainter(
                  lineColor:
                      (extra?.borderDefault ??
                              colorScheme.outlineVariant ??
                              colorScheme.outline)
                          .withOpacity(0.7),
                ),
              ),
            ),

            // Верхній опис
            Align(
              alignment: Alignment.topLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Оперативна обстановка',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      color: mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Тут буде інтерактивна мапа покриття',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            // Легенда знизу зліва
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.background.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        extra?.borderDefault ??
                        colorScheme.outline.withOpacity(0.6),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: stableColor, label: 'Стабільна зона'),
                    const SizedBox(width: 12),
                    _LegendDot(
                      color: degradedColor,
                      label: 'Погіршене покриття',
                    ),
                    const SizedBox(width: 12),
                    _LegendDot(color: criticalColor, label: 'Критичні ділянки'),
                  ],
                ),
              ),
            ),

            // Плейсхолдерні "вузли" / "базові станції"
            Align(
              alignment: Alignment.center,
              child: Wrap(
                spacing: 32,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  _NodePoint(label: 'Вузол А', statusColor: stableColor),
                  _NodePoint(label: 'Вузол B', statusColor: degradedColor),
                  _NodePoint(label: 'Вузол C', statusColor: criticalColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────── ПРАВА ПАНЕЛЬ СТАНУ ─────────────────

class _SideStatusPanel extends StatelessWidget {
  const _SideStatusPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final extra = theme.extension<AppExtraColors>();

    final stableColor = extra?.success ?? colorScheme.primary;
    final degradedColor = extra?.warning ?? colorScheme.secondary;
    final criticalColor = colorScheme.error;

    final mutedText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Стан покриття',
            style: textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),

          // Прогрес-бари по якості звʼязку
          _CoverageStatusRow(
            label: 'Стабільна зона',
            percent: 0.72,
            color: stableColor,
          ),
          const SizedBox(height: 8),
          _CoverageStatusRow(
            label: 'Погіршене покриття',
            percent: 0.18,
            color: degradedColor,
          ),
          const SizedBox(height: 8),
          _CoverageStatusRow(
            label: 'Критичні ділянки',
            percent: 0.10,
            color: criticalColor,
          ),

          const SizedBox(height: 20),

          Text(
            'Ключові вузли',
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          _NodeStatusTile(
            name: 'Вузол А — Штаб ОТУ',
            status: 'OK',
            description: 'Основний вузол, стабільний канал, резерв увімкнено.',
            color: stableColor,
          ),
          const SizedBox(height: 8),
          _NodeStatusTile(
            name: 'Вузол B — Опорний пункт',
            status: 'Warning',
            description:
                'Періодичні втрати пакеті в години пікового навантаження.',
            color: degradedColor,
          ),
          const SizedBox(height: 8),
          _NodeStatusTile(
            name: 'Вузол C — Резервний ретранслятор',
            status: 'Critical',
            description: 'Знижена потужність передавача, потрібна перевірка.',
            color: criticalColor,
          ),
        ],
      ),
    );
  }
}

/// ───────────────── Дрібні допоміжні віджети ─────────────────

class _FilterPill extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label:',
              style: textTheme.bodySmall?.copyWith(fontSize: 12, color: muted),
            ),
            const SizedBox(width: 6),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: muted),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final legendTextColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            fontSize: 11,
            color: legendTextColor,
          ),
        ),
      ],
    );
  }
}

class _NodePoint extends StatelessWidget {
  final String label;
  final Color statusColor;

  const _NodePoint({required this.label, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final labelColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.8);

    return Column(
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(fontSize: 11, color: labelColor),
        ),
      ],
    );
  }
}

class _CoverageStatusRow extends StatelessWidget {
  final String label;
  final double percent; // 0..1
  final Color color;

  const _CoverageStatusRow({
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: muted,
                ),
              ),
            ),
            Text(
              '${(percent * 100).round()}%',
              style: textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 6,
            backgroundColor:
                colorScheme.surfaceVariant ??
                colorScheme.surface.withOpacity(0.5),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _NodeStatusTile extends StatelessWidget {
  final String name;
  final String status;
  final String description;
  final Color color;

  const _NodeStatusTile({
    required this.name,
    required this.status,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();

    final muted =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Кольоровий маркер
          Container(
            width: 8,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),

          // Текст
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color, width: 1),
              color: color.withOpacity(0.12),
            ),
            child: Text(
              status,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Фон з сіткою для мапи (щоб не був просто голий прямокутник)
class _GridBackgroundPainter extends CustomPainter {
  final Color lineColor;

  const _GridBackgroundPainter({required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const step = 32.0;

    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine);
    }

    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintLine);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
