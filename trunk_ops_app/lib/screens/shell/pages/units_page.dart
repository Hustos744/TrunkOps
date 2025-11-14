import 'package:flutter/material.dart';
import 'package:trunk_ops_app/theme/app_colors.dart'; // AppExtraColors

class UnitsPage extends StatelessWidget {
  const UnitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const spacing = 16.0;

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

        final subtitleColor =
            textTheme.bodySmall?.color ??
            colorScheme.onBackground.withOpacity(0.7);

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок сторінки
              Text(
                'Підрозділи',
                style: textTheme.headlineLarge?.copyWith(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Структура підрозділів та їхній стан з точки зору забезпечення транкінговим звʼязком',
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: subtitleColor,
                ),
              ),

              const SizedBox(height: 24),

              // Верхні статистичні картки
              Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  SizedBox(
                    width: cardWidth,
                    child: const _UnitStatCard(
                      title: 'Загальна кількість підрозділів',
                      value: '38',
                      subtitle: 'по обраному ОТУ',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _UnitStatCard(
                      title: 'Підрозділи з активним звʼязком',
                      value: '31',
                      subtitle: 'канал в нормі',
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _UnitStatCard(
                      title: 'Проблемні підрозділи',
                      value: '5',
                      subtitle: 'виявлено збої / деградацію',
                      highlight: true,
                    ),
                  ),
                  SizedBox(
                    width: cardWidth,
                    child: const _UnitStatCard(
                      title: 'У резерві / відключені',
                      value: '2',
                      subtitle: 'тимчасово виведені з роботи',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Панель фільтрів + пошук
              const _UnitsFilterBar(),

              const SizedBox(height: 20),

              // Таблиця / список підрозділів
              const _UnitsTable(),
            ],
          ),
        );
      },
    );
  }
}

/// ───────────────── КАРТКИ-СТАТИСТИКА ─────────────────

class _UnitStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final bool highlight;

  const _UnitStatCard({
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

    final subtitleColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

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

/// ───────────────── ПАНЕЛЬ ФІЛЬТРІВ ─────────────────

class _UnitsFilterBar extends StatelessWidget {
  const _UnitsFilterBar();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final resetColor = extra?.warning ?? colorScheme.secondary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 800;

        final searchField = Expanded(
          child: TextField(
            style: textTheme.bodyMedium?.copyWith(
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Пошук підрозділу, позивного або індексу',
              hintStyle: textTheme.bodySmall?.copyWith(fontSize: 13),
              prefixIcon: Icon(
                Icons.search,
                size: 18,
                color:
                    textTheme.bodySmall?.color ??
                    colorScheme.onSurface.withOpacity(0.7),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              filled: true,
              fillColor: colorScheme.surface,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color:
                      extra?.borderDefault ??
                      colorScheme.outline.withOpacity(0.7),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide(
                  color: extra?.success ?? colorScheme.primary,
                  width: 1.2,
                ),
              ),
            ),
          ),
        );

        final filters = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _FilterChipButton(
              label: 'Тип підрозділу',
              value: 'Рота / батальйон',
              onTap: () {},
            ),
            _FilterChipButton(
              label: 'Стан звʼязку',
              value: 'Усі стани',
              onTap: () {},
            ),
            _FilterChipButton(
              label: 'Зона / район',
              value: 'Усі зони',
              onTap: () {},
            ),
          ],
        );

        final resetButton = TextButton(
          onPressed: () {},
          child: Text(
            'Скинути',
            style: textTheme.bodySmall?.copyWith(
              fontSize: 13,
              color: resetColor,
            ),
          ),
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              filters,
              const SizedBox(height: 12),
              Row(
                children: [searchField, const SizedBox(width: 8), resetButton],
              ),
            ],
          );
        } else {
          return Row(
            children: [
              Expanded(child: filters),
              const SizedBox(width: 12),
              searchField,
              const SizedBox(width: 8),
              resetButton,
            ],
          );
        }
      },
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterChipButton({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7),
            width: 1,
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

/// ───────────────── ТАБЛИЦЯ ПІДРОЗДІЛІВ ─────────────────

class _UnitsTable extends StatelessWidget {
  const _UnitsTable();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = theme.extension<AppExtraColors>();
    final textTheme = theme.textTheme;

    final units = _demoUnits;

    final headerBg =
        colorScheme.surfaceVariant ?? colorScheme.surface.withOpacity(1.02);

    final headerTextColor =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    final dividerColor =
        extra?.borderDefault ?? colorScheme.outline.withOpacity(0.7);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: dividerColor),
      ),
      child: Column(
        children: [
          // Заголовки колонок
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Row(
              children: [
                _HeaderCell(flex: 2, label: 'Підрозділ'),
                _HeaderCell(flex: 2, label: 'Тип'),
                _HeaderCell(flex: 2, label: 'Район / зона'),
                _HeaderCell(flex: 2, label: 'Стан звʼязку'),
                _HeaderCell(flex: 1, label: 'Активність'),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: dividerColor),

          // Рядки
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: units.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, thickness: 1, color: dividerColor),
            itemBuilder: (context, index) {
              final unit = units[index];
              return _UnitRow(unit: unit);
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final int flex;
  final String label;

  const _HeaderCell({required this.flex, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final color =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

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

class _UnitRow extends StatelessWidget {
  final _Unit unit;

  const _UnitRow({required this.unit});

  Color _statusColor(BuildContext context) {
    final theme = Theme.of(context);
    final extra = theme.extension<AppExtraColors>();
    final colorScheme = theme.colorScheme;

    switch (unit.status) {
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
    final secondaryText =
        textTheme.bodySmall?.color ?? colorScheme.onSurface.withOpacity(0.7);

    return InkWell(
      onTap: () {
        // TODO: відкриття детальної картки підрозділу
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                unit.name,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                unit.type,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                unit.area,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: secondaryText,
                ),
              ),
            ),
            Expanded(
              flex: 2,
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
                    unit.statusLabel,
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 13,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  unit.activity,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ───────────────── Тимчасова "модель" підрозділу ─────────────────

class _Unit {
  final String name;
  final String type;
  final String area;
  final String status; // OK / Warning / Critical
  final String statusLabel;
  final String activity;

  _Unit({
    required this.name,
    required this.type,
    required this.area,
    required this.status,
    required this.statusLabel,
    required this.activity,
  });
}

// Тимчасові демонстраційні дані
final List<_Unit> _demoUnits = [
  _Unit(
    name: 'Рота звʼязку 1',
    type: 'Рота',
    area: 'Сектор «Північ-1»',
    status: 'OK',
    statusLabel: 'Стабільний канал',
    activity: 'Активна',
  ),
  _Unit(
    name: 'Штаб батальйону',
    type: 'Штаб',
    area: 'Оперативний район А',
    status: 'Warning',
    statusLabel: 'Погіршене покриття',
    activity: 'Активна',
  ),
  _Unit(
    name: 'Резервний вузол 3',
    type: 'Резервний вузол',
    area: 'Тиловий район',
    status: 'OK',
    statusLabel: 'Готовий до роботи',
    activity: 'Резерв',
  ),
  _Unit(
    name: 'Опорний пункт Б',
    type: 'Взводний опорний пункт',
    area: 'Сектор «Південь-2»',
    status: 'Critical',
    statusLabel: 'Часті розриви',
    activity: 'Проблемний',
  ),
  _Unit(
    name: 'Рота звʼязку 2',
    type: 'Рота',
    area: 'Сектор «Схід-1»',
    status: 'OK',
    statusLabel: 'Стабільний канал',
    activity: 'Активна',
  ),
];
